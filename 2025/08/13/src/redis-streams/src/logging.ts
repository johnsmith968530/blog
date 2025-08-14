import fs from 'fs';
import path from 'path';
import { mkdir } from 'fs/promises';

export interface LogConfig {
  directory: string;
  filename?: string;
}

export class Logger {
  private logPath: string;

  constructor(config: LogConfig) {
    this.logPath = path.join(
      config.directory,
      config.filename ?? 'api.log'
    );
  }

  async initialize(): Promise<void> {
    // Ensure log directory exists
    await mkdir(path.dirname(this.logPath), { recursive: true });
  }

  log(data: any): void {
    const timestamp = new Date().toISOString();
    const logEntry = `${timestamp}\n${JSON.stringify(data, null, 2)}\n\n`;
    fs.appendFileSync(this.logPath, logEntry);
  }

  logRequest(command: string, args: any): void {
    this.log({
      type: 'request',
      command,
      args
    });
  }

  logResponse(data: any): void {
    this.log({
      type: 'response',
      data
    });
  }

  logError(error: Error | string): void {
    this.log({
      type: 'error',
      message: error instanceof Error ? error.message : error,
      stack: error instanceof Error ? error.stack : undefined
    });
  }
}
