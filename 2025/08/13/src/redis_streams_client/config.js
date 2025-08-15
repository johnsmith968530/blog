import { secrets } from '../envy/index.js';

export function getRedisConfig() {
  const redis = secrets.redis;
  
  return [redis.host, redis.port, redis.password];
}
