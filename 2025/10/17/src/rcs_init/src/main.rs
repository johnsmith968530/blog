use anyhow::{anyhow, Context, Result};
use clap::Parser;
use path_clean::clean;
use regex::Regex;
use std::env;
use std::fs;
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};
use std::process::Command;
use which::which;

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Enable binary file mode
    #[arg(long)]
    binary: bool,

    /// Files to process
    files: Vec<String>,
}

fn get_description(file_path: &Path) -> Result<String> {
    let abs_path = fs::canonicalize(file_path)?;
    let abs_str = abs_path.to_string_lossy();
    
    // Match and capture cloud storage paths in any home directory
    let re = Regex::new(r"^/(home/[^/]+|Users/[^/]/Library/CloudStorage)/((Dropbox|MEGA|Nextcloud)/.*)$").unwrap();
    if let Some(caps) = re.captures(&abs_str) {
        return Ok(caps[2].to_string());
    }
    
    let hostname = hostname::get()?.to_string_lossy().into_owned();
    let hostname = hostname.strip_suffix(".local").unwrap_or(&hostname).to_string();
    Ok(format!("{}:{}", hostname, abs_str))
}

fn safe_exec(command: &str, args: &[&str]) -> Result<()> {
    let status = Command::new(command)
        .args(args)
        .status()
        .with_context(|| format!("Failed to execute {} with args {:?}", command, args))?;

    if !status.success() {
        return Err(anyhow!(
            "Command {} {:?} failed with status {}",
            command,
            args,
            status
        ));
    }
    Ok(())
}

fn process_file(file_path: &Path, binary: bool) -> Result<()> {
    let file_path = clean(file_path.to_path_buf());
    let dir = file_path.parent().unwrap_or_else(|| Path::new("."));
    let base = file_path.file_name().unwrap();
    let rcs_dir = dir.join("RCS");

    // Create RCS directory if it doesn't exist
    if !rcs_dir.exists() {
        fs::create_dir(&rcs_dir)?;
        fs::set_permissions(&rcs_dir, fs::Permissions::from_mode(0o770))?;
    }

    let rcs_file = rcs_dir.join(format!("{},v", base.to_string_lossy()));
    
    if !file_path.is_file() {
        return Ok(());
    }

    if rcs_file.exists() {
        // Check for uncommitted changes using rcsdiff
        let output = Command::new("rcsdiff")
            .arg("-q")
            .arg(&file_path)
            .output()
            .with_context(|| format!("Failed to run rcsdiff on {}", file_path.display()))?;

        if !output.status.success() {
            return Err(anyhow!(
                "{} has uncommitted changes. Please check in manually using: ci -l -m\"<message>\" {}",
                file_path.display(),
                file_path.display()
            ));
        }
        return Ok(());
    }

    // Initialize new RCS entry
    if file_path.is_file() {
        let desc = get_description(&file_path)?;
        let file_str = file_path.to_string_lossy();
        
        if binary {
            safe_exec("rcs", &["-i", "-kb", &format!("-t-{}", desc), "-x,v", &file_str])?;
            safe_exec("ci", &["-l", &file_str])?;
        } else {
            safe_exec("ci", &[&format!("-t-{}", desc), "-x,v", &file_str])?;
            safe_exec("co", &[&file_str])?;
            safe_exec("rcs", &["-l", "-x,v", &file_str])?;
        }
        
        safe_exec("chmod", &["u+w", &file_str])?;
    }

    println!("{}", file_path.display());
    Ok(())
}

fn main() -> Result<()> {
    // Check if RCS is available
    which("rcs").context("RCS is not installed")?;

    let args = Args::parse();
    let cwd = env::current_dir()?;
    let mut has_errors = false;

    for file in args.files {
        let path = if Path::new(&file).is_absolute() {
            PathBuf::from(file)
        } else {
            cwd.join(file)
        };
        
        if let Err(e) = process_file(&path, args.binary) {
            eprintln!("Error processing {}: {}", path.display(), e);
            has_errors = true;
        }
    }

    if has_errors {
        return Err(anyhow!("One or more files failed to process"));
    }

    Ok(())
}

// vim: set et ff=unix ft=rust nocp sts=2 sw=2 ts=2:
