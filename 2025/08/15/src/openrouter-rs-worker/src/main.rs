use anyhow::Context;
use async_trait::async_trait;
use redis::AsyncCommands;
use redis_streams_worker::{Args, CommandHandler, RedisConfig, SecretsFile, StreamConfig, Worker, Result, WorkerError};
use serde::{Deserialize, Serialize};
use serde_json::Value;

const OPENROUTER_API_URL: &str = "https://openrouter.ai/api/v1";

// A no-op handler for the base64 worker since we only use it for wait_for_job
struct NoopHandler;

#[async_trait]
impl CommandHandler for NoopHandler {
    async fn handle_command(&self, _command: &str, _args: &str) -> Result<String> {
        Ok("".to_string())
    }

    fn get_commands(&self) -> Vec<String> {
        vec![]
    }
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(tag = "type")]
enum ContentItem {
    #[serde(rename = "text")]
    Text {
        text: String,
    },
    #[serde(rename = "image_url")]
    ImageUrl {
        image_url: ImageUrl,
    },
}

#[derive(Debug, Serialize, Deserialize)]
struct ImageUrl {
    url: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct Message {
    role: String,
    content: Value, // Can be string or array of ContentItem
}

#[derive(Debug, Serialize, Deserialize)]
struct JobArgs {
    model: Option<String>,
    messages: Option<Vec<Message>>,
    log: Option<bool>,
}

struct OpenRouterHandler {
    client: reqwest::Client,
    base64_worker: Worker,
}

impl OpenRouterHandler {
    fn new(redis_config: RedisConfig) -> anyhow::Result<Self> {
        let secrets = SecretsFile::read()?;
        let api_key = secrets.get_string("openrouter.api_key")
            .ok_or_else(|| anyhow::anyhow!("OpenRouter API key not found in secrets file"))?;
        
        let client = reqwest::Client::builder()
            .default_headers({
                let mut headers = reqwest::header::HeaderMap::new();
                headers.insert(
                    "Authorization",
                    format!("Bearer {}", api_key).parse().unwrap(),
                );
                headers.insert(
                    "Content-Type",
                    "application/json".parse().unwrap(),
                );
                headers
            })
            .build()?;

        // Create a worker for base64 operations
        let base64_config = StreamConfig::with_namespace("base64");
        let base64_worker = Worker::new(
            redis_config.clone(),
            base64_config,
            Box::new(NoopHandler),
        );

        Ok(Self { client, base64_worker })
    }

    async fn get_base64_data_url(&self, file_path: &str) -> anyhow::Result<String> {
        // Prepare job arguments
        let args = serde_json::json!({
            "filename": file_path
        });

        // Add job using enqueue_job
        let job_id = self.base64_worker.enqueue_job("filename", Some(args))
            .await
            .map_err(|e| anyhow::anyhow!("Failed to add job to stream: {}", e))?;

        // Wait for response using the job ID
        let fields = self.base64_worker.wait_for_job("base64", &job_id).await
            .map_err(|e| anyhow::anyhow!("Failed to get base64 conversion result: {}", e))?;

        // Parse result
        if let Some(result) = fields.get("result") {
            let result: serde_json::Value = serde_json::from_str(result)
                .map_err(|e| anyhow::anyhow!("Failed to parse base64 result: {}", e))?;
            if let Some(data_url) = result.get("data_url").and_then(|v| v.as_str()) {
                return Ok(data_url.to_string());
            }
        }
        
        if let Some(error) = fields.get("error") {
            return Err(anyhow::anyhow!("Base64 conversion failed: {}", error));
        }

        Err(anyhow::anyhow!("Base64 conversion result missing data_url"))
    }

    async fn get_default_model(&self) -> anyhow::Result<String> {
        // Create a temporary worker for Redis operations
        let redis_config = RedisConfig::from_secrets()?;
        let redis_client = redis::Client::open(redis_config.to_url())?;
        let mut con = redis_client.get_multiplexed_async_connection().await?;
        match con.get::<_, Option<String>>("openrouter:default_model").await? {
            Some(model) => Ok(model),
            None => Err(anyhow::anyhow!("Default model not set in Redis"))
        }
    }

    async fn is_model_banned(&self, model: &str) -> anyhow::Result<bool> {
        let redis_config = RedisConfig::from_secrets()?;
        let redis_client = redis::Client::open(redis_config.to_url())?;
        let mut con = redis_client.get_multiplexed_async_connection().await?;
        
        // Get the list of banned models
        let banned_models: Vec<String> = con.smembers("openrouter:banned_models").await?;
        Ok(banned_models.contains(&model.to_string()))
    }

