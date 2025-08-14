use anyhow::Context;
use async_trait::async_trait;
use chrono::{DateTime, Datelike, TimeZone, Utc, NaiveDateTime};
use chrono_tz::Tz;
use redis_streams_worker::{CommandHandler, RedisConfig, StreamConfig, Worker, Result, WorkerError};
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
struct ToStardateArgs {
    datetime: String,
    timezone: Option<String>,
    format: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
struct FromStardateArgs {
    stardate: f64,
    timezone: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct StardateDiffArgs {
    stardate1: f64,
    stardate2: f64,
    unit: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct StardateToUnixArgs {
    stardate: f64,
}

#[derive(Debug, Serialize, Deserialize)]
struct UnixToStardateArgs {
    timestamp: i64,
    format: Option<String>,
}

struct StardateHandler {
    redis_client: redis::Client,
}

fn year_to_epoch(year: i32) -> i64 {
    Utc.with_ymd_and_hms(year, 1, 1, 0, 0, 0)
        .unwrap()
        .timestamp()
}

fn date_to_stardate(date: DateTime<Utc>) -> f64 {
    let year = date.year();
    let t0 = year_to_epoch(year);
    let t1 = year_to_epoch(year + 1);
    year as f64 + (date.timestamp() - t0) as f64 / (t1 - t0) as f64
}

fn stardate_to_date(stardate: f64, timezone: &str) -> anyhow::Result<DateTime<Tz>> {
    let year = stardate.floor() as i32;
    let t0 = year_to_epoch(year);
    let t1 = year_to_epoch(year + 1);
    let tx = t0 + ((t1 - t0) as f64 * (stardate - year as f64)) as i64;
    let utc = Utc.timestamp_opt(tx, 0).unwrap();
    let tz: Tz = timezone.parse().map_err(|e| anyhow::anyhow!("Invalid timezone: {}", e))?;
    Ok(utc.with_timezone(&tz))
}

impl StardateHandler {
    fn new(redis_config: RedisConfig) -> anyhow::Result<Self> {
        let redis_client = redis::Client::open(redis_config.to_url())?;
        Ok(Self { redis_client })
    }

    async fn handle_to_stardate(&self, args_str: &str) -> Result<String> {
        let args: ToStardateArgs = serde_json::from_str(args_str)
            .map_err(|e| WorkerError::ArgumentInvalid {
                name: "args".to_string(),
                reason: format!("Invalid JSON: {}", e),
            })?;
        let datetime = args.datetime;
        let format = args.format.unwrap_or_else(|| "canonical".to_string());
        
        let dt = if datetime == "now" {
            Utc::now()
        } else {
            let timezone = args.timezone.ok_or_else(|| WorkerError::ArgumentInvalid {
                name: "timezone".to_string(),
                reason: "timezone is required when datetime is not \"now\"".to_string(),
            })?;
            
            let tz: Tz = timezone.parse::<Tz>()
                .map_err(|e: chrono_tz::ParseError| WorkerError::ArgumentInvalid { 
                    name: "timezone".to_string(), 
                    reason: e.to_string() 
                })?;
            
            let naive_dt = NaiveDateTime::parse_from_str(&datetime, "%Y-%m-%dT%H:%M:%S")
                .or_else(|_| NaiveDateTime::parse_from_str(&datetime, "%Y-%m-%d %H:%M:%S"))
                .map_err(|_| WorkerError::ArgumentInvalid {
                    name: "datetime".to_string(),
                    reason: "Invalid format. Expected YYYY-MM-DDThh:mm:ss or YYYY-MM-DD hh:mm:ss".to_string()
                })?;
            
            tz.from_local_datetime(&naive_dt)
                .single()
                .ok_or_else(|| WorkerError::ArgumentInvalid {
                    name: "datetime".to_string(),
                    reason: "Invalid or ambiguous local time".to_string()
                })?
                .with_timezone(&Utc)
        };

        let stardate = date_to_stardate(dt);
        let precision = match format.as_str() {
            "short" => 3,
            "medium" => 6,
            _ => 15,
        };

        Ok(format!("{:.1$}", stardate, precision))
    }

    async fn handle_from_stardate(&self, args_str: &str) -> Result<String> {
        let args: FromStardateArgs = serde_json::from_str(args_str)
            .map_err(|e| WorkerError::ArgumentInvalid {
                name: "args".to_string(),
                reason: format!("Invalid JSON: {}", e),
            })?;
        let stardate = args.stardate;
        let timezone = args.timezone;
        
        let dt = stardate_to_date(stardate, &timezone)
            .map_err(|e| WorkerError::JobFailed(e.to_string()))?;
        
        Ok(dt.format("%Y-%m-%d %H:%M:%S (%A, %B %d, %Y %Z)").to_string())
    }

    async fn handle_stardate_diff(&self, args_str: &str) -> Result<String> {
        let args: StardateDiffArgs = serde_json::from_str(args_str)
            .map_err(|e| WorkerError::ArgumentInvalid {
                name: "args".to_string(),
                reason: format!("Invalid JSON: {}", e),
            })?;
        let stardate1 = args.stardate1;
        let stardate2 = args.stardate2;
        let unit = args.unit;

        let dt1 = stardate_to_date(stardate1, "UTC")
            .map_err(|e| WorkerError::JobFailed(e.to_string()))?;
        let dt2 = stardate_to_date(stardate2, "UTC")
            .map_err(|e| WorkerError::JobFailed(e.to_string()))?;
        
        let diff = match unit.as_str() {
            "years" => (dt2 - dt1).num_days() as f64 / 365.25,
            "months" => (dt2 - dt1).num_days() as f64 / 30.44,
            "weeks" => (dt2 - dt1).num_weeks() as f64,
            "days" => (dt2 - dt1).num_days() as f64,
            "hours" => (dt2 - dt1).num_hours() as f64,
            "minutes" => (dt2 - dt1).num_minutes() as f64,
            "seconds" => (dt2 - dt1).num_seconds() as f64,
            "milliseconds" => (dt2 - dt1).num_milliseconds() as f64,
            _ => return Err(WorkerError::ArgumentInvalid {
                name: "unit".to_string(),
                reason: format!("Invalid unit: {}", unit),
            }),
        };

        Ok(format!("{} {}", diff.abs().round(), unit))
    }

    async fn handle_stardate_to_unix(&self, args_str: &str) -> Result<String> {
        let args: StardateToUnixArgs = serde_json::from_str(args_str)
            .map_err(|e| WorkerError::ArgumentInvalid {
                name: "args".to_string(),
                reason: format!("Invalid JSON: {}", e),
            })?;
        let stardate = args.stardate;
        let dt = stardate_to_date(stardate, "UTC")
            .map_err(|e| WorkerError::JobFailed(e.to_string()))?;
        Ok(dt.timestamp().to_string())
    }

    async fn handle_unix_to_stardate(&self, args_str: &str) -> Result<String> {
        let args: UnixToStardateArgs = serde_json::from_str(args_str)
            .map_err(|e| WorkerError::ArgumentInvalid {
                name: "args".to_string(),
                reason: format!("Invalid JSON: {}", e),
            })?;
        let timestamp = args.timestamp;
        let format = args.format.unwrap_or_else(|| "canonical".to_string());
        
        let dt = Utc.timestamp_opt(timestamp, 0)
            .single()
            .ok_or_else(|| WorkerError::ArgumentInvalid {
                name: "timestamp".to_string(),
                reason: "Invalid timestamp".to_string()
            })?;
        
        let stardate = date_to_stardate(dt);
        let precision = match format.as_str() {
            "short" => 3,
            "medium" => 6,
            _ => 15,
        };

        Ok(format!("{:.1$}", stardate, precision))
    }
}

#[async_trait]
impl CommandHandler for StardateHandler {
    async fn handle_command(&self, command: &str, args: &str) -> Result<String> {
        match command {
            "to_stardate" => self.handle_to_stardate(args).await,
            "from_stardate" => self.handle_from_stardate(args).await,
            "stardate_diff" => self.handle_stardate_diff(args).await,
            "stardate_to_unix" => self.handle_stardate_to_unix(args).await,
            "unix_to_stardate" => self.handle_unix_to_stardate(args).await,
            _ => Err(WorkerError::CommandUnknown(command.to_string())),
        }
    }

    fn get_commands(&self) -> Vec<String> {
        vec![
            "to_stardate".to_string(),
            "from_stardate".to_string(),
            "stardate_diff".to_string(),
            "stardate_to_unix".to_string(),
            "unix_to_stardate".to_string(),
        ]
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let redis_config = RedisConfig::from_secrets()
        .context("Failed to get Redis configuration")?;
    
    let stream_config = StreamConfig::with_namespace("stardate");
    let handler = Box::new(StardateHandler::new(redis_config.clone())?);
    let worker = Worker::new(redis_config, stream_config, handler);
    
    println!("Starting Stardate Redis Streams worker...");
    worker.run().await.context("Worker failed")?;
    
    Ok(())
}
