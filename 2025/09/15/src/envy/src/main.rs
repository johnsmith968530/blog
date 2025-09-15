use std::fs::{self, File, OpenOptions};
use std::io::{self, Read};
use std::os::unix::fs::PermissionsExt;
use std::os::unix::fs::OpenOptionsExt;
use std::path::PathBuf;

use anyhow::{anyhow, Context, Result};
use clap::{Parser, Subcommand};
use regex::Regex;
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
    Get {
        #[arg(help = "Configuration section (local, secret, global, universal)")]
        section: String,
        #[arg(help = "Path to the value")]
        path: Vec<String>,
        #[arg(long, help = "Don't output the trailing newline")]
        nonl: bool,
    },
    Keys {
        #[arg(help = "Configuration section (local, secret, global, universal)")]
        section: String,
        #[arg(help = "Path to the subtree")]
        path: Vec<String>,
    },
    Set {
        #[arg(help = "Configuration section (local, secret, global, universal)")]
        section: String,
        #[arg(help = "Path to the value, with the last argument being the value to set")]
        path: Vec<String>,
        #[arg(long, help = "Read JSON value from stdin instead of using the last argument as value")]
        json: bool,
    },
    Del {
        #[arg(help = "Configuration section (local, secret, global, universal)")]
        section: String,
        #[arg(help = "Path to the value to delete")]
        path: Vec<String>,
    },
    Search {
        #[arg(help = "Configuration section (local, secret, global, universal)")]
        section: String,
        #[arg(help = "Optional keys to descend into JSON tree, followed by required search expression")]
        args: Vec<String>,
    },
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

    fn search_value(&self, value: &Value, regex: &Regex, current_path: &[String], matches: &mut Vec<String>) {
        match value {
            Value::Object(obj) => {
                for (key, val) in obj {
                    let mut new_path = current_path.to_vec();
                    new_path.push(key.clone());
                    
                    // Check if the key matches the regex
                    if regex.is_match(key) {
                        matches.push(new_path.join(" → "));
                    }
                    
                    // Recursively search the value
                    self.search_value(val, regex, &new_path, matches);
                }
            }
            Value::Array(arr) => {
                for (index, val) in arr.iter().enumerate() {
                    let mut new_path = current_path.to_vec();
                    new_path.push(index.to_string());
                    self.search_value(val, regex, &new_path, matches);
                }
            }
            Value::String(s) => {
                if regex.is_match(s) {
                    matches.push(format!("{} → {}", current_path.join(" → "), s));
                }
            }
            Value::Number(n) => {
                let n_str = n.to_string();
                if regex.is_match(&n_str) {
                    matches.push(format!("{} → {}", current_path.join(" → "), n_str));
                }
            }
            Value::Bool(b) => {
                let b_str = b.to_string();
                if regex.is_match(&b_str) {
                    matches.push(format!("{} → {}", current_path.join(" → "), b_str));
                }
            }
            Value::Null => {
                if regex.is_match("null") {
                    matches.push(format!("{} → null", current_path.join(" → ")));
                }
            }
        }
    }
}

fn get_section_name(config_type: &str) -> &str {
    match config_type {
        "localenv" => "local",
        "secrets" => "secret", 
        "global" => "global",
        "universal" => "universal",
        _ => config_type,
    }
}

fn match_section(input: &str) -> Result<&'static str> {
    let sections = [
        ("local", "localenv"),
        ("secret", "secrets"),
        ("global", "global"),
        ("universal", "universal"),
    ];
    
    let matches: Vec<_> = sections
        .iter()
        .filter(|(name, _)| name.starts_with(input))
        .collect();
    
    match matches.len() {
        0 => Err(anyhow!("No section matches '{}'. Valid sections are: local, secret, global, universal", input)),
        1 => Ok(matches[0].1),
        _ => {
            let matching_names: Vec<_> = matches.iter().map(|(name, _)| *name).collect();
            Err(anyhow!("Ambiguous section '{}'. Could match: {}. Please be more specific.", input, matching_names.join(", ")))
        }
    }
}

