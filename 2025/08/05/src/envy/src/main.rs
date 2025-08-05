use std::fs::{self, File, OpenOptions};
use std::io::Read;
use std::os::unix::fs::PermissionsExt;
use std::os::unix::fs::OpenOptionsExt;
use std::path::PathBuf;

use anyhow::{anyhow, Context, Result};
use clap::{Parser, Subcommand};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    Local {
        #[command(subcommand)]
        action: Action,
    },
    Secret {
        #[command(subcommand)]
        action: Action,
    },
    Global {
        #[command(subcommand)]
        action: Action,
    },
}

#[derive(Subcommand)]
enum Action {
    Get { path: Vec<String> },
    Set { path: Vec<String> },
    Del { path: Vec<String> },
}

#[derive(Debug, Serialize, Deserialize)]
struct Config {
    #[serde(flatten)]
    data: serde_json::Map<String, Value>,
}

impl Config {
    fn get_value(&self, path: &[String]) -> Option<Value> {
        let mut current = Value::Object(self.data.clone());
        for key in path {
            current = current.get(key)?.clone();
        }
        Some(current)
    }

    fn set_value(&mut self, path: &[String], value: Value) -> Result<()> {
        if path.is_empty() {
            return Err(anyhow!("Path cannot be empty"));
        }

        let mut current = &mut self.data;
        for key in path.iter().take(path.len() - 1) {
            current = current
                .entry(key)
                .or_insert_with(|| Value::Object(serde_json::Map::new()))
                .as_object_mut()
                .ok_or_else(|| anyhow!("Invalid path: expected object"))?;
        }

        let last_key = path.last().unwrap();
        current.insert(last_key.clone(), value);
        Ok(())
    }

    fn delete_value(&mut self, path: &[String]) -> Result<()> {
        if path.is_empty() {
            return Err(anyhow!("Path cannot be empty"));
        }

        let mut current = &mut self.data;
        for key in path.iter().take(path.len() - 1) {
            current = current
                .get_mut(key)
                .and_then(|v| v.as_object_mut())
                .ok_or_else(|| anyhow!("Invalid path"))?;
        }

        let last_key = path.last().unwrap();
        current.remove(last_key);
        Ok(())
    }
}

fn get_secrets_dir() -> Result<PathBuf> {
    let home = dirs::home_dir().ok_or_else(|| anyhow!("Could not determine home directory"))?;
    Ok(home.join(".secrets"))
}

fn ensure_secrets_dir() -> Result<()> {
    let secrets_dir = get_secrets_dir()?;
    if !secrets_dir.exists() {
        fs::create_dir_all(&secrets_dir)?;
        fs::set_permissions(&secrets_dir, fs::Permissions::from_mode(0o700))?;
    }
    Ok(())
}

fn get_global_config_file() -> Result<PathBuf> {
    Ok(PathBuf::from("/usr/local/var/lib/org/au0/envy.json"))
}

fn ensure_global_config_dir() -> Result<()> {
    let global_config_path = get_global_config_file()?;
    if let Some(parent) = global_config_path.parent() {
        if !parent.exists() {
            fs::create_dir_all(parent)?;
        }
    }
    Ok(())
}

fn get_config_file(config_type: &str) -> Result<PathBuf> {
    match config_type {
        "global" => get_global_config_file(),
        _ => {
            let secrets_dir = get_secrets_dir()?;
            Ok(secrets_dir.join(format!("{}.json", config_type)))
        }
    }
}

fn read_config(config_type: &str) -> Result<Config> {
    if config_type == "global" {
        ensure_global_config_dir()?;
    } else {
        ensure_secrets_dir()?;
    }
    let file_path = get_config_file(config_type)?;

    if !file_path.exists() {
        let file = OpenOptions::new()
            .write(true)
            .create(true)
            .mode(0o600)
            .open(&file_path)?;
        serde_json::to_writer(&file, &json!({}))?;
    }

    let mut file = File::open(&file_path)?;
    let mut contents = String::new();
    file.read_to_string(&mut contents)?;
    let config: Config = serde_json::from_str(&contents)
        .with_context(|| format!("Failed to parse {}", file_path.display()))?;
    Ok(config)
}

fn write_config(config_type: &str, config: &Config) -> Result<()> {
    let file_path = get_config_file(config_type)?;
    let file = OpenOptions::new()
        .write(true)
        .truncate(true)
        .create(true)
        .mode(0o600)
        .open(file_path)?;
    serde_json::to_writer_pretty(&file, &config.data)?;
    Ok(())
}

fn handle_get(config_type: &str, path: &[String]) -> Result<()> {
    let config = read_config(config_type)?;
    if let Some(value) = config.get_value(path) {
        match value {
            Value::String(s) => println!("{}", s),
            _ => println!("{}", serde_json::to_string_pretty(&value)?),
        }
    }
    Ok(())
}

fn handle_set(config_type: &str, path: &[String]) -> Result<()> {
    if path.len() < 2 {
        return Err(anyhow!("Set requires at least a key and a value"));
    }

    let mut config = read_config(config_type)?;
    let (path, value) = path.split_at(path.len() - 1);
    let value = value[0].clone();
    
    // Try to parse as JSON first, fall back to string if that fails
    let json_value = serde_json::from_str(&value).unwrap_or_else(|_| json!(value));
    config.set_value(path, json_value)?;
    write_config(config_type, &config)?;
    Ok(())
}

fn handle_del(config_type: &str, path: &[String]) -> Result<()> {
    let mut config = read_config(config_type)?;
    config.delete_value(path)?;
    write_config(config_type, &config)?;
    Ok(())
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Commands::Local { action } => match action {
            Action::Get { path } => handle_get("localenv", &path),
            Action::Set { path } => handle_set("localenv", &path),
            Action::Del { path } => handle_del("localenv", &path),
        },
        Commands::Secret { action } => match action {
            Action::Get { path } => handle_get("secrets", &path),
            Action::Set { path } => handle_set("secrets", &path),
            Action::Del { path } => handle_del("secrets", &path),
        },
        Commands::Global { action } => match action {
            Action::Get { path } => handle_get("global", &path),
            Action::Set { path } => handle_set("global", &path),
            Action::Del { path } => handle_del("global", &path),
        },
    }
}
