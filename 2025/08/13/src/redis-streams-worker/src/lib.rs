//! A library for building Redis Streams workers that process commands from a request stream
//! and publish results to a response stream.
//!
//! # Example
//! ```rust,no_run
//! use redis_streams_worker::{Args, CommandHandler, RedisConfig, StreamConfig, Worker, Result};
//! use async_trait::async_trait;
//!
//! struct MyHandler;
//!
//! #[async_trait]
//! impl CommandHandler for MyHandler {
//!     async fn handle_command(&self, command: &str, args: &str) -> Result<String> {
//!         match command {
//!             "hello" => {
//!                 let args = Args::parse(args)?;
//!                 let name = args.get_string_or("name", "world");
//!                 Ok(format!("Hello, {}!", name))
//!             }
//!             _ => Err(redis_streams_worker::WorkerError::CommandUnknown(command.to_string())),
//!         }
//!     }
//!
//!     fn get_commands(&self) -> Vec<String> {
//!         vec!["hello".to_string()]
//!     }
//! }
//!
//! #[tokio::main]
//! async fn main() -> Result<()> {
//!     let redis_config = RedisConfig::from_secrets()?;
//!     let stream_config = StreamConfig::with_namespace("myapp");
//!     
//!     let handler = Box::new(MyHandler);
//!     let worker = Worker::new(redis_config, stream_config, handler);
//!     worker.run().await
//! }
//! ```

mod args;
mod config;
mod error;
mod worker;

pub use args::Args;
pub use config::{RedisConfig, SecretsFile};
pub use error::{Result, WorkerError};
pub use worker::{CommandHandler, StreamConfig, Worker};
