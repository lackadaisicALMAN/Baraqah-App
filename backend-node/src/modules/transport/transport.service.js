'use strict';

const sessionModel = require('../../models/pg/session.model');
const { getRedis, RedisKeys, RedisTTL } = require('../../config/redis');

async function updateRidePreference(sessionId, userId, transportMode) {
  const session = await sessionModel.findById(sessionId);
  if (!session) {
    const err = new Error('Session not found');
    err.statusCode = 404;
    throw err;
  }

  const isMember = await sessionModel.isAttendee(sessionId, userId);
  if (!isMember) {
    const err = new Error('Not a session attendee');
    err.statusCode = 403;
    throw err;
  }

  if (transportMode === 'RIDE_TOGETHER' && session.has_ride_available) {
    const redis = getRedis();
    const seatsKey = RedisKeys.sessionRideSeats(sessionId);
    const seats = parseInt((await redis.get(seatsKey)) || '0', 10);

    const currentAttendee = await require('../../config/database').query(
      `SELECT transport_mode FROM session_attendees WHERE session_id = $1 AND user_id = $2`,
      [sessionId, userId]
    );
    const wasRideTogether = currentAttendee.rows[0]?.transport_mode === 'RIDE_TOGETHER';

    if (!wasRideTogether && seats <= 0) {
      const err = new Error('No ride seats available');
      err.statusCode = 400;
      throw err;
    }

    if (!wasRideTogether) {
      await redis.decr(seatsKey);
    }
  } else if (transportMode === 'MEET_THERE') {
    const redis = getRedis();
    const currentAttendee = await require('../../config/database').query(
      `SELECT transport_mode FROM session_attendees WHERE session_id = $1 AND user_id = $2`,
      [sessionId, userId]
    );
    if (currentAttendee.rows[0]?.transport_mode === 'RIDE_TOGETHER') {
      await redis.incr(RedisKeys.sessionRideSeats(sessionId));
    }
  }

  await sessionModel.updateTransport(sessionId, userId, transportMode);
  return { sessionId, userId, transportMode };
}

async function configureRide(sessionId, hostUserId, data) {
  const session = await sessionModel.findById(sessionId);
  if (!session || session.host_user_id !== hostUserId) {
    const err = new Error('Unauthorized or session not found');
    err.statusCode = 403;
    throw err;
  }

  await sessionModel.updateRideAvailability(
    sessionId,
    data.has_ride_available,
    data.available_ride_seats,
    data.vehicle_info
  );

  const redis = getRedis();
  if (data.has_ride_available) {
    await redis.set(
      RedisKeys.sessionRideSeats(sessionId),
      String(data.available_ride_seats),
      'EX',
      RedisTTL.SESSION
    );
  }

  return sessionModel.findById(sessionId);
}

module.exports = { updateRidePreference, configureRide };
