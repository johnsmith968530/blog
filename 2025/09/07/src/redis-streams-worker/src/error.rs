use std::fmt;

#[derive(Debug)]
pub enum WorkerError {
    Redis(redis::RedisError),
    CommandMissing,
    CommandUnknown(String),
    ArgumentMissing(String),
    ArgumentInvalid { name: String, reason: String },
    JobFailed(String),
    Timeout,
}

impl fmt::Display for WorkerError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            WorkerError::Redis(e) => write!(f, "Redis error: {}", e),
            WorkerError::CommandMissing => write!(f, "Command is missing"),
            WorkerError::CommandUnknown(cmd) => write!(f, "Unknown command: {}", cmd),
            WorkerError::ArgumentMissing(arg) => write!(f, "Missing required argument: {}", arg),
            WorkerError::ArgumentInvalid { name, reason } => {
                write!(f, "Invalid argument {}: {}", name, reason)
            }
            WorkerError::JobFailed(reason) => write!(f, "Job failed: {}", reason),
            WorkerError::Timeout => write!(f, "Operation timed out"),
        }
    }
}

impl std::error::Error for WorkerError {}

impl From<redis::RedisError> for WorkerError {
    fn from(err: redis::RedisError) -> Self {
        WorkerError::Redis(err)
    }
}

pub type Result<T> = std::result::Result<T, WorkerError>;
