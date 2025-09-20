use std::collections::HashMap;
use std::time::{Duration, Instant};

use async_trait::async_trait;
use redis::{Value as RedisValue, AsyncCommands};
use redis::Client as RedisClient;

use crate::config::RedisConfig;
use crate::error::{Result, WorkerError};

pub struct StreamConfig {
    pub request_stream: String,
    pub response_stream: String,
    pub error_stream: String,
    pub consumer_group: String,
    pub consumer_name: String,
    pub block_ms: u64,
}

impl StreamConfig {
    pub fn with_namespace(namespace: &str) -> Self {
        let prefix = format!("{}:", namespace);
        Self {
            request_stream: format!("{}{}", prefix, "requests"),
            response_stream: format!("{}{}", prefix, "responses"),
            error_stream: format!("{}{}", prefix, "errors"),
            consumer_group: format!("{}{}", prefix, "workers"),
            consumer_name: format!("{}{}", prefix, "worker:1"),
            block_ms: 5000,
        }
    }
}

#[async_trait]
pub trait CommandHandler: Send + Sync {
    async fn handle_command(&self, command: &str, args: &str) -> Result<String>;
    fn get_commands(&self) -> Vec<String>;
}

pub struct Worker {
    pub redis_config: RedisConfig,
    stream_config: StreamConfig,
    handler: Box<dyn CommandHandler>,
    redis_client: RedisClient,
}

impl Worker {
    fn handle_redis_error(error: &redis::RedisError) -> ! {
        eprintln!("Fatal: Redis connection error: {}. Exiting worker...", error);
        std::process::exit(1);
    }

    pub fn extract_job_fields(
        messages: Vec<(String, Vec<(String, String)>)>,
        job_id: &str,
    ) -> Option<HashMap<String, String>> {
        messages.into_iter().find_map(|(_, pairs)| {
            let fields: HashMap<_, _> = pairs.into_iter().collect();
            if fields.get("job_id") == Some(&job_id.to_string()) {
                Some(fields)
            } else {
                None
            }
        })
    }

    pub async fn wait_for_job(
        &self,
        namespace: &str,
        job_id: &str,
    ) -> Result<HashMap<String, String>> {
        let mut con = match self.redis_client.get_multiplexed_async_connection().await {
            Ok(con) => con,
            Err(e) => Self::handle_redis_error(&e),
        };

        let timeout_key = format!("{}:timeout", namespace);
        let timeout: Option<u64> = match redis::cmd("GET")
            .arg(&timeout_key)
            .query_async(&mut con)
            .await
        {
            Ok(val) => val,
            Err(e) => Self::handle_redis_error(&e),
        };

        let timeout = match timeout {
            Some(t) => t,
            None => return Err(WorkerError::JobFailed(format!("Timeout key '{}' does not exist", timeout_key))),
        };
        println!("Using timeout of {} s for job {}", timeout, job_id);

        let start_time = Instant::now();
        let block_ms = 5000;

        loop {
            if start_time.elapsed() >= Duration::from_secs(timeout) {
                return Err(WorkerError::Timeout);
            }

            // Non-blocking check for existing messages
            let messages: Vec<(String, Vec<(String, String)>)> = match redis::cmd("XREVRANGE")
                .arg(&self.stream_config.response_stream)
                .arg("+")
                .arg("-")
                .query_async(&mut con)
                .await
            {
                Ok(val) => val,
                Err(e) => Self::handle_redis_error(&e),
            };

            // Print and check existing messages
            for (msg_id, pairs) in &messages {
                let fields: HashMap<_, _> = pairs.iter().cloned().collect();
                println!("Found message {}: job_id={:?}", msg_id, fields.get("job_id"));
            }
            if let Some(fields) = Worker::extract_job_fields(messages, job_id) {
                return Ok(fields);
            }

            // Calculate remaining timeout for blocking read
            let elapsed = start_time.elapsed();
            if elapsed >= Duration::from_secs(timeout) {
                return Err(WorkerError::Timeout);
            }

            // Use the shorter of block_ms or remaining timeout
            let remaining_ms = Duration::from_secs(timeout).saturating_sub(elapsed).as_millis() as u64;
            let block_duration = std::cmp::min(block_ms, remaining_ms);

            // Blocking check for new messages
            let response: Option<Vec<(String, Vec<(String, Vec<(String, String)>)>)>> = match redis::cmd("XREAD")
                .arg("BLOCK")
                .arg(block_duration)
                .arg("STREAMS")
                .arg(&self.stream_config.response_stream)
                .arg("$")
                .query_async(&mut con)
                .await
            {
                Ok(val) => val,
                Err(e) => Self::handle_redis_error(&e),
            };

            if let Some(streams) = response {
                for (_, messages) in streams {
                    // Print all received messages
                    for (msg_id, pairs) in &messages {
                        let fields: HashMap<_, _> = pairs.iter().cloned().collect();
                        println!("Received new message {}: job_id={:?}", msg_id, fields.get("job_id"));
                    }
                    if let Some(fields) = Worker::extract_job_fields(messages, job_id) {
                        return Ok(fields);
                    }
                }
            }
        }
    }

