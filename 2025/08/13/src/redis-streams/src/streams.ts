import { createClient } from 'redis';

export interface StreamsConfig {
  requestStream: string;
  responseStream: string;
  timeoutKey?: string;
  defaultTimeout?: number;
}

export class StreamsManager {
  private client: ReturnType<typeof createClient>;
  private config: StreamsConfig;

  constructor(client: ReturnType<typeof createClient>, config: StreamsConfig) {
    this.client = client;
    this.config = {
      timeoutKey: 'timeout',
      defaultTimeout: 30,
      ...config
    };
  }

  async enqueueJob(command: string, args: Record<string, any> = {}): Promise<string> {
    // Prepare fields for Redis Stream with command and args as JSON
    const fields: Record<string, string> = {
      command,
      args: JSON.stringify(args)
    };

    // Add job to the stream
    const jobId = await this.client.xAdd(
      this.config.requestStream,
      '*', // Let Redis generate the ID
      fields
    );

    return jobId;
  }

  async getJobResult(jobId: string): Promise<any> {
    // Get timeout from Redis or use default
    const timeoutStr = this.config.timeoutKey ? 
      await this.client.get(this.config.timeoutKey) : 
      null;
    const timeout = timeoutStr ? parseInt(timeoutStr, 10) : (this.config.defaultTimeout ?? 30);

    const startTime = Date.now();
    const blockMs = 5000; // 5 second blocks like in worker.rs

    while (true) {
      // Check if we've exceeded the timeout
      if (Date.now() - startTime >= timeout * 1000) {
        throw new Error('Timeout waiting for job result');
      }

      // Check existing messages
      const messages = await this.client.xRevRange(
        this.config.responseStream,
        '+',
        '-'
      );

      for (const message of messages) {
        if (message.message.job_id === jobId) {
          if (message.message.result) {
            return message.message.result;
          } else if (message.message.error) {
            throw new Error(message.message.error);
          }
        }
      }

      // Calculate remaining timeout
      const elapsed = Date.now() - startTime;
      const remainingMs = Math.max(0, (timeout * 1000) - elapsed);
      if (remainingMs === 0) {
        throw new Error('Timeout waiting for job result');
      }

      // Block for the shorter of blockMs or remaining timeout
      const blockTimeout = Math.min(blockMs, remainingMs);

      // Wait for new messages
      const response = await this.client.xRead(
        [
          {
            key: this.config.responseStream,
            id: '$' // Only get new messages
          }
        ],
        {
          COUNT: 1,
          BLOCK: blockTimeout
        }
      );

      if (response) {
        for (const stream of response) {
          for (const message of stream.messages) {
            if (message.message.job_id === jobId) {
              if (message.message.result) {
                return message.message.result;
              } else if (message.message.error) {
                throw new Error(message.message.error);
              }
            }
          }
        }
      }
      // If no response or no matching message, continue loop
    }
  }
}