fn build_path_string(section_name: &str, path: &[String]) -> String {
    if path.is_empty() {
        section_name.to_string()
    } else {
        format!("{} → {}", section_name, path.join(" → "))
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
    if PathBuf::from("/Applications").exists() {
      Ok(PathBuf::from("/usr/local/var/lib/org/au0/envy.json"))
    } else {
      Ok(PathBuf::from("/var/lib/org/au0/envy.json"))
    }
}

fn get_universal_config_file() -> Result<PathBuf> {
    let home = dirs::home_dir().ok_or_else(|| anyhow!("Could not determine home directory"))?;
    Ok(PathBuf::from(home.join("Dropbox/1/etc/envy.json")))
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
        "universal" => get_universal_config_file(),
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

fn handle_get(config_type: &str, path: &[String], nonl: bool) -> Result<()> {
    let config = read_config(config_type)?;
    if let Some(value) = config.get_value(path) {
        match value {
            Value::String(s) => {
                if nonl {
                    print!("{}", s);
                } else {
                    println!("{}", s);
                }
            },
            _ => {
                let formatted = serde_json::to_string_pretty(&value)?;
                if nonl {
                    print!("{}", formatted);
                } else {
                    println!("{}", formatted);
                }
            },
        }
    } else {
        let section_name = get_section_name(config_type);
        let path_string = build_path_string(section_name, path);
        if nonl {
            print!("Path not found: {}", path_string);
        } else {
            println!("Path not found: {}", path_string);
        }
    }
    Ok(())
}

fn handle_keys(config_type: &str, path: &[String]) -> Result<()> {
    let config = read_config(config_type)?;
    if let Some(value) = config.get_value(path) {
        match value {
            Value::Object(obj) => {
                let keys: Vec<String> = obj.keys().cloned().collect();
                let keys_json = serde_json::to_string_pretty(&keys)?;
                println!("{}", keys_json);
            },
            Value::Array(arr) => {
                let indices: Vec<String> = (0..arr.len()).map(|i| i.to_string()).collect();
                let indices_json = serde_json::to_string_pretty(&indices)?;
                println!("{}", indices_json);
            },
            _ => {
                let section_name = get_section_name(config_type);
                let path_string = build_path_string(section_name, path);
                return Err(anyhow!("Cannot get keys of a non-object/non-array value at path: {}", path_string));
            }
        }
    } else {
        let section_name = get_section_name(config_type);
        let path_string = build_path_string(section_name, path);
        return Err(anyhow!("Path not found: {}", path_string));
    }
    Ok(())
}

fn handle_set(config_type: &str, path: &[String], json_flag: bool) -> Result<()> {
    let mut config = read_config(config_type)?;
    
    let (path, json_value) = if json_flag {
        // When --json flag is used, read from stdin and parse as JSON
        if path.is_empty() {
            return Err(anyhow!("Set with --json requires at least a key path"));
        }
        
        let mut stdin_content = String::new();
        io::stdin().read_to_string(&mut stdin_content)
            .context("Failed to read from stdin")?;
        
        let json_value = serde_json::from_str(&stdin_content)
            .context("Failed to parse stdin content as JSON")?;
        
        (path, json_value)
    } else {
        // Original behavior: last argument is the value
        if path.len() < 2 {
            return Err(anyhow!("Set requires at least a key and a value"));
        }
        
        let (path, value) = path.split_at(path.len() - 1);
        let value = value[0].clone();
        
        // Try to parse as JSON first, fall back to string if that fails
        let json_value = serde_json::from_str(&value).unwrap_or_else(|_| json!(value));
        (path, json_value)
    };
    
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

fn handle_search(config_type: &str, args: &[String]) -> Result<()> {
    if args.is_empty() {
        return Err(anyhow!("Search requires at least a pattern"));
    }

    let config = read_config(config_type)?;
    
    // Split args into keys and pattern (last argument is the pattern)
    let (keys, pattern) = args.split_at(args.len() - 1);
    let pattern = &pattern[0];
    
    let regex = Regex::new(pattern)
        .with_context(|| format!("Invalid regex pattern: {}", pattern))?;
    
    let section_name = get_section_name(config_type);
    
    // If keys are provided, descend into the JSON tree first
    let search_root = if keys.is_empty() {
        Value::Object(config.data.clone())
    } else {
        match config.get_value(keys) {
            Some(value) => value,
            None => {
                let path_string = build_path_string(section_name, keys);
                println!("Path not found: {}", path_string);
                return Ok(());
            }
        }
    };
    
    // Build the initial path for search results
    let mut initial_path = vec![section_name.to_string()];
    initial_path.extend_from_slice(keys);
    
    let mut matches = Vec::new();
    config.search_value(&search_root, &regex, &initial_path, &mut matches);
    
    if matches.is_empty() {
        if keys.is_empty() {
            println!("No matches found for pattern: {}", pattern);
        } else {
            let path_string = build_path_string(section_name, keys);
            println!("No matches found for pattern '{}' in path: {}", pattern, path_string);
        }
    } else {
        for match_result in matches {
            println!("{}", match_result);
        }
    }
    
    Ok(())
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Commands::Get { section, path, nonl } => {
            let config_type = match_section(&section)?;
            handle_get(config_type, &path, nonl)
        },
        Commands::Keys { section, path } => {
            let config_type = match_section(&section)?;
            handle_keys(config_type, &path)
        },
        Commands::Set { section, path, json } => {
            let config_type = match_section(&section)?;
            handle_set(config_type, &path, json)
        },
        Commands::Del { section, path } => {
            let config_type = match_section(&section)?;
            handle_del(config_type, &path)
        },
        Commands::Search { section, args } => {
            let config_type = match_section(&section)?;
            handle_search(config_type, &args)
        },
    }
}
