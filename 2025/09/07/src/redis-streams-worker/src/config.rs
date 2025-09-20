use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::fs;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RedisConfig {
    pub host: String,
    pub port: u16,
    pub password: String,
}

pub struct SecretsFile {
    value: Value,
}

impl SecretsFile {
    pub fn read() -> Result<Self> {
        // Get home directory
        let home = dirs::home_dir().context("Could not find home directory")?;
        let secrets_file = home.join(".secrets").join("secrets.json");
        
        // Read and parse secrets file
        let secrets_content = fs::read_to_string(&secrets_file)
            .context("Failed to read secrets file")?;
        let value = serde_json::from_str(&secrets_content)
            .context("Failed to parse secrets file")?;
        
        Ok(Self { value })
    }

    pub fn get_value(&self, path: &str) -> Option<&Value> {
        path.split('.')
            .fold(Some(&self.value), |acc, key| {
                acc.and_then(|v| v.get(key))
            })
    }

    pub fn get_string(&self, path: &str) -> Option<String> {
        self.get_value(path)
            .and_then(|v| v.as_str())
            .map(ToOwned::to_owned)
    }
}

impl RedisConfig {
    pub fn from_secrets() -> Result<Self> {
        let secrets = SecretsFile::read()?;
        let redis = secrets.get_value("redis")
            .ok_or_else(|| anyhow::anyhow!("Redis configuration not found in secrets file"))?;
        
        serde_json::from_value(redis.clone())
            .context("Failed to parse Redis configuration")
    }

    pub fn to_url(&self) -> String {
        format!("redis://:{}@{}:{}/", self.password, self.host, self.port)
    }
}
