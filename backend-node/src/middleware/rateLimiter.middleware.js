'use strict';

const { getRedis, RedisKeys, RedisTTL } = require('../config/redis');
const { error: errorResponse } = require('../utils/response.utils');

const WINDOW_MS = parseInt(process.env.RATE_LIMIT_WINDOW_MS || '60000', 10);
const MAX_REQUESTS = parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100', 10);

/**
 * Redis-backed sliding window rate limiter per IP address.
 */
function rateLimiter(options = {}) {
  const windowMs = options.windowMs || WINDOW_MS;
  const maxRequests = options.maxRequests || MAX_REQUESTS;
  const keyPrefix = options.keyPrefix || 'baraqah:auth:rate';

  return async (req, res, next) => {
    try {
      const ip =
        req.headers['x-forwarded-for']?.split(',')[0]?.trim() ||
        req.socket.remoteAddress ||
        'unknown';

      const redis = getRedis();
      const key = `${keyPrefix}:${ip}`;
      const ttlSeconds = Math.ceil(windowMs / 1000);

      const current = await redis.incr(key);
      if (current === 1) {
        await redis.expire(key, ttlSeconds);
      }

      res.setHeader('X-RateLimit-Limit', maxRequests);
      res.setHeader('X-RateLimit-Remaining', Math.max(0, maxRequests - current));

      if (current > maxRequests) {
        const ttl = await redis.ttl(key);
        res.setHeader('Retry-After', ttl);
        return errorResponse(res, 'Too many requests', 429);
      }

      next();
    } catch (err) {
      next(err);
    }
  };
}

/**
 * Stricter rate limit for auth endpoints.
 */
const authRateLimiter = rateLimiter({
  windowMs: 60000,
  maxRequests: 20,
  keyPrefix: 'baraqah:auth:rate',
});

module.exports = { rateLimiter, authRateLimiter };
