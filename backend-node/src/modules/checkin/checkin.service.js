'use strict';

const { v4: uuidv4 } = require('uuid');
const sessionModel = require('../../models/pg/session.model');
const attendanceModel = require('../../models/pg/attendance.model');
const userModel = require('../../models/pg/user.model');
const { getRedis, RedisKeys, RedisTTL } = require('../../config/redis');
const { generateQrDataUrl, parseQrPayload } = require('../../utils/qr.utils');
const { isWithinRadius } = require('../../utils/geo.utils');
const { emitToSession } = require('../../config/socket');

const DEFAULT_RADIUS = parseInt(process.env.CHECKIN_DEFAULT_RADIUS_METERS || '200', 10);

async function openCheckin(sessionId, hostUserId) {
  const session = await sessionModel.findById(sessionId);
  if (!session || session.host_user_id !== hostUserId) {
    const err = new Error('Unauthorized or session not found');
    err.statusCode = 403;
    throw err;
  }

  const qrToken = uuidv4();
  const now = new Date();
  const closesAt = new Date(now.getTime() + 90 * 60 * 1000);

  await sessionModel.updateQrToken(sessionId, qrToken);
  await sessionModel.setCheckinWindow(sessionId, now, closesAt);

  const redis = getRedis();
  await redis.hset(RedisKeys.checkinQr(qrToken), {
    session_id: sessionId,
    valid_from: now.toISOString(),
    valid_until: closesAt.toISOString(),
    checkin_count: '1',
  });
  await redis.expire(RedisKeys.checkinQr(qrToken), RedisTTL.CHECKIN_QR);

  const lat = parseFloat(session.restaurant_lat || session.meeting_lat || 0.0);
  const lng = parseFloat(session.restaurant_lng || session.meeting_lng || 0.0);
  await redis.set(
    RedisKeys.checkinGeoLock(sessionId),
    `${lat},${lng}:${DEFAULT_RADIUS}`,
    'EX',
    RedisTTL.CHECKIN_QR
  );

  // Automatically record host attendance in SQL database
  await attendanceModel.createLog({
    sessionId,
    attendeeUserId: hostUserId,
    status: 'CONFIRMED',
    lat,
    lng,
    deviceInfo: { is_host: true, note: 'Host marked arrival' }
  });

  // Automatically mark host checked-in in Redis cache
  await redis.sadd(RedisKeys.checkinScanned(sessionId), hostUserId);
  await redis.expire(RedisKeys.checkinScanned(sessionId), RedisTTL.CHECKIN_SCANNED);

  const qrDataUrl = await generateQrDataUrl(qrToken, sessionId);

  emitToSession(sessionId, 'CHECKIN_OPEN', { sessionId, opensAt: now, closesAt });

  return { qrToken, qrDataUrl, opensAt: now, closesAt };
}

async function scanCheckin(userId, payload, lat, lng, deviceInfo) {
  let qrToken, sessionId;

  if (typeof payload === 'string') {
    const parsed = parseQrPayload(payload);
    if (!parsed) {
      const err = new Error('Invalid QR payload');
      err.statusCode = 400;
      throw err;
    }
    qrToken = parsed.qrToken;
    sessionId = parsed.sessionId;
  } else {
    qrToken = payload.qr_token;
    sessionId = payload.session_id;
  }

  const redis = getRedis();
  const qrData = await redis.hgetall(RedisKeys.checkinQr(qrToken));

  if (!qrData.session_id || qrData.session_id !== sessionId) {
    const err = new Error('Invalid or expired QR code');
    err.statusCode = 400;
    throw err;
  }

  const now = new Date();
  if (now > new Date(qrData.valid_until)) {
    const err = new Error('Check-in window has closed');
    err.statusCode = 400;
    throw err;
  }

  const isMember = await sessionModel.isAttendee(sessionId, userId);
  if (!isMember) {
    const err = new Error('Not a session attendee');
    err.statusCode = 403;
    throw err;
  }

  const alreadyScanned = await redis.sismember(
    RedisKeys.checkinScanned(sessionId),
    userId
  );
  if (alreadyScanned) {
    const err = new Error('Already checked in');
    err.statusCode = 409;
    throw err;
  }

  const geoLock = await redis.get(RedisKeys.checkinGeoLock(sessionId));
  if (geoLock && lat != null && lng != null) {
    const [coords, radiusStr] = geoLock.split(':');
    const [centerLat, centerLng] = coords.split(',').map(parseFloat);
    const radius = parseInt(radiusStr, 10);
    if (!isWithinRadius(lat, lng, centerLat, centerLng, radius)) {
      const err = new Error('You must be at the venue to check in');
      err.statusCode = 400;
      throw err;
    }
  }

  const existing = await attendanceModel.findBySessionAndUser(sessionId, userId);
  if (existing) {
    const err = new Error('Already checked in');
    err.statusCode = 409;
    throw err;
  }

  const log = await attendanceModel.createLog({
    sessionId,
    attendeeUserId: userId,
    status: 'CONFIRMED',
    lat,
    lng,
    deviceInfo,
  });

  await redis.sadd(RedisKeys.checkinScanned(sessionId), userId);
  await redis.expire(RedisKeys.checkinScanned(sessionId), RedisTTL.CHECKIN_SCANNED);
  await redis.hincrby(RedisKeys.checkinQr(qrToken), 'checkin_count', 1);

  emitToSession(sessionId, 'ATTENDEE_CHECKED_IN', {
    userId,
    sessionId,
    scannedAt: log.scanned_at,
  });

  return log;
}