    async fn process_messages(&self, messages: Vec<Message>) -> anyhow::Result<Vec<Message>> {
        let mut processed = Vec::new();
        
        for msg in messages {
            let processed_content = match msg.content {
                Value::String(_) => msg.content,
                Value::Array(items) => {
                    let mut processed_items = Vec::new();
                    for item in items {
                        let item = match serde_json::from_value::<ContentItem>(item)? {
                            ContentItem::Text { text } => ContentItem::Text { text },
                            ContentItem::ImageUrl { mut image_url } => {
                                if !image_url.url.starts_with("http") && !image_url.url.starts_with("data:") {
                                    let base64_url = self.get_base64_data_url(&image_url.url).await?;
                                    image_url.url = base64_url;
                                }
                                ContentItem::ImageUrl { image_url }
                            }
                        };
                        processed_items.push(serde_json::to_value(item)?);
                    }
                    Value::Array(processed_items)
                }
                _ => msg.content,
            };
            
            processed.push(Message {
                role: msg.role,
                content: processed_content,
            });
        }
        
        Ok(processed)
    }

    async fn handle_list_models(&self) -> Result<String> {
        let response = self.client
            .get(&format!("{}/models", OPENROUTER_API_URL))
            .send()
            .await
            .map_err(|e| WorkerError::JobFailed(e.to_string()))?;
            
        if !response.status().is_success() {
            let error = response.text().await
                .map_err(|e| WorkerError::JobFailed(e.to_string()))?;
            return Err(WorkerError::JobFailed(format!("OpenRouter API error: {}", error)));
        }
        
        let value = response.json::<Value>().await
            .map_err(|e| WorkerError::JobFailed(e.to_string()))?;
        serde_json::to_string(&value)
            .map_err(|e| WorkerError::JobFailed(e.to_string()))
    }

    async fn handle_chat_completion(&self, args_str: &str) -> Result<String> {
        let args = Args::parse(args_str)?;
        let args_json: serde_json::Value = serde_json::from_str(args_str)
            .map_err(|e| WorkerError::ArgumentInvalid {
                name: "args".to_string(),
                reason: format!("Invalid JSON: {}", e),
            })?;
        
        let messages = args_json.get("messages")
            .ok_or_else(|| WorkerError::ArgumentInvalid {
                name: "messages".to_string(),
                reason: "Missing required argument".to_string(),
            })?;
        
        let messages: Vec<Message> = serde_json::from_value(messages.clone())
            .map_err(|e| WorkerError::ArgumentInvalid {
                name: "messages".to_string(),
                reason: format!("Invalid messages format: {}", e),
            })?;

        let processed_messages = self.process_messages(messages).await
            .map_err(|e| WorkerError::JobFailed(e.to_string()))?;
        
        let model = if let Ok(m) = args.get_string("model") {
            m
        } else {
            self.get_default_model().await
                .map_err(|e| WorkerError::JobFailed(e.to_string()))?
        };

        // Check if the model is banned
        if self.is_model_banned(&model).await
            .map_err(|e| WorkerError::JobFailed(format!("Failed to check banned models: {}", e)))? {
            return Err(WorkerError::JobFailed(format!(
                "Model '{}' is banned and cannot be used. This usually means the model is outdated or has been replaced by better alternatives. If you're an LLM making this request, you may have specified an incorrect model ID - please verify the model identifier is current and valid.",
                model
            )));
        }
        
        let payload = serde_json::json!({
            "model": model,
            "messages": processed_messages,
        });

        let response = self.client
            .post(&format!("{}/chat/completions", OPENROUTER_API_URL))
            .json(&payload)
            .send()
            .await
            .map_err(|e| WorkerError::JobFailed(e.to_string()))?;
            
        let response_data = response.json::<Value>().await
            .map_err(|e| WorkerError::JobFailed(e.to_string()))?;
        serde_json::to_string(&response_data)
            .map_err(|e| WorkerError::JobFailed(e.to_string()))
    }
}

#[async_trait]
impl CommandHandler for OpenRouterHandler {
    async fn handle_command(&self, command: &str, args: &str) -> Result<String> {
        match command {
            "list_models" => self.handle_list_models().await,
            "chat_completion" => self.handle_chat_completion(args).await,
            _ => Err(WorkerError::CommandUnknown(command.to_string())),
        }
    }

    fn get_commands(&self) -> Vec<String> {
        vec![
            "list_models".to_string(),
            "chat_completion".to_string(),
        ]
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let redis_config = RedisConfig::from_secrets()
        .context("Failed to get Redis configuration")?;
    
    let stream_config = StreamConfig::with_namespace("openrouter");
    let handler = Box::new(OpenRouterHandler::new(redis_config.clone())?);
    let worker = Worker::new(redis_config, stream_config, handler);

    println!("Starting OpenRouter Redis Streams worker...");
    worker.run().await.context("Worker failed")?;
    
    Ok(())
}
