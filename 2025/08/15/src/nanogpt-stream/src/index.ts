#!/usr/bin/env node
import path from 'path';
import os from 'os';
import { RedisStreamsServer } from '@modelcontextprotocol/redis-streams';
import { CallToolRequestSchema, McpError, ErrorCode } from '@modelcontextprotocol/sdk/types.js';

class NanoGPTStreamServer extends RedisStreamsServer {
  constructor() {
    super({
      name: 'nanogpt-stream',
      version: '0.1.0',
      streams: {
        requestStream: 'nanogpt:requests',
        responseStream: 'nanogpt:responses',
        timeoutKey: 'nanogpt:timeout'
      },
      logging: {
        directory: path.join(os.homedir(), 'Dropbox/2/src/modelcontextprotocol/nanogpt-stream/log')
      }
    });
  }

  protected getTools() {
    return [
      {
        name: 'list_models',
        description: 'Get a list of all available models from NanoGPT API',
        inputSchema: {
          type: 'object',
          properties: {},
          required: []
        }
      },
      {
        name: 'chat_completion',
        description: 'Generate chat completions using NanoGPT API',
        inputSchema: {
          type: 'object',
          properties: {
            model: {
              type: 'string',
              description: 'Model identifier. Defaults to envy secret get nanogpt default_model or anthropic/claude-3.5-sonnet if not specified. Other options include openai/gpt-4, anthropic/claude-3-opus, etc.'
            },
            log: {
              type: 'boolean',
              description: 'Optional. Determines whether to log the request and response. Defaults to false.',
              default: false
            },
            messages: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  role: {
                    type: 'string',
                    enum: ['system', 'user', 'assistant'],
                    description: 'Role of the message sender'
                  },
                  content: {
                    oneOf: [
                      {
                        type: 'string',
                        description: 'Text content of the message'
                      },
                      {
                        type: 'array',
                        items: {
                          type: 'object',
                          properties: {
                            type: {
                              type: 'string',
                              enum: ['text', 'image_url'],
                              description: 'Type of content'
                            },
                            text: {
                              type: 'string',
                              description: 'Text content when type is text'
                            },
                            image_url: {
                              type: 'object',
                              properties: {
                                url: {
                                  type: 'string',
                                  description: 'Image URL (http/https), data URI, or local file path. Local files will be automatically converted to base64 data URIs.'
                                }
                              },
                              description: 'Image URL object when type is image_url'
                            }
                          },
                          required: ['type'],
                          allOf: [
                            {
                              if: {
                                properties: {
                                  type: {
                                    const: 'text'
                                  }
                                }
                              },
                              then: {
                                required: ['text']
                              }
                            },
                            {
                              if: {
                                properties: {
                                  type: {
                                    const: 'image_url'
                                  }
                                }
                              },
                              then: {
                                required: ['image_url']
                              }
                            }
                          ]
                        },
                        description: 'Array of content items for multimodal messages'
                      }
                    ],
                    description: 'Content of the message - either text or array of content items'
                  }
                },
                required: ['role', 'content']
              },
              description: 'Array of messages in the conversation'
            }
          },
          required: ['messages']
        }
      }
    ];
  }
}

const server = new NanoGPTStreamServer();
server.run().catch(console.error);
