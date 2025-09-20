import { createClient } from 'redis';
import type { RedisConfig } from './config.js';

export async function createRedisClient(config: RedisConfig) {
  const client = createClient({
    socket: {
      host: config.host,
      port: config.port
    },
    password: config.password
  });

  // Error handling
  client.on('error', (error) => console.error('[Redis Error]', error));

  await client.connect();
  console.error('Connected to Redis');

  return client;
}

export async function closeRedisClient(client: ReturnType<typeof createClient>) {
  if (client) {
    await client.quit();
    console.error('Disconnected from Redis');
  }
}
