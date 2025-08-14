#!/usr/bin/env node
import path from 'path';
import os from 'os';
import { RedisStreamsServer } from '@modelcontextprotocol/redis-streams';

class StardateStreamServer extends RedisStreamsServer {
  constructor() {
    super({
      name: 'stardate-stream',
      version: '0.2.0',
      streams: {
        requestStream: 'stardate:requests',
        responseStream: 'stardate:responses',
        timeoutKey: 'stardate:timeout'
      },
      logging: {
        directory: path.join(os.homedir(), 'Dropbox/2/src/modelcontextprotocol/stardate-stream/log')
      }
    });
  }

  protected getTools() {
    return [
      {
        name: 'to_stardate',
        description: 'Convert a date/time to stardate',
        inputSchema: {
          type: 'object',
          properties: {
            datetime: {
              type: 'string',
              description: 'ISO date/time string or "now"'
            },
            timezone: {
              type: 'string',
              description: 'IANA time zone (e.g. "America/New_York"). Ignored when datetime is "now", required otherwise'
            },
            format: {
              type: 'string',
              enum: ['canonical', 'medium', 'short'],
              description: 'Precision of decimal places (canonical=15, medium=6, short=3)'
            }
          },
          required: ['datetime']
        }
      },
      {
        name: 'from_stardate',
        description: 'Convert a stardate to date/time',
        inputSchema: {
          type: 'object',
          properties: {
            stardate: {
              type: 'number',
              description: 'Stardate to convert'
            },
            timezone: {
              type: 'string',
              description: 'IANA time zone (e.g. "America/New_York")'
            }
          },
          required: ['stardate', 'timezone']
        }
      },
      {
        name: 'stardate_diff',
        description: 'Calculate time difference between two stardates',
        inputSchema: {
          type: 'object',
          properties: {
            stardate1: {
              type: 'number',
              description: 'First stardate'
            },
            stardate2: {
              type: 'number',
              description: 'Second stardate'
            },
            unit: {
              type: 'string',
              enum: ['years', 'months', 'weeks', 'days', 'hours', 'minutes', 'seconds', 'milliseconds'],
              description: 'Unit for the difference'
            }
          },
          required: ['stardate1', 'stardate2', 'unit']
        }
      },
      {
        name: 'stardate_to_unix',
        description: 'Convert a stardate to a UNIX timestamp',
        inputSchema: {
          type: 'object',
          properties: {
            stardate: {
              type: 'number',
              description: 'Stardate to convert'
            }
          },
          required: ['stardate']
        }
      },
      {
        name: 'unix_to_stardate',
        description: 'Convert a UNIX timestamp to a stardate',
        inputSchema: {
          type: 'object',
          properties: {
            timestamp: {
              type: 'string',
              description: 'UNIX timestamp to convert (as string)'
            },
            format: {
              type: 'string',
              enum: ['canonical', 'medium', 'short'],
              description: 'Precision of decimal places (canonical=15, medium=6, short=3)'
            }
          },
          required: ['timestamp']
        }
      }
    ];
  }
}

const server = new StardateStreamServer();
server.run().catch(console.error);
