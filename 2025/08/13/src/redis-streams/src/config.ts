import path from 'path';
import os from 'os';
import { readFile } from 'fs/promises';

export interface RedisConfig {
  host: string;
  port: number;
  password: string;
}

export async function getRedisConfig(): Promise<RedisConfig> {
  const secretsPath = path.join(os.homedir(), '.secrets', 'secrets.json');
  const secretsContent = await readFile(secretsPath, 'utf-8');
  const secrets = JSON.parse(secretsContent);
  
  const redis = secrets.redis;
  if (!redis?.host || !redis?.port) {
    throw new Error('Redis configuration not found in secrets for some reason');
  }
  
  return {
    host: redis.host,
    port: redis.port,
    password: redis.password
  };
}