    pub fn new(
        redis_config: RedisConfig,
        stream_config: StreamConfig,
        handler: Box<dyn CommandHandler>,
    ) -> Self {
        let redis_client = redis::Client::open(redis_config.to_url())
            .expect("Invalid Redis URL");
        Self { 
            redis_config, 
            stream_config, 
            handler,
            redis_client,
        }
    }

    /// Enqueue a job onto the request stream
    /// 
    /// # Arguments
    /// * `command` - The command to execute
    /// * `args` - Optional arguments that can be serialized to JSON
    /// 
    /// # Returns
    /// The job ID assigned by Redis
    pub async fn enqueue_job<T>(&self, command: &str, args: Option<T>) -> Result<String> 
    where 
        T: serde::Serialize,
    {
        let mut con = match self.redis_client.get_multiplexed_async_connection().await {
            Ok(con) => con,
            Err(e) => Self::handle_redis_error(&e),
        };

        let args_json = match args {
            Some(args) => serde_json::to_string(&args)
                .map_err(|e| WorkerError::JobFailed(format!("Failed to serialize args: {}", e)))?,
            None => "{}".to_string(),
        };

        let job_id = match con.xadd(
            &self.stream_config.request_stream,
            "*",
            &[
                ("command", command),
                ("args", &args_json),
            ],
        ).await {
            Ok(val) => val,
            Err(e) => Self::handle_redis_error(&e),
        };

        Ok(job_id)
    }

    async fn process_message(
        &self,
        job_id: &str,
        fields: &HashMap<String, RedisValue>,
    ) -> Result<()> {
        let mut con = match self.redis_client.get_connection() {
            Ok(con) => con,
            Err(e) => Self::handle_redis_error(&e),
        };

        // Extract command
        let command = match fields.get("command") {
            Some(redis::Value::BulkString(bytes)) => String::from_utf8_lossy(bytes).to_string(),
            _ => return Err(WorkerError::CommandMissing),
        };

        println!("Processing job: {} - {}", job_id, command);

        // Extract arguments as JSON string
        let args = match fields.get("args") {
            Some(redis::Value::BulkString(bytes)) => String::from_utf8_lossy(bytes).to_string(),
            _ => "{}".to_string(), // Default to empty JSON object if no args
        };

        // Process command
        match self.handler.handle_command(&command, &args).await {
            Ok(response) => {
                println!("Completed job: {}", job_id);
                // Publish result to response stream
                let response_id: String = match redis::cmd("XADD")
                    .arg(&self.stream_config.response_stream)
                    .arg("*") // Let Redis assign the ID
                    .arg("job_id")
                    .arg(job_id)
                    .arg("result")
                    .arg(&*response)
                    .query(&mut con)
                {
                    Ok(val) => val,
                    Err(e) => Self::handle_redis_error(&e),
                };
                println!("Published response with ID: {} for job: {}", response_id, job_id);
            }
            Err(e) => {
                println!("Job {} failed: {}", job_id, e);
                // Move failed message to error stream
                let error_id: String = match redis::cmd("XADD")
                    .arg(&self.stream_config.error_stream)
                    .arg("MAXLEN")
                    .arg("~")
                    .arg(1000)
                    .arg("*")
                    .arg("job_id")
                    .arg(job_id)
                    .arg("error")
                    .arg(e.to_string())
                    .query(&mut con)
                {
                    Ok(val) => val,
                    Err(e) => Self::handle_redis_error(&e),
                };
                println!("Published error with ID: {} for job: {}", error_id, job_id);
                
                // Publish error to response stream
                let response_id: String = match redis::cmd("XADD")
                    .arg(&self.stream_config.response_stream)
                    .arg("*") // Let Redis assign the ID
                    .arg("job_id")
                    .arg(job_id)
                    .arg("error")
                    .arg(e.to_string())
                    .query(&mut con)
                {
                    Ok(val) => val,
                    Err(e) => Self::handle_redis_error(&e),
                };
                println!("Published error response with ID: {} for job: {}", response_id, job_id);
            }
        }

        // Acknowledge message
        match redis::cmd("XACK")
            .arg(&self.stream_config.request_stream)
            .arg(&self.stream_config.consumer_group)
            .arg(job_id)
            .query::<()>(&mut con)
        {
            Ok(_) => (),
            Err(e) => Self::handle_redis_error(&e),
        }
        println!("Acknowledged message: {}", job_id);

        Ok(())
    }

