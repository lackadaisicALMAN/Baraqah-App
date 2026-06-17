'use strict';

const sessionsService = require('./sessions.service');
const { getIO } = require('../../config/socket');
const logger = require('../../utils/logger');

/**
 * Register Socket.IO event handlers for session real-time updates.
 */
function registerSessionSocketHandlers(io) {
  io.on('connection', (socket) => {
    socket.on('session:subscribe', async (sessionId) => {
      socket.join(`session:${sessionId}`);
      socket.emit('session:subscribed', { sessionId });
    });

    socket.on('session:typing', (data) => {
      socket.to(`session:${data.sessionId}`).emit('session:typing', {
        userId: socket.userId,
        sessionId: data.sessionId,
      });
    });
  });
}

/**
 * Publish session event via Redis pub/sub for cross-instance delivery.
 */
async function publishSessionEvent(sessionId, event, data) {
  const { getRedis, RedisKeys } = require('../../config/redis');
  const redis = getRedis();
  const channel = RedisKeys.pubsubSession(sessionId);
  await redis.publish(channel, JSON.stringify({ event, data }));
}

module.exports = {
  registerSessionSocketHandlers,
  publishSessionEvent,
};
