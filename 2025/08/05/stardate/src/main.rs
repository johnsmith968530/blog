use chrono::{DateTime, Datelike, Local, NaiveDateTime, TimeZone, Timelike, Utc};
use chrono_tz::Tz;
use clap::Parser;
use dialoguer::Input;
use std::fs;
use std::path::PathBuf;

#[derive(Parser)]
#[command(name = "stardate")]
#[command(about = "Convert dates to and from stardates")]
struct Cli {
    #[arg(long)]
    diff: bool,

    #[arg(long)]
    hyphen: bool,

    #[arg(long)]
    interactive: bool,

    #[arg(long)]
    localtime: bool,

    #[arg(long)]
    medium: bool,

    #[arg(long)]
    mtime: Option<PathBuf>,

    #[arg(long)]
    nl: bool,

    #[arg(long)]
    round: bool,

    #[arg(long)]
    short: bool,

    #[arg(long)]
    underscore: bool,

    #[arg(trailing_var_arg = true)]
    args: Vec<String>,
}

fn year_to_epoch(year: i32) -> i64 {
    Utc.with_ymd_and_hms(year, 1, 1, 0, 0, 0)
        .unwrap()
        .timestamp()
}

fn unfmt(sd: &str) -> f64 {
    sd.replace('_', ".")
        .replace('-', ".")
        .parse()
        .unwrap_or_default()
}

fn stardate_to_datetime(sd: &str, tz: &Tz) -> DateTime<Tz> {
    let sd = unfmt(sd);
    let year = sd.floor() as i32;
    let t0 = year_to_epoch(year);
    let t1 = year_to_epoch(year + 1);
    let tx = t0 + ((t1 - t0) as f64 * (sd - year as f64)) as i64;
    let utc = Utc.timestamp_opt(tx, 0).unwrap();
    utc.with_timezone(tz)
}

fn display_diff(delta: f64, factor: f64, label: &str) -> bool {
    if delta >= factor {
        println!("{} {}", delta / factor, label);
        true
    } else {
        false
    }
}

fn prompt(prompt: &str, default: &str) -> String {
    Input::new()
        .with_prompt(format!("{} ({})", prompt, default))
        .default(default.to_string())
        .interact()
        .unwrap_or_else(|_| default.to_string())
}

fn main() {
    let cli = Cli::parse();
    // Get timezone from TZ env var or use default
    let local_tz_name = std::env::var("TZ").unwrap_or_else(|_| "UTC".to_string());
    let local_tz: Tz = local_tz_name.parse().unwrap_or(chrono_tz::UTC);

    let date_fmt = format!("%Y-%m-%d %H:%M:%S (%A, %B %-d, %Y in {} %:z)", local_tz_name);

    if cli.localtime {
        for arg in cli.args {
            let dt = stardate_to_datetime(&arg, &local_tz);
            println!("{}", dt.format(date_fmt.as_str()));
        }
        return;
    }

    if cli.diff {
        if cli.args.len() >= 2 {
            let delta = (unfmt(&cli.args[1]) - unfmt(&cli.args[0])).abs();
            if display_diff(delta, 1.0, "years")
                || display_diff(delta, 0.08333333333333333, "months")
                || display_diff(delta, 0.019165349048919554, "weeks")
                || display_diff(delta, 0.002737907006988508, "days")
                || display_diff(delta, 0.00011407945862452115, "hours")
                || display_diff(delta, 1.901324310408686e-6, "minutes")
                || display_diff(delta, 3.168873850681143e-8, "seconds")
            {
                return;
            }
            println!("{} milliseconds", delta / 3.168873850681143e-11);
        }
        return;
    }

    let tx = if cli.interactive {
        let now = Local::now();
        let mut year = now.year().to_string();
        let mut month = now.month().to_string();
        let mut day = now.day().to_string();
        let mut hour = if cli.round {
            "12".to_string()
        } else {
            now.hour().to_string()
        };
        let mut minute = if cli.round {
            "0".to_string()
        } else {
            now.minute().to_string()
        };
        let mut second = if cli.round {
            "0".to_string()
        } else {
            now.second().to_string()
        };

        loop {
            year = prompt("Year", &year);
            month = prompt("Month", &month);
            day = prompt("Day", &day);
            hour = prompt("Hour", &hour);
            minute = prompt("Minute", &minute);
            second = prompt("Second", &second);

            let dt = NaiveDateTime::parse_from_str(
                &format!(
                    "{}-{}-{} {}:{}:{}",
                    year, month, day, hour, minute, second
                ),
                "%Y-%m-%d %H:%M:%S",
            );

            match dt {
                Ok(dt) => {
                    let dt = local_tz.from_local_datetime(&dt).unwrap();
                    println!("{}", dt.format(date_fmt.as_str()));
                    break dt.with_timezone(&Utc);
                }
                Err(_) => println!("Invalid date, please try again"),
            }
        }
    } else if let Some(path) = cli.mtime {
        let metadata = fs::metadata(path).expect("Failed to get file metadata");
        let mtime = metadata.modified().expect("Failed to get modification time");
        let dt: DateTime<Utc> = mtime.into();
        dt
    } else {
        Utc::now()
    };

    let year = tx.year();
    let t0 = year_to_epoch(year);
    let t1 = year_to_epoch(year + 1);
    let sd = year as f64 + (tx.timestamp() - t0) as f64 / (t1 - t0) as f64;

    let precision = if cli.short {
        3
    } else if cli.medium {
        6
    } else {
        15
    };

    let mut formatted = format!("{:.1$}", sd, precision);

    if cli.underscore {
        formatted = formatted.replace('.', "_");
    } else if cli.hyphen {
        formatted = formatted.replace('.', "-");
    }

    print!("{}", formatted);
    if cli.nl {
        println!();
    }
}
