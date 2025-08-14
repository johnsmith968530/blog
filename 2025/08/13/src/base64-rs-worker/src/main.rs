use anyhow::Context;
use async_trait::async_trait;
use base64::{Engine as _, engine::general_purpose::STANDARD as BASE64};
use redis_streams_worker::{Args, CommandHandler, RedisConfig, StreamConfig, Worker, Result, WorkerError};
use serde::Serialize;
use std::fs;
use std::path::Path;
use url::Url;

#[derive(Debug, Serialize)]
struct Base64Result {
    base64: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    data_url: Option<String>,
}

struct Base64Handler;

impl Base64Handler {
    fn handle_blob(data: &[u8], mime_type: Option<String>) -> Result<String> {
        let base64 = BASE64.encode(data);
        let result = Base64Result {
            base64: base64.clone(),
            data_url: mime_type.map(|mime| format!("data:{};base64,{}", mime, base64)),
        };
        serde_json::to_string(&result)
            .map_err(|e| WorkerError::JobFailed(format!("Failed to serialize result: {}", e)))
    }

    fn extract_path(path_or_url: &str) -> Result<String> {
        if !path_or_url.starts_with("file://") {
            return Ok(path_or_url.to_string());
        }
        
        let url = Url::parse(path_or_url)
            .map_err(|e| WorkerError::ArgumentInvalid {
                name: "filename".to_string(),
                reason: format!("Invalid file URL: {}", e),
            })?;
        
        if url.scheme() != "file" {
            return Err(WorkerError::ArgumentInvalid { 
                name: "filename".to_string(), 
                reason: "URL must use file:// scheme".to_string() 
            });
        }
        
        Ok(url.path().to_string())
    }

    fn handle_filename<P: AsRef<Path>>(path: P, mime_type: Option<String>) -> Result<String> {
        let path_str = path.as_ref().to_string_lossy();
        let actual_path = Self::extract_path(&path_str)?;
        
        let data = fs::read(&actual_path)
            .map_err(|e| WorkerError::ArgumentInvalid {
                name: "filename".to_string(),
                reason: format!("Failed to read file: {}", e),
            })?;
        
        let mime_type = mime_type.or_else(|| 
            mime_guess::from_path(&actual_path)
                .first()
                .map(|m| m.to_string())
        );
        
        Self::handle_blob(&data, mime_type)
    }

    async fn handle_blob_command(&self, args_str: &str) -> Result<String> {
        let args = Args::parse(args_str)?;
        let blob_data = args.get_string("blob")?;
        let mime_type = if args.get_string_or("mime_type", "").is_empty() {
            None
        } else {
            Some(args.get_string_or("mime_type", ""))
        };

        let bytes = BASE64.decode(blob_data.as_bytes())
            .map_err(|e| WorkerError::ArgumentInvalid {
                name: "blob".to_string(),
                reason: format!("Invalid base64 input: {}", e),
            })?;

        Self::handle_blob(&bytes, mime_type)
    }

    async fn handle_filename_command(&self, args_str: &str) -> Result<String> {
        let args = Args::parse(args_str)?;
        let filename = args.get_string("filename")?;
        let mime_type = if args.get_string_or("mime_type", "").is_empty() {
            None
        } else {
            Some(args.get_string_or("mime_type", ""))
        };
        Self::handle_filename(filename, mime_type)
    }
}

#[async_trait]
impl CommandHandler for Base64Handler {
    async fn handle_command(&self, command: &str, args: &str) -> Result<String> {
        match command {
            "blob" => self.handle_blob_command(args).await,
            "filename" => self.handle_filename_command(args).await,
            _ => Err(WorkerError::CommandUnknown(command.to_string())),
        }
    }

    fn get_commands(&self) -> Vec<String> {
        vec![
            "blob".to_string(),
            "filename".to_string(),
        ]
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let redis_config = RedisConfig::from_secrets()
        .context("Failed to get Redis configuration")?;
    
    let stream_config = StreamConfig::with_namespace("base64");

    let handler = Box::new(Base64Handler);
    let worker = Worker::new(redis_config, stream_config, handler);
    
    println!("Starting Base64 Redis Streams worker...");
    worker.run().await.context("Worker failed")?;
    
    Ok(())
}
