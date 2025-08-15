import { createClient } from 'redis';
import { getRedisConfig } from './config.js';
import { JobError } from './exceptions.js';

export class RedisStreamsClient {
  constructor(namespace) {
    const [host, port, password] = getRedisConfig();
    this.redis = createClient({
      socket: {
        host,
        port
      },
      password,
      database: 0
    });
    this.namespace = namespace;
    this.connected = false;
  }

  async connect() {
    if (!this.connected) {
      await this.redis.connect();
      this.connected = true;
    }
  }

  async disconnect() {
    if (this.connected) {
      await this.redis.disconnect();
      this.connected = false;
    }
  }

  async enqueueJob(streamName, command, args = null) {
    await this.connect();
    const fields = {
      command,
      args: args ? JSON.stringify(args) : '{}'
    };
    const jobId = await this.redis.xAdd(streamName, '*', fields);
    return jobId;
  }

  async getTimeout() {
    await this.connect();
    const timeout = await this.redis.get(`${this.namespace}:timeout`);
    if (!timeout) {
      throw new JobError(`Timeout key '${this.namespace}:timeout' does not exist`);
    }
    console.log(`${this.namespace}:timeout = ${parseInt(timeout)}`);
    return parseInt(timeout);
  }

  async getJobResult(streamName, jobId) {
    await this.connect();
    const blockMs = 5000; // 5 second blocks, same as Python implementation
    const startTime = Date.now();
    const timeout = await this.getTimeout();

    while (true) {
      // Check if we've exceeded total timeout
      const elapsed = (Date.now() - startTime) / 1000;
      if (elapsed >= timeout) {
        throw new JobError('Timeout waiting for result');
      }

      // Non-blocking check of existing messages
      const messages = await this.redis.xRevRange(streamName, '+', '-');
//    console.log('Non-blocking messages:', JSON.stringify(messages, null, 2));
      for (const message of messages) {
//      console.log('Processing message:', JSON.stringify(message, null, 2));
        if (message.job_id === jobId) {
          if ('result' in message) {
            return message.result;
          } else if ('error' in message) {
            throw new JobError(message.error);
          }
        }
      }

      // Calculate remaining time for blocking read
      const remainingMs = Math.min(blockMs, (timeout - elapsed) * 1000);

      // Blocking check for new messages
      const response = await this.redis.xRead(
        [{ key: streamName, id: '$' }],
        { COUNT: 1, BLOCK: remainingMs }
      );
      
      console.log('Blocking response:', JSON.stringify(response, null, 2));

      for (const k1 in response) {
        console.log('k1:', k1);
        const r1 = response[k1];
        console.log('r1:', JSON.stringify(r1, null, 2));
        for (const msg1 of r1.messages) {
          console.log('message:', JSON.stringify(msg1, null, 2));
          if (msg1.message.job_id === jobId) {
            console.log('Job ID match');
            if ('result' in msg1.message) {
              return msg1.message.result;
            } else if ('error' in msg1.message) {
              throw new JobError(msg1.message.error);
            }
          } else {
            console.log(`Job ID mismatch (got ${msg1.message.job_id} but want ${jobId})`);
          }
        }
      }
    }
  }

  getRequestStream() {
    return `${this.namespace}:requests`;
  }

  getResponseStream() {
    return `${this.namespace}:responses`;
  }

  getErrorStream() {
    return `${this.namespace}:errors`;
  }

  async cleanupStreams() {
    await this.connect();
    const streams = [
      this.getRequestStream(),
      this.getResponseStream(),
      this.getErrorStream()
    ];
    
    for (const stream of streams) {
      await this.redis.xTrim(stream, 'MAXLEN', 0);
    }
  }
}