    pub async fn run(&self) -> Result<()> {
        println!("Starting Redis Streams worker...");

        // Connect to Redis
        let mut con = match self.redis_client.get_connection() {
            Ok(con) => con,
            Err(e) => Self::handle_redis_error(&e),
        };

        // Create consumer group if it doesn't exist
        let _request_stream = format!("{}:{}", self.stream_config.consumer_group, self.stream_config.request_stream);
        let _response_stream = format!("{}:{}", self.stream_config.consumer_group, self.stream_config.response_stream);
        let _error_stream = format!("{}:{}", self.stream_config.consumer_group, self.stream_config.error_stream);

        let create_group_result: redis::RedisResult<()> = redis::cmd("XGROUP")
            .arg("CREATE")
            .arg(&self.stream_config.request_stream)
            .arg(&self.stream_config.consumer_group)
            .arg("0")
            .arg("MKSTREAM")
            .query(&mut con);

        if let Err(e) = create_group_result {
            if !e.to_string().contains("BUSYGROUP") {
                Self::handle_redis_error(&e);
            }
            println!("Consumer group already exists");
        }

        loop {
            // Read from stream with XREADGROUP
            let result: redis::RedisResult<Vec<redis::Value>> = redis::cmd("XREADGROUP")
                .arg("GROUP")
                .arg(&self.stream_config.consumer_group)
                .arg(&self.stream_config.consumer_name)
                .arg("COUNT")
                .arg(1)
                .arg("BLOCK")
                .arg(self.stream_config.block_ms)
                .arg("STREAMS")
                .arg(&self.stream_config.request_stream)
                .arg(">") // Use > for new messages only
                .query(&mut con);

            match result {
                Ok(messages) => {
                    if messages.is_empty() {
                        continue;
                    }

                    // XREADGROUP returns: [[stream_name, [[id, [key, value, ...]], ...]]]
                    if let redis::Value::Array(outer) = &messages[0] {
                        if outer.len() >= 2 {
                            if let redis::Value::Array(stream_messages) = &outer[1] {
                                for message in stream_messages {
                                    if let redis::Value::Array(message_parts) = message {
                                        if let (Some(redis::Value::BulkString(id_bytes)), Some(redis::Value::Array(fields_bulk))) = 
                                            (message_parts.get(0), message_parts.get(1)) {
                                            
                                            let job_id = String::from_utf8_lossy(id_bytes);
                                            println!("Received message with ID: {}", job_id);
                                            let mut fields = HashMap::new();
                                            
                                            // Parse fields and print raw values
                                            println!("Raw message fields:");
                                            for chunk in fields_bulk.chunks(2) {
                                                if let (Some(key), Some(value)) = (chunk.get(0), chunk.get(1)) {
                                                    if let redis::Value::BulkString(key_bytes) = key {
                                                        let key_str = String::from_utf8_lossy(key_bytes);
                                                        println!("  {}: {:?}", key_str, value);
                                                        fields.insert(key_str.to_string(), value.clone());
                                                    }
                                                }
                                            }

                                            if let Err(e) = self.process_message(&job_id, &fields).await {
                                                eprintln!("Failed to process message: {}", e);
                                                // Try to acknowledge failed message before exiting
                                                let _ = redis::cmd("XACK")
                                                    .arg(&self.stream_config.request_stream)
                                                    .arg(&self.stream_config.consumer_group)
                                                    .arg(&*job_id)
                                                    .query::<()>(&mut con);
                                                return Err(e);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Err(e) => Self::handle_redis_error(&e),
            }
        }
    }
}
