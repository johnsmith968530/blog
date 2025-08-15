use serde_json::Value;
use crate::error::{Result, WorkerError};

/// Helper functions for parsing command arguments
pub struct Args(Value);

impl Args {
    /// Parse a JSON string into Args
    pub fn parse(args: &str) -> Result<Self> {
        let value = serde_json::from_str(args)
            .map_err(|e| WorkerError::ArgumentInvalid {
                name: "args".to_string(),
                reason: format!("Invalid JSON: {}", e),
            })?;
        Ok(Args(value))
    }

    /// Get a required string field
    pub fn get_string(&self, name: &str) -> Result<String> {
        self.0[name].as_str()
            .ok_or_else(|| WorkerError::ArgumentMissing(name.to_string()))
            .map(|s| s.to_string())
    }

    /// Get an optional string field with a default value
    pub fn get_string_or(&self, name: &str, default: &str) -> String {
        self.0[name].as_str()
            .unwrap_or(default)
            .to_string()
    }

    /// Get a required number field (parses from string)
    pub fn get_number<T>(&self, name: &str) -> Result<T> 
    where
        T: std::str::FromStr,
        T::Err: std::fmt::Display,
    {
        let str_val = self.get_string(name)?;
        str_val.parse::<T>().map_err(|e| WorkerError::ArgumentInvalid {
            name: name.to_string(),
            reason: format!("Invalid number: {}", e),
        })
    }

    /// Get a required field with custom error message for missing field
    pub fn get_string_with_error(&self, name: &str, error_msg: &str) -> Result<String> {
        self.0[name].as_str()
            .ok_or_else(|| WorkerError::ArgumentMissing(error_msg.to_string()))
            .map(|s| s.to_string())
    }
}
