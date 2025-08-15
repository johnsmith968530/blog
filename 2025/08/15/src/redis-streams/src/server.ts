import { Server as McpServer } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ErrorCode,
  ListToolsRequestSchema,
  McpError,
} from '@modelcontextprotocol/sdk/types.js';
import { createClient } from 'redis';

import { getRedisConfig } from './config.js';
import { createRedisClient, closeRedisClient } from './client.js';
import { StreamsManager, type StreamsConfig } from './streams.js';
import { Logger, type LogConfig } from './logging.js';

export interface ServerConfig {
  name: string;
  version: string;
  streams: StreamsConfig;
  logging?: LogConfig;
}

export abstract class RedisStreamsServer {
  private config: ServerConfig;
  protected server: McpServer;
  protected redisClient: ReturnType<typeof createClient>;
  protected streamsManager: StreamsManager;
  protected logger?: Logger;

  constructor(config: ServerConfig) {
    this.config = config;
    this.server = new McpServer(
      {
        name: config.name,
        version: config.version,
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    // Redis client will be initialized in run()
    this.redisClient = null as any;

    // Streams manager will be initialized in run()
    this.streamsManager = null as any;

    // Initialize logger if config provided
    if (config.logging) {
      this.logger = new Logger(config.logging);
    }

    this.setupToolHandlers();
    
    // Error handling
    this.server.onerror = (error: unknown) => {
      console.error('[MCP Error]', error);
      if (error instanceof Error || typeof error === 'string') {
        this.logger?.logError(error);
      }
    };

    process.on('SIGINT', async () => {
      await this.close();
      process.exit(0);
    });
  }

  protected abstract getTools(): Array<{
    name: string;
    description: string;
    inputSchema: object;
  }>;

  private setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: this.getTools(),
    }));

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const validTools = this.getTools().map(tool => tool.name);

      if (!validTools.includes(request.params.name)) {
        throw new McpError(
          ErrorCode.MethodNotFound,
          `Unknown tool: ${request.params.name}`
        );
      }

      try {
        this.logger?.logRequest(request.params.name, request.params.arguments);

        const jobId = await this.streamsManager.enqueueJob(
          request.params.name,
          request.params.arguments
        );
        const result = await this.streamsManager.getJobResult(jobId);

        this.logger?.logResponse(result);

        return {
          content: [
            {
              type: 'text',
              text: result,
            },
          ],
        };
      } catch (error) {
        if (error instanceof Error || typeof error === 'string') {
          this.logger?.logError(error);
        }
        return {
          content: [
            {
              type: 'text',
              text: `Error: ${error instanceof Error ? error.message : String(error)}`,
            },
          ],
          isError: true,
        };
      }
    });
  }

  async run() {
    // Initialize logger if configured
    if (this.logger) {
      await this.logger.initialize();
    }

    // Get Redis configuration from secrets
    const redisConfig = await getRedisConfig();
    
    // Initialize Redis client
    this.redisClient = await createRedisClient(redisConfig);

    // Initialize streams manager
    this.streamsManager = new StreamsManager(this.redisClient, {
      requestStream: this.config.streams.requestStream,
      responseStream: this.config.streams.responseStream,
      timeoutKey: this.config.streams.timeoutKey,
      defaultTimeout: this.config.streams.defaultTimeout
    });

    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error(`${this.config.name} MCP server running on stdio`);
  }

  async close() {
    if (this.redisClient) {
      await closeRedisClient(this.redisClient);
    }
    await this.server.close();
  }
}
