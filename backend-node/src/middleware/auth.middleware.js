'use strict';

const jwt = require('jsonwebtoken');
const { getRedis, RedisKeys, RedisTTL } = require('../config/redis');
const { error: errorResponse } = require('../utils/response.utils');

/**
 * JWT authentication middleware.
 * Verifies access token and checks Redis allowlist for revocation.
 */
async function authMiddleware(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return errorResponse(res, 'Authentication required', 401);
    }

    const token = authHeader.slice(7);
    const payload = jwt.verify(token, process.env.JWT_ACCESS_SECRET);

    const redis = getRedis();
    const allowlistKey = RedisKeys.accessToken(payload.sub, payload.jti);
    const isValid = await redis.get(allowlistKey);

    if (!isValid) {
      return errorResponse(res, 'Token revoked or expired', 401);
    }

    req.user = {
      id: payload.sub,
      jti: payload.jti,
      phone: payload.phone,
    };

    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return errorResponse(res, 'Token expired', 401);
    }
    if (err.name === 'JsonWebTokenError') {
      return errorResponse(res, 'Invalid token', 401);
    }
    next(err);
  }
}

/**
 * Optional auth — attaches user if token present, continues otherwise.
 */
async function optionalAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next();
  }
  return authMiddleware(req, res, next);
}

module.exports = { authMiddleware, optionalAuth };
