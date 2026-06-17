'use strict';

const logger = require('../utils/logger');
const { error: errorResponse } = require('../utils/response.utils');

/**
 * Global error handler — must be registered last.
 */
function errorMiddleware(err, req, res, _next) {
  logger.error('Request error', {
    message: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
  });

  if (err.name === 'ValidationError') {
    return errorResponse(res, err.message, 422);
  }

  if (err.code === '23505') {
    return errorResponse(res, 'Duplicate entry', 409);
  }

  if (err.code === '23503') {
    return errorResponse(res, 'Referenced resource not found', 404);
  }

  const statusCode = err.statusCode || err.status || 500;
  const message =
    process.env.NODE_ENV === 'production' && statusCode === 500
      ? 'Internal server error'
      : err.message;

  return errorResponse(res, message, statusCode);
}

/**
 * 404 handler for unmatched routes.
 */
function notFoundMiddleware(req, res) {
  return errorResponse(res, `Route not found: ${req.method} ${req.path}`, 404);
}

module.exports = { errorMiddleware, notFoundMiddleware };