async function completeSession(sessionId, hostUserId) {
  const session = await sessionModel.findById(sessionId);
  if (!session || session.host_user_id !== hostUserId) {
    const err = new Error('Unauthorized or session not found');
    err.statusCode = 403;
    throw err;
  }

  // 1. Mark no-shows (creates logs with status = 'NO_SHOW' for users who haven't scanned)
  const noShows = await attendanceModel.markNoShows(sessionId);
  
  // 2. Penalize no-shows by removing 1 star from Baraqah score
  for (const ns of noShows) {
    await applyScoreEvent(ns.attendee_user_id, 'NO_SHOW', sessionId, -1.0);
  }

  await sessionModel.updateStatus(sessionId, 'COMPLETED');

  const redis = getRedis();
  await redis.zrem(RedisKeys.sessionsActiveGeo, sessionId);
  await redis.del(RedisKeys.sessionState(sessionId));

  // 3. Reward only confirmed attendees (+0.2 for host, +0.1 for members)
  const attendees = await sessionModel.getAttendees(sessionId);
  const attendanceLogs = await attendanceModel.getSessionAttendance(sessionId);
  const confirmedUserIds = new Set(
    attendanceLogs
      .filter(log => log.status === 'CONFIRMED')
      .map(log => log.attendee_user_id)
  );

  for (const attendee of attendees) {
    if (confirmedUserIds.has(attendee.user_id)) {
      if (attendee.is_host) {
        await applyScoreEvent(attendee.user_id, 'HOST_COMPLETED', sessionId, 0.2);
      } else {
        await applyScoreEvent(attendee.user_id, 'SESSION_COMPLETED', sessionId, 0.1);
      }
    }
  }

  emitToSession(sessionId, 'SESSION_COMPLETED', { sessionId });
  return { sessionId, status: 'COMPLETED' };
}

async function applyScoreEvent(userId, eventType, sessionId, delta) {
  const user = await userModel.findById(userId);
  if (!user) return;

  const scoreBefore = parseFloat(user.baraqah_score);
  const scoreAfter = Math.min(7.0, Math.max(0, scoreBefore + delta));

  await userModel.updateScore(userId, scoreAfter);
  await userModel.recordScoreEvent({
    userId,
    eventType,
    sessionId,
    delta,
    scoreBefore,
    scoreAfter,
    metadata: {},
  });

  const redis = getRedis();
  await redis.hset(RedisKeys.scoreCache(userId), {
    score: String(scoreAfter),
    last_calculated_at: new Date().toISOString(),
  });
  await redis.expire(RedisKeys.scoreCache(userId), RedisTTL.SCORE_CACHE);
  await redis.zadd(RedisKeys.scoreLeaderboard, scoreAfter, userId);
}

async function getAttendance(sessionId, userId) {
  const isMember = await sessionModel.isAttendee(sessionId, userId);
  if (!isMember) {
    const err = new Error('Not a session attendee');
    err.statusCode = 403;
    throw err;
  }
  return attendanceModel.getSessionAttendance(sessionId);
}

module.exports = {
  openCheckin,
  scanCheckin,
  completeSession,
  getAttendance,
  applyScoreEvent,
};
