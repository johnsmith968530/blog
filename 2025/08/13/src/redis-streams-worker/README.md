* $Source: /home/c/Dropbox/2/src/rust/redis-streams-worker/RCS/README.md,v $
* $Date: 2025/02/08 00:53:48 $
* $Revision: 1.3 $

# Redis Streams Worker

The Redis Streams workers will usually be run be [supervisord](/home/c/Dropbox/3/Documents/man/S/Supervisor/1).
* Here's `/etc/supervisor/conf.d/stardate-rs-worker.conf` as an example:
```
[program:stardate-rs-worker]
command=/home/c/Dropbox/2/src/rust/stardate-rs-worker/target/debug/stardate-rs-worker
directory=/home/c/Dropbox/2/src/rust/stardate-rs-worker
user=c
autostart=true
autorestart=true
stderr_logfile=/var/log/rs-worker/stardate.err.log
stdout_logfile=/var/log/rs-worker/stardate.out.log
```

# Common Problems

When creating a new Redis Streams worker, there are several common pitfalls to avoid:

1. Job ID Handling
   * DO NOT create custom UUIDs for job tracking
   * Use the message ID provided by Redis Streams (returned by XADD)
   * See stardate-rs-worker/test_jobs.py for the correct pattern

2. Configuration and Secrets
   * DO NOT implement custom secrets handling
   * Use RedisConfig::from_secrets() provided by this library
   * It automatically reads from ~/.secrets/secrets.json

3. Redis Library Version
   * Use redis = { version = "0.28.2", features = ["tokio-comp"] }
   * Use get_multiplexed_async_connection() instead of the deprecated get_async_connection()
   * Example:
     ```rust
     let mut con = redis_client.get_multiplexed_async_connection().await?;
     ```

4. Test Script Pattern
   * Follow the pattern in stardate-rs-worker/test_jobs.py
   * Return raw response strings without JSON parsing
   * Use Redis timeout configuration with get_timeout()
   * Keep test files (e.g., images) within your project directory

* vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
