'use strict';

require('dotenv').config();

const http = require('http');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const { connectMongo, disconnectMongo } = require('./config/mongo');
const { connectRedis, disconnectRedis } = require('./config/redis');
const { initSocket, getIO } = require('./config/socket');
const { rateLimiter } = require('./middleware/rateLimiter.middleware');
const { errorMiddleware, notFoundMiddleware } = require('./middleware/error.middleware');
const { registerSessionSocketHandlers } = require('./modules/sessions/sessions.socket');
const logger = require('./utils/logger');

const authRoutes = require('./modules/auth/auth.routes');
const usersRoutes = require('./modules/users/users.routes');
const sessionsRoutes = require('./modules/sessions/sessions.routes');
const restaurantsRoutes = require('./modules/restaurants/restaurants.routes');
const transportRoutes = require('./modules/transport/transport.routes');
const checkinRoutes = require('./modules/checkin/checkin.routes');
const reviewsRoutes = require('./modules/reviews/reviews.routes');
const socialRoutes = require('./modules/social/social.routes');

const PORT = parseInt(process.env.NODE_PORT || '3000', 10);

async function bootstrap() {
  await connectMongo();
  await connectRedis();

  const app = express();
  const server = http.createServer(app);

  const corsOrigins = (process.env.CORS_ORIGINS || 'http://localhost:3000').split(',');
  const corsOptions = {
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
    credentials: true,
  };

  app.use(cors(corsOptions));
  app.use((req, res, next) => {
    logger.info(`[HTTP] ${req.method} ${req.url} - Origin: ${req.headers.origin || 'none'} - Auth: ${req.headers.authorization ? 'Present' : 'Missing'}`);
    next();
  });
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true }));
  app.use(rateLimiter());

  app.get('/health', (_req, res) => {
    res.json({ status: 'ok', service: 'baraqah-node', timestamp: new Date().toISOString() });
  });

  app.use('/api/auth', authRoutes);
  app.use('/api/users', usersRoutes);
  app.use('/api/sessions', sessionsRoutes);
  app.use('/api/restaurants', restaurantsRoutes);
  app.use('/api/transport', transportRoutes);
  app.use('/api/checkin', checkinRoutes);
  app.use('/api/reviews', reviewsRoutes);
  app.use('/api/social', socialRoutes);

  app.use(notFoundMiddleware);
  app.use(errorMiddleware);

  initSocket(server);
  registerSessionSocketHandlers(getIO());

  server.listen(PORT, () => {
    logger.info(`Baraqah Node server listening on port ${PORT}`);
  });

  const shutdown = async (signal) => {
    logger.info(`${signal} received, shutting down gracefully`);
    server.close(async () => {
      await disconnectMongo();
      await disconnectRedis();
      process.exit(0);
    });
  };

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

bootstrap().catch((err) => {
  logger.error('Failed to start server', { error: err.message, stack: err.stack });
  process.exit(1);
});
