use std::fs::{File, OpenOptions};
use std::io::{self, Read};
use std::os::unix::fs::OpenOptionsExt;
use std::path::PathBuf;

use anyhow::{anyhow, Context, Result};
use clap::{Parser, Subcommand};
use regex::{Regex, RegexBuilder};
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
        #[arg(long, help = "Custom JSON file to operate on")]
        file: Option<PathBuf>,
        #[arg(help = "Configuration section (local, secret, global, universal) or path arguments")]
        args: Vec<String>,
        #[arg(long, help = "Don't output the trailing newline")]
        nonl: bool,
    },
    Keys {
        #[arg(long, help = "Custom JSON file to operate on")]
        file: Option<PathBuf>,
        #[arg(help = "Configuration section (local, secret, global, universal) or path arguments")]
        args: Vec<String>,
    },
    Set {
        #[arg(long, help = "Custom JSON file to operate on")]
        file: Option<PathBuf>,
        #[arg(help = "Configuration section (local, secret, global, universal) or path arguments")]
        args: Vec<String>,
        #[arg(long, help = "Read JSON value from stdin instead of using the last argument as value")]
        json: bool,
    },
    Del {
        #[arg(long, help = "Custom JSON file to operate on")]
        file: Option<PathBuf>,
        #[arg(help = "Configuration section (local, secret, global, universal) or path arguments")]
        args: Vec<String>,
    },
    Find {
        #[arg(long, help = "Custom JSON file to operate on")]
        file: Option<PathBuf>,
        #[arg(help = "Configuration section (local, secret, global, universal) or search arguments")]
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


fn get_global_config_file() -> Result<PathBuf> {
    if PathBuf::from("/Applications").exists() {
      Ok(PathBuf::from("/usr/local/var/lib/com/m0x13/envy.json"))
    } else {
      Ok(PathBuf::from("/var/lib/com/m0x13/envy.json"))
    }
}

fn get_universal_config_file() -> Result<PathBuf> {
    let home = dirs::home_dir().ok_or_else(|| anyhow!("Could not determine home directory"))?;
    Ok(PathBuf::from(home.join("Dropbox/1/etc/envy.json")))
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


fn file_open_error(file_path: &PathBuf, err: io::Error) -> anyhow::Error {
    if err.kind() == io::ErrorKind::NotFound {
        anyhow!("File not found: {}", file_path.display())
    } else {
        anyhow!("Failed to open {}: {}", file_path.display(), err)
    }
}

fn read_config_from_file(file_path: &PathBuf) -> Result<Config> {
    if !file_path.exists() {
        let file = OpenOptions::new()
            .write(true)
            .create(true)
            .mode(0o600)
            .open(file_path)
            .map_err(|err| file_open_error(file_path, err))?;
        serde_json::to_writer(&file, &json!({}))?;
    }

    let mut file = File::open(file_path).map_err(|err| file_open_error(file_path, err))?;
    let mut contents = String::new();
    file.read_to_string(&mut contents)?;
    let config: Config = serde_json::from_str(&contents)
        .with_context(|| format!("Failed to parse {}", file_path.display()))?;
    Ok(config)
}

fn write_config_to_file(file_path: &PathBuf, config: &Config) -> Result<()> {
    let file = OpenOptions::new()
        .write(true)
        .truncate(true)
        .create(true)
        .mode(0o600)
        .open(file_path)
        .map_err(|err| file_open_error(file_path, err))?;
    serde_json::to_writer_pretty(&file, &config.data)?;
    Ok(())
}

fn resolve_config_source(section: &Option<String>, file: &Option<PathBuf>) -> Result<(PathBuf, String)> {
    match (section, file) {
        (Some(section), None) => {
            let config_type = match_section(section)?;
            let file_path = get_config_file(config_type)?;
            let display_name = get_section_name(config_type).to_string();
            Ok((file_path, display_name))
        },
        (None, Some(file)) => {
            let display_name = file.file_name()
                .and_then(|name| name.to_str())
                .unwrap_or("file")
                .to_string();
            Ok((file.clone(), display_name))
        },
        (None, None) => Err(anyhow!("Either section or --file must be specified")),
        (Some(_), Some(_)) => Err(anyhow!("Cannot specify both section and --file")),
    }
}

fn handle_get_unified(section: &Option<String>, file: &Option<PathBuf>, path: &[String], nonl: bool) -> Result<()> {
    let (file_path, display_name) = resolve_config_source(section, file)?;
    let config = read_config_from_file(&file_path)?;
    
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
        let path_string = build_path_string(&display_name, path);
        if nonl {
            print!("Path not found: {}", path_string);
        } else {
            println!("Path not found: {}", path_string);
        }
    }
    Ok(())
}

fn handle_keys_unified(section: &Option<String>, file: &Option<PathBuf>, path: &[String]) -> Result<()> {
    let (file_path, display_name) = resolve_config_source(section, file)?;
    let config = read_config_from_file(&file_path)?;
    
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
                let path_string = build_path_string(&display_name, path);
                return Err(anyhow!("Cannot get keys of a non-object/non-array value at path: {}", path_string));
            }
        }
    } else {
        let path_string = build_path_string(&display_name, path);
        return Err(anyhow!("Path not found: {}", path_string));
    }
    Ok(())
}

