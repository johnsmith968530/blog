# Stardate Redis Streams Worker

A Rust-based worker that processes stardate conversion jobs using Redis Streams. This is an improved version of the original Redis Queue-based worker, offering better scalability, message persistence, and error handling.

## Features

- Uses Redis Streams for reliable message processing
- Consumer group support for scalable processing
- Automatic message acknowledgment
- Separate error stream for failed jobs
- Message persistence and replay capability
- Supports all original stardate operations:
  - Convert date/time to stardate
  - Convert stardate to date/time
  - Calculate time difference between stardates
  - Convert between stardates and UNIX timestamps

## Architecture

The worker uses Redis Streams instead of traditional Redis Queues, providing several advantages:

- **Message Persistence**: Messages in the stream are persisted and can be replayed if needed
- **Consumer Groups**: Multiple workers can process messages concurrently
- **Better Error Handling**: Failed messages are moved to a separate error stream
- **Message Acknowledgment**: Explicit message acknowledgment ensures reliable processing

### Streams and Consumer Groups

- Main stream: `stardate:stream` - Where jobs are submitted
- Consumer group: `stardate:group` - For processing jobs
- Response stream: `stardate:responses` - Where results and errors are published
- Error stream: `stardate:errors` - For tracking failed jobs

## Setup

1. Create a Redis configuration in `~/.secrets/secrets.json`:
   ```json
   {
     "redis": {
       "host": "your-redis-host",
       "port": your-redis-port,
       "password": "your-redis-password"
     }
   }
   ```

2. Build and run the worker:
   ```bash
   cargo build --release
   cargo run --release
   ```

3. Send jobs to the stream using the Redis CLI or a client library:
   ```bash
   # Example: Convert current time to stardate
   XADD stardate:stream * job '{"id":"123","command":"to_stardate","args":{"datetime":"now"}}'
   
   # Example: Convert stardate to date/time
   XADD stardate:stream * job '{"id":"124","command":"from_stardate","args":{"stardate":2024.1,"timezone":"America/Los_Angeles"}}'
   ```

4. Check results using Redis CLI:
   ```bash
   # Read from response stream
   XREAD BLOCK 0 STREAMS stardate:responses $
   
   # Read last 10 responses
   XREVRANGE stardate:responses + - COUNT 10
   ```

## Error Handling

- Failed jobs are moved to the `stardate:errors` stream for tracking
- Both successful results and errors are published to the `stardate:responses` stream
- The response stream is capped at 1000 entries using MAXLEN
- Clients can block-read from the response stream to receive results immediately

## Monitoring

Monitor the streams using Redis CLI:
```bash
# View stream contents
XRANGE stardate:stream - +

# View error stream (failed jobs)
XRANGE stardate:errors - +

# View response stream (results and errors)
XRANGE stardate:responses - +

# View consumer group info
XINFO GROUPS stardate:stream


xgroup destroy stardate:requests stardate:workers
xgroup create stardate:requests stardate:workers 0
xgroup delconsumer stardate:requests stardate:workers worker:1

* See `/home/c/Dropbox/3/Documents/man/R/Redis/1/README.md` for more Redis-specif information.
