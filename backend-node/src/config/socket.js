'use strict';

const { Server } = require('socket.io');
const { createAdapter } = require('@socket.io/redis-adapter');
const jwt = require('jsonwebtoken');
const { getRedisPubSub, RedisKeys, RedisTTL } = require('./redis');
const logger = require('../utils/logger');

/** @type {Server|null} */
let io = null;

/**
 * Initialize Socket.IO server attached to HTTP server.
 * @param {import('http').Server} httpServer
 * @returns {Server}
 */
function initSocket(httpServer) {
  const corsOrigins = (process.env.CORS_ORIGINS || 'http://localhost:3000').split(',');

  io = new Server(httpServer, {
    cors: {
      origin: function (origin, callback) {
        if (!origin) return callback(null, true);
        if (process.env.NODE_ENV === 'development' && (origin.startsWith('http://localhost:') || origin.startsWith('http://127.0.0.1:') || origin.startsWith('http://10.0.2.2:'))) {
          return callback(null, true);
        }
        if (corsOrigins.indexOf(origin) !== -1 || corsOrigins.includes('*')) {
          return callback(null, true);
        }
        return callback(new Error('Not allowed by CORS'), false);
      },
      methods: ['GET', 'POST'],
      credentials: true,
    },
    path: '/socket.io',
    transports: ['websocket', 'polling'],
  });

  const { pub, sub } = getRedisPubSub();
  io.adapter(createAdapter(pub, sub));

  // Auth middleware for socket connections
  io.use(async (socket, next) => {
    try {
      const token =
        socket.handshake.auth?.token ||
        socket.handshake.headers?.authorization?.replace('Bearer ', '');

      if (!token) {
        return next(new Error('Authentication required'));
      }

      const payload = jwt.verify(token, process.env.JWT_ACCESS_SECRET);
      socket.userId = payload.sub;
      socket.jti = payload.jti;
      next();
    } catch (err) {
      next(new Error('Invalid token'));
    }
  });

  io.on('connection', async (socket) => {
    const userId = socket.userId;
    const redis = require('./redis').getRedis();

    await redis.set(RedisKeys.userSocket(userId), socket.id, 'EX', RedisTTL.USER_SOCKET);
    await redis.set(RedisKeys.userOnline(userId), socket.id, 'EX', RedisTTL.USER_ONLINE);

    logger.info('Socket connected', { userId, socketId: socket.id });

    socket.on('heartbeat', async () => {
      await redis.set(RedisKeys.userOnline(userId), socket.id, 'EX', RedisTTL.USER_ONLINE);
      socket.emit('heartbeat_ack', { ts: Date.now() });
    });

    socket.on('join_session_room', async (sessionId) => {
      socket.join(`session:${sessionId}`);
      socket.emit('joined_session_room', { sessionId });
    });

    socket.on('leave_session_room', (sessionId) => {
      socket.leave(`session:${sessionId}`);
    });

    socket.on('disconnect', async () => {
      await redis.del(RedisKeys.userOnline(userId));
      const storedSocketId = await redis.get(RedisKeys.userSocket(userId));
      if (storedSocketId === socket.id) {
        await redis.del(RedisKeys.userSocket(userId));
      }
      logger.info('Socket disconnected', { userId });
    });
  });

  return io;
}

function getIO() {
  if (!io) {
    throw new Error('Socket.IO not initialized');
  }
  return io;
}

/**
 * Emit event to all sockets in a session room.
 */
function emitToSession(sessionId, event, data) {
  if (io) {
    io.to(`session:${sessionId}`).emit(event, data);
  }
}

/**
 * Emit event to a specific user's connected socket.
 */
async function emitToUser(userId, event, data) {
  const redis = require('./redis').getRedis();
  const socketId = await redis.get(RedisKeys.userSocket(userId));
  if (io && socketId) {
    io.to(socketId).emit(event, data);
  }
}

module.exports = {
  initSocket,
  getIO,
  emitToSession,
  emitToUser,
};
