'use strict';

const sessionModel = require('../../models/pg/session.model');
const restaurantModel = require('../../models/pg/restaurant.model');
const GroupChat = require('../../models/mongo/GroupChat.model');
const { getRedis, RedisKeys, RedisTTL } = require('../../config/redis');
const { simpleGeohash } = require('../../utils/geo.utils');
const { emitToSession } = require('../../config/socket');
const { v4: uuidv4 } = require('uuid');

async function createSession(hostUserId, data) {
  const restaurant = await restaurantModel.findById(data.restaurant_id);
  if (!restaurant) {
    const err = new Error('Restaurant not found');
    err.statusCode = 404;
    throw err;
  }

  const meetingLat = data.meeting_lat ?? parseFloat(restaurant.lat);
  const meetingLng = data.meeting_lng ?? parseFloat(restaurant.lng);

  const session = await sessionModel.create({
    hostUserId,
    restaurantId: data.restaurant_id,
    scheduledAt: data.scheduled_at,
    maxAttendees: data.max_attendees,
    foodCategory: data.food_category,
    splitType: data.split_type,
    splitDetails: data.split_details,
    hasRideAvailable: data.has_ride_available,
    availableRideSeats: data.available_ride_seats,
    vehicleInfo: data.vehicle_info,
    meetingLat,
    meetingLng,
    meetingNote: data.meeting_note,
    description: data.description,
    hostTransportMode: data.host_transport_mode,
  });

  await syncSessionToRedis(session);
  await GroupChat.create({
    sessionId: session.id,
    participant_ids: [hostUserId],
    messages: [{
      type: 'SYSTEM',
      content: 'Group chat created. Welcome to your FoodPool session!',
      senderId: 'system',
      sentAt: new Date(),
    }],
  });

  return enrichSession(session);
}

async function syncSessionToRedis(session) {
  const redis = getRedis();

  await redis.hset(RedisKeys.sessionState(session.id), {
    status: session.status,
    current_attendees: String(session.current_attendees),
    checkin_opens_at: session.checkin_opens_at || '',
    qr_token: session.qr_token || '',
  });
  await redis.expire(RedisKeys.sessionState(session.id), RedisTTL.SESSION);

  await redis.sadd(RedisKeys.sessionAttendees(session.id), session.host_user_id);
  await redis.expire(RedisKeys.sessionAttendees(session.id), RedisTTL.SESSION);

  if (session.has_ride_available) {
    await redis.set(
      RedisKeys.sessionRideSeats(session.id),
      String(session.available_ride_seats || 0),
      'EX',
      RedisTTL.SESSION
    );
  }

  if (session.meeting_lat != null) {
    await redis.geoadd(
      RedisKeys.sessionsActiveGeo,
      session.meeting_lng,
      session.meeting_lat,
      session.id
    );
  }
}

async function enrichSession(session) {
  const full = await sessionModel.findById(session.id);
  return full;
}

async function browseSessions(lat, lng, radiusKm, limit) {
  const redis = getRedis();
  const geoResults = await redis.georadius(
    RedisKeys.sessionsActiveGeo,
    lng,
    lat,
    radiusKm,
    'km',
    'WITHDIST',
    'COUNT',
    limit
  );

  if (geoResults.length > 0) {
    const sessions = await Promise.all(
      geoResults.map(async ([sessionId, distance]) => {
        const session = await sessionModel.findById(sessionId);
        if (session) session.distance_km = parseFloat(distance);
        return session;
      })
    );
    return sessions.filter(Boolean);
  }

  return sessionModel.findOpenNearby(lat, lng, radiusKm, limit);
}

async function getSession(sessionId, userId) {
  const session = await sessionModel.findById(sessionId);
  if (!session) {
    const err = new Error('Session not found');
    err.statusCode = 404;
    throw err;
  }

  const [attendees, pendingRequests, messages] = await Promise.all([
    sessionModel.getAttendees(sessionId),
    session.host_user_id === userId ? sessionModel.getPendingRequests(sessionId) : [],
    GroupChat.getMessages(sessionId, 30),
  ]);

  const redis = getRedis();
  const state = await redis.hgetall(RedisKeys.sessionState(sessionId));

  return { session, attendees, pendingRequests, messages, realtimeState: state };
}

