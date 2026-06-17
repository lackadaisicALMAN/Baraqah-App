'use strict';

const Redis = require('ioredis');
const logger = require('../utils/logger');

const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379/0';

/** @type {Redis} */
let redisClient = null;

/** @type {Redis} */
let redisPubClient = null;

/** @type {Redis} */
let redisSubClient = null;

/**
 * Redis key namespace helpers per architecture spec.
 */
const RedisKeys = {
  // Auth
  accessToken: (userId, jti) => `baraqah:auth:access_token:${userId}:${jti}`,
  otp: (phone) => `baraqah:auth:otp:${phone}`,
  otpAttempts: (phone) => `baraqah:auth:otp_attempts:${phone}`,
  authRate: (ip) => `baraqah:auth:rate:${ip}`,

  // Sessions
  sessionState: (sessionId) => `baraqah:session:state:${sessionId}`,
  sessionAttendees: (sessionId) => `baraqah:session:attendees:${sessionId}`,
  sessionPendingRequests: (sessionId) => `baraqah:session:pending_requests:${sessionId}`,
  sessionRideSeats: (sessionId) => `baraqah:session:ride_seats:${sessionId}`,
  sessionsActiveGeo: 'baraqah:sessions:active:geo',

  // Check-in
  checkinQr: (qrToken) => `baraqah:checkin:qr:${qrToken}`,
  checkinScanned: (sessionId) => `baraqah:checkin:scanned:${sessionId}`,
  checkinGeoLock: (sessionId) => `baraqah:checkin:geo_lock:${sessionId}`,

  // User
  userLocation: (userId) => `baraqah:user:location:${userId}`,
  userOnline: (userId) => `baraqah:user:online:${userId}`,
  userSocket: (userId) => `baraqah:user:socket:${userId}`,

  // Notifications
  notificationsUnread: (userId) => `baraqah:notifications:unread:${userId}`,
  notificationsPushQueue: 'baraqah:notifications:push_queue',
  notificationsFailed: (userId) => `baraqah:notifications:failed:${userId}`,

  // Matching & Scoring
  matchResults: (userId, geohash) => `baraqah:match:results:${userId}:${geohash}`,
  scoreCache: (userId) => `baraqah:score:cache:${userId}`,
  scoreLeaderboard: 'baraqah:score:leaderboard',
  scoreLeaderboardCity: (city) => `baraqah:score:leaderboard:city:${city}`,

  // Pub/Sub channels
  pubsubSession: (sessionId) => `baraqah:pubsub:session:${sessionId}`,
  pubsubUser: (userId) => `baraqah:pubsub:user:${userId}`,
  pubsubCheckin: (sessionId) => `baraqah:pubsub:checkin:${sessionId}`,
  pubsubSystem: 'baraqah:pubsub:system',
};

const RedisTTL = {
  ACCESS_TOKEN: 15 * 60,
  OTP: 5 * 60,
  OTP_ATTEMPTS: 15 * 60,
  AUTH_RATE: 60,
  SESSION: 4 * 60 * 60,
  CHECKIN_QR: 90 * 60,
  CHECKIN_SCANNED: 2 * 60 * 60,
  USER_LOCATION: 10 * 60,
  USER_ONLINE: 30,
  USER_SOCKET: 30 * 60,
  NOTIFICATIONS_UNREAD: 7 * 24 * 60 * 60,
  NOTIFICATIONS_FAILED: 24 * 60 * 60,
  MATCH_RESULTS: 5 * 60,
  SCORE_CACHE: 15 * 60,
};

function createRedisClient(name = 'main') {
  const client = new Redis(REDIS_URL, {
    maxRetriesPerRequest: 3,
    lazyConnect: true,
    connectionName: `baraqah-node-${name}`,
  });

  client.on('error', (err) => {
    logger.error(`Redis ${name} error`, { error: err.message });
  });

  return client;
}

async function connectRedis() {
  if (redisClient) return redisClient;

  redisClient = createRedisClient('main');
  redisPubClient = createRedisClient('pub');
  redisSubClient = createRedisClient('sub');

  await Promise.all([
    redisClient.connect(),
    redisPubClient.connect(),
    redisSubClient.connect(),
  ]);

  logger.info('Redis connected');
  return redisClient;
}

function getRedis() {
  if (!redisClient) {
    throw new Error('Redis not connected. Call connectRedis() first.');
  }
  return redisClient;
}

function getRedisPubSub() {
  return { pub: redisPubClient, sub: redisSubClient };
}

async function disconnectRedis() {
  const clients = [redisClient, redisPubClient, redisSubClient].filter(Boolean);
  await Promise.all(clients.map((c) => c.quit()));
  redisClient = null;
  redisPubClient = null;
  redisSubClient = null;
  logger.info('Redis disconnected');
}

module.exports = {
  connectRedis,
  disconnectRedis,
  getRedis,
  getRedisPubSub,
  RedisKeys,
  RedisTTL,
};
