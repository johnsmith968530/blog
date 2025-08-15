use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use std::process::Command;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RedisConfig {
    pub host: String,
    pub port: u16,
    pub password: String,
}

impl RedisConfig {
    pub fn from_envy() -> Result<Self> {
        let host = envy_secret_get(&["redis", "host"])?;
        let port_str = envy_secret_get(&["redis", "port"])?;
        let password = envy_secret_get(&["redis", "password"])?;
        
        let port = port_str.parse::<u16>()
            .context("Failed to parse Redis port as u16")?;
        
        Ok(RedisConfig {
            host,
            port,
            password,
        })
    }

    pub fn to_url(&self) -> String {
        format!("redis://:{}@{}:{}/", self.password, self.host, self.port)
    }
}

fn envy_secret_get(path: &[&str]) -> Result<String> {
    let mut cmd = Command::new("envy");
    cmd.arg("secret").arg("get");
    
    for part in path {
        cmd.arg(part);
    }
    
    let output = cmd.output()
        .context("Failed to execute envy command")?;
    
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(anyhow::anyhow!(
            "envy command failed for {}: {}", 
            path.join("."),
            stderr
        ));
    }
    
    let value = String::from_utf8(output.stdout)
        .context("Failed to parse envy output as UTF-8")?
        .trim()
        .to_string();
    
/*     if value.is_empty() {
        return Err(anyhow::anyhow!(
            "Empty value returned for {}", 
            path.join(".")
        ));
    } */
    
    Ok(value)
}
