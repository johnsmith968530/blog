import { execSync } from 'child_process';

export interface RedisConfig {
  host: string;
  port: number;
  password: string;
}

function envySecretGet(...path: string[]): string {
  const cmd = ['envy', 'secret', 'get', ...path].join(' ');
  
  try {
    const result = execSync(cmd, { encoding: 'utf-8' });
    const value = result.trim();
    
    return value;
  } catch (error: any) {
    if (error.code === 'ENOENT') {
      throw new Error('envy command not found. Make sure it\'s installed and in your PATH.');
    }
    throw new Error(`envy command failed for ${path.join('.')}: ${error.message}`);
  }
}

export function getRedisConfig(): RedisConfig {
  const host = envySecretGet('redis', 'host');
  const portStr = envySecretGet('redis', 'port');
  const password = envySecretGet('redis', 'password');
  
  const port = parseInt(portStr, 10);
  if (isNaN(port)) {
    throw new Error(`Failed to parse Redis port as number: ${portStr}`);
  }
  
  return {
    host,
    port,
    password
  };
}
