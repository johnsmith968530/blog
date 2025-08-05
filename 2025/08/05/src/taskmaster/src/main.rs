use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use serde::{Deserialize, Serialize};
use std::fs::File;
use std::io::{BufReader, BufWriter};
use std::process::{Command, Stdio};

const TASKMASTER_FILE: &str = "/Users/x/Dropbox/2/Data/Taskmaster/taskmaster.json";

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Task {
    id: i32,
    text: String,
    #[serde(default)]
    comment: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    shortcut: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    hub_id: Option<i32>,
}

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Find tasks matching a pattern
    Find {
        /// Search pattern
        pattern: String,
    },
    /// Inspect a task by ID or shortcut
    Inspect {
        /// Task ID or shortcut
        id: String,
    },
    /// Print task text by ID or shortcut
    Print {
        /// Task ID or shortcut
        id: String,
    },
    /// Copy task text to clipboard by ID or shortcut
    Copy {
        /// Task ID or shortcut
        id: String,
    },
    /// Add a new task
    Add {
        /// Task text
        text: String,
        /// Task comment
        #[arg(default_value = "")]
        comment: String,
        /// Task shortcut
        #[arg(default_value = None)]
        shortcut: Option<String>,
    },
}

fn read_tasks() -> Result<Vec<Task>> {
    let file = File::open(TASKMASTER_FILE)
        .with_context(|| format!("Failed to open {}", TASKMASTER_FILE))?;
    let reader = BufReader::new(file);
    serde_json::from_reader(reader).context("Failed to parse JSON")
}

fn write_tasks(tasks: &[Task]) -> Result<()> {
    let file = File::create(TASKMASTER_FILE)
        .with_context(|| format!("Failed to create {}", TASKMASTER_FILE))?;
    let writer = BufWriter::new(file);
    serde_json::to_writer_pretty(writer, tasks).context("Failed to write JSON")
}

fn find_task<'a>(tasks: &'a [Task], id_or_shortcut: &str) -> Option<&'a Task> {
    tasks.iter().find(|task| {
        task.id.to_string() == id_or_shortcut || 
        task.shortcut.as_deref() == Some(id_or_shortcut)
    })
}

fn copy_to_clipboard(text: &str) -> Result<()> {
    let mut child = Command::new("pbcopy")
        .stdin(Stdio::piped())
        .spawn()
        .context("Failed to spawn pbcopy")?;

    if let Some(mut stdin) = child.stdin.take() {
        use std::io::Write;
        stdin.write_all(text.as_bytes())?;
    }

    child.wait().context("Failed to wait for pbcopy")?;
    Ok(())
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    let mut tasks = read_tasks()?;

    match cli.command {
        Commands::Find { pattern } => {
            for task in tasks.iter() {
                if task.text.to_lowercase().contains(&pattern.to_lowercase()) {
                    println!("{}", serde_json::to_string_pretty(task)?);
                }
            }
        }
        Commands::Inspect { id } => {
            if let Some(task) = find_task(&tasks, &id) {
                println!("{}", serde_json::to_string_pretty(task)?);
            }
        }
        Commands::Print { id } => {
            if let Some(task) = find_task(&tasks, &id) {
                println!("{}", task.text);
            }
        }
        Commands::Copy { id } => {
            if let Some(task) = find_task(&tasks, &id) {
                println!("{}", serde_json::to_string_pretty(task)?);
                copy_to_clipboard(&task.text)?;
            }
        }
        Commands::Add { text, comment, shortcut } => {
            let max_id = tasks.iter().map(|t| t.id).max().unwrap_or(-999999);
            let new_task = Task {
                id: max_id + 1,
                text,
                comment,
                shortcut,
                hub_id: None,
            };
            tasks.push(new_task.clone());
            write_tasks(&tasks)?;
            println!("{}", serde_json::to_string_pretty(&new_task)?);
        }
    }

    Ok(())
}