async function submitJoinRequest(sessionId, userId, data) {
  const session = await sessionModel.findById(sessionId);
  if (!session) {
    const err = new Error('Session not found');
    err.statusCode = 404;
    throw err;
  }
  if (session.status !== 'OPEN') {
    const err = new Error('Session is not accepting join requests');
    err.statusCode = 400;
    throw err;
  }
  if (session.host_user_id === userId) {
    const err = new Error('Host cannot join own session');
    err.statusCode = 400;
    throw err;
  }

  const existing = await sessionModel.isAttendee(sessionId, userId);
  if (existing) {
    const err = new Error('Already an attendee');
    err.statusCode = 409;
    throw err;
  }

  if (session.current_attendees >= session.max_attendees) {
    const err = new Error('Session is full');
    err.statusCode = 400;
    throw err;
  }

  // 1. Create join request automatically as ACCEPTED
  const request = await sessionModel.createJoinRequest({
    sessionId,
    requesterId: userId,
    transportMode: data.transport_mode || 'MEET_THERE',
    message: data.message,
  });
  await sessionModel.updateJoinRequestStatus(request.id, 'ACCEPTED');

  // 2. Add attendee in SQL
  const attendee = await sessionModel.addAttendee({
    sessionId,
    userId,
    joinRequestId: request.id,
    transportMode: data.transport_mode || 'MEET_THERE',
  });

  // 3. Update Redis cache
  const redis = getRedis();
  await redis.sadd(RedisKeys.sessionAttendees(sessionId), userId);
  await redis.zrem(RedisKeys.sessionPendingRequests(sessionId), userId);

  // 4. Update session status to LOCKED if full
  const updatedSession = await sessionModel.findById(sessionId);
  if (updatedSession && updatedSession.current_attendees >= updatedSession.max_attendees) {
    await sessionModel.updateStatus(sessionId, 'LOCKED');
    await redis.hset(RedisKeys.sessionState(sessionId), 'status', 'LOCKED');
  }

  // 5. Emit socket events & add system message in MongoDB chat
  await GroupChat.addMessage(sessionId, {
    senderId: 'system',
    type: 'SYSTEM',
    content: `A new member joined the session.`,
    participantIds: [userId],
  });

  emitToSession(sessionId, 'REQUEST_ACCEPTED', { attendee });

  return request;
}

async function reviewJoinRequest(sessionId, requestId, hostUserId, action) {
  const session = await sessionModel.findById(sessionId);
  if (!session || session.host_user_id !== hostUserId) {
    const err = new Error('Unauthorized or session not found');
    err.statusCode = 403;
    throw err;
  }

  const joinRequest = await sessionModel.findJoinRequest(requestId);
  if (!joinRequest || joinRequest.session_id !== sessionId) {
    const err = new Error('Join request not found');
    err.statusCode = 404;
    throw err;
  }
  if (joinRequest.status !== 'PENDING') {
    const err = new Error('Request already processed');
    err.statusCode = 400;
    throw err;
  }

  if (action === 'REJECT') {
    const updated = await sessionModel.updateJoinRequestStatus(requestId, 'REJECTED');
    emitToSession(sessionId, 'REQUEST_REJECTED', { requestId });
    return updated;
  }

  if (session.current_attendees >= session.max_attendees) {
    const err = new Error('Session is full');
    err.statusCode = 400;
    throw err;
  }

  if (
    joinRequest.transport_mode === 'RIDE_TOGETHER' &&
    session.has_ride_available
  ) {
    const redis = getRedis();
    const seats = parseInt(
      (await redis.get(RedisKeys.sessionRideSeats(sessionId))) ||
        String(session.available_ride_seats),
      10
    );
    if (seats <= 0) {
      const err = new Error('No ride seats available');
      err.statusCode = 400;
      throw err;
    }
    await redis.decr(RedisKeys.sessionRideSeats(sessionId));
  }

  await sessionModel.updateJoinRequestStatus(requestId, 'ACCEPTED');
  const attendee = await sessionModel.addAttendee({
    sessionId,
    userId: joinRequest.requester_id,
    joinRequestId: requestId,
    transportMode: joinRequest.transport_mode,
  });

  const redis = getRedis();
  await redis.sadd(RedisKeys.sessionAttendees(sessionId), joinRequest.requester_id);
  await redis.zrem(RedisKeys.sessionPendingRequests(sessionId), joinRequest.requester_id);

  await GroupChat.addMessage(sessionId, {
    senderId: 'system',
    type: 'SYSTEM',
    content: `A new member joined the session.`,
    participantIds: [joinRequest.requester_id],
  });

  emitToSession(sessionId, 'REQUEST_ACCEPTED', { attendee });
  return attendee;
}

async function sendChatMessage(sessionId, userId, data) {
  const isMember = await sessionModel.isAttendee(sessionId, userId);
  if (!isMember) {
    const err = new Error('Not a session attendee');
    err.statusCode = 403;
    throw err;
  }

  const { message } = await GroupChat.addMessage(sessionId, {
    senderId: userId,
    type: data.type,
    content: data.content,
    metadata: data.metadata,
    participantIds: [userId],
  });

  emitToSession(sessionId, 'CHAT_MESSAGE', { message });
  return message;
}

async function getUserSessions(userId) {
  return sessionModel.getUserSessions(userId);
}

module.exports = {
  createSession,
  browseSessions,
  getSession,
  submitJoinRequest,
  reviewJoinRequest,
  sendChatMessage,
  getUserSessions,
  syncSessionToRedis,
};