fn handle_set_unified(section: &Option<String>, file: &Option<PathBuf>, path: &[String], json_flag: bool) -> Result<()> {
    let (file_path, _display_name) = resolve_config_source(section, file)?;
    let mut config = read_config_from_file(&file_path)?;
    
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
    write_config_to_file(&file_path, &config)?;
    Ok(())
}

fn handle_del_unified(section: &Option<String>, file: &Option<PathBuf>, path: &[String]) -> Result<()> {
    let (file_path, _display_name) = resolve_config_source(section, file)?;
    let mut config = read_config_from_file(&file_path)?;
    config.delete_value(path)?;
    write_config_to_file(&file_path, &config)?;
    Ok(())
}

fn handle_find_unified(section: &Option<String>, file: &Option<PathBuf>, args: &[String]) -> Result<()> {
    if args.is_empty() {
        return Err(anyhow!("Search requires at least a pattern"));
    }

    let (file_path, display_name) = resolve_config_source(section, file)?;
    let config = read_config_from_file(&file_path)?;
    
    // Split args into keys and pattern (last argument is the pattern)
    let (keys, pattern) = args.split_at(args.len() - 1);
    let pattern = &pattern[0];
    
    let regex = RegexBuilder::new(pattern)
        .case_insensitive(true)
        .build()
        .with_context(|| format!("Invalid regex pattern: {}", pattern))?;
    
    // If keys are provided, descend into the JSON tree first
    let search_root = if keys.is_empty() {
        Value::Object(config.data.clone())
    } else {
        match config.get_value(keys) {
            Some(value) => value,
            None => {
                let path_string = build_path_string(&display_name, keys);
                println!("Path not found: {}", path_string);
                return Ok(());
            }
        }
    };
    
    // Build the initial path for search results
    let mut initial_path = vec![display_name.clone()];
    initial_path.extend_from_slice(keys);
    
    let mut matches = Vec::new();
    config.search_value(&search_root, &regex, &initial_path, &mut matches);
    
    if matches.is_empty() {
        if keys.is_empty() {
            println!("No matches found for pattern: {}", pattern);
        } else {
            let path_string = build_path_string(&display_name, keys);
            println!("No matches found for pattern '{}' in path: {}", pattern, path_string);
        }
    } else {
        for match_result in matches {
            println!("{}", match_result);
        }
    }
    
    Ok(())
}


fn match_command(input: &str) -> Result<String> {
    let commands = ["get", "keys", "set", "del", "find"];
    
    let matches: Vec<_> = commands
        .iter()
        .filter(|command| command.starts_with(input))
        .collect();
    
    match matches.len() {
        0 => Err(anyhow!("No command matches '{}'. Valid commands are: {}", input, commands.join(", "))),
        1 => Ok(matches[0].to_string()),
        _ => {
            let matching_names: Vec<&str> = matches.iter().map(|&name| *name).collect();
            Err(anyhow!("Ambiguous command '{}'. Could match: {}. Please be more specific.", input, matching_names.join(", ")))
        }
    }
}

fn parse_args_for_section_and_path(file: &Option<PathBuf>, args: &[String]) -> Result<(Option<String>, Vec<String>)> {
    if file.is_some() {
        // When --file is specified, all args are path components
        Ok((None, args.to_vec()))
    } else {
        // When --file is not specified, first arg should be section
        if args.is_empty() {
            return Err(anyhow!("Either --file must be specified or a section must be provided"));
        }
        let section = Some(args[0].clone());
        let path = args[1..].to_vec();
        Ok((section, path))
    }
}

fn main() -> Result<()> {
    // Handle partial command matching
    let args: Vec<String> = std::env::args().collect();
    let mut modified_args = args.clone();
    
    // If we have at least 2 arguments (program name + command), try to expand the command
    if args.len() >= 2 {
        let potential_command = &args[1];
        // Only try to match if it doesn't start with '-' (not a flag) and is not 'help'
        if !potential_command.starts_with('-') && potential_command != "help" {
            match match_command(potential_command) {
                Ok(full_command) => {
                    modified_args[1] = full_command;
                },
                Err(e) => {
                    // If it's not a partial match, let clap handle it normally
                    // This allows clap to show its own error messages for invalid commands
                    if !["get", "keys", "set", "del", "find"].contains(&potential_command.as_str()) {
                        eprintln!("Error: {}", e);
                        std::process::exit(1);
                    }
                }
            }
        }
    }
    
    // Parse with potentially modified arguments
    let cli = Cli::parse_from(modified_args);

    match cli.command {
        Commands::Get { file, args, nonl } => {
            let (section, path) = parse_args_for_section_and_path(&file, &args)?;
            handle_get_unified(&section, &file, &path, nonl)
        },
        Commands::Keys { file, args } => {
            let (section, path) = parse_args_for_section_and_path(&file, &args)?;
            handle_keys_unified(&section, &file, &path)
        },
        Commands::Set { file, args, json } => {
            let (section, path) = parse_args_for_section_and_path(&file, &args)?;
            handle_set_unified(&section, &file, &path, json)
        },
        Commands::Del { file, args } => {
            let (section, path) = parse_args_for_section_and_path(&file, &args)?;
            handle_del_unified(&section, &file, &path)
        },
        Commands::Find { file, args } => {
            let (section, search_args) = parse_args_for_section_and_path(&file, &args)?;
            handle_find_unified(&section, &file, &search_args)
        },
    }
}
