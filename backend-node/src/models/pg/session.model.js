'use strict';

const { query, withTransaction } = require('../../config/database');
const { pointWkt } = require('../../utils/geo.utils');

async function findById(id) {
  const result = await query(
    `SELECT ds.*,
            ST_Y(ds.meeting_location::geometry) AS meeting_lat,
            ST_X(ds.meeting_location::geometry) AS meeting_lng,
            r.name AS restaurant_name, r.address AS restaurant_address,
            r.city AS restaurant_city, r.cuisine_tags,
            ST_Y(r.location::geometry) AS restaurant_lat,
            ST_X(r.location::geometry) AS restaurant_lng,
            u.full_name AS host_name, u.display_name AS host_display_name,
            u.avatar_url AS host_avatar, u.baraqah_score AS host_score
     FROM dining_sessions ds
     JOIN restaurants r ON r.id = ds.restaurant_id
     JOIN users u ON u.id = ds.host_user_id
     WHERE ds.id = $1`,
    [id]
  );
  return result.rows[0] || null;
}

async function create(data) {
  const result = await query(
    `INSERT INTO dining_sessions
       (host_user_id, restaurant_id, scheduled_at, max_attendees, food_category,
        split_type, split_details, has_ride_available, available_ride_seats,
        vehicle_info, meeting_location, meeting_note, description, checkin_opens_at, checkin_closes_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
             ST_GeomFromText($11, 4326), $12, $13, $14, $15)
     RETURNING *`,
    [
      data.hostUserId,
      data.restaurantId,
      data.scheduledAt,
      data.maxAttendees,
      data.foodCategory,
      data.splitType || 'EQUAL',
      JSON.stringify(data.splitDetails || []),
      data.hasRideAvailable || false,
      data.availableRideSeats || 0,
      data.vehicleInfo ? JSON.stringify(data.vehicleInfo) : null,
      data.meetingLng != null ? pointWkt(data.meetingLng, data.meetingLat) : null,
      data.meetingNote || null,
      data.description || null,
      data.checkinOpensAt || null,
      data.checkinClosesAt || null,
    ]
  );
  const session = result.rows[0];

  await query(
    `INSERT INTO session_attendees (session_id, user_id, is_host, transport_mode)
     VALUES ($1, $2, TRUE, $3)`,
    [session.id, data.hostUserId, data.hostTransportMode || 'MEET_THERE']
  );

  return session;
}

async function findOpenNearby(lat, lng, radiusKm = 10, limit = 50) {
  const result = await query(
    `SELECT ds.id, ds.host_user_id, ds.status, ds.scheduled_at, ds.max_attendees,
            ds.current_attendees, ds.food_category, ds.split_type,
            ds.has_ride_available, ds.available_ride_seats, ds.description,
            ST_Y(ds.meeting_location::geometry) AS meeting_lat,
            ST_X(ds.meeting_location::geometry) AS meeting_lng,
            r.name AS restaurant_name, r.city, r.cuisine_tags, r.price_range,
            u.display_name AS host_display_name, u.baraqah_score AS host_score,
            ST_Distance(
              ds.meeting_location::geography,
              ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography
            ) / 1000 AS distance_km
     FROM dining_sessions ds
     JOIN restaurants r ON r.id = ds.restaurant_id
     JOIN users u ON u.id = ds.host_user_id
     WHERE ds.status = 'OPEN'
       AND ds.meeting_location IS NOT NULL
       AND ST_DWithin(
             ds.meeting_location::geography,
             ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography,
             $3 * 1000
           )
     ORDER BY distance_km
     LIMIT $4`,
    [lat, lng, radiusKm, limit]
  );
  return result.rows;
}

async function updateStatus(sessionId, status) {
  const result = await query(
    `UPDATE dining_sessions SET status = $1 WHERE id = $2 RETURNING *`,
    [status, sessionId]
  );
  return result.rows[0] || null;
}

async function updateQrToken(sessionId, qrToken) {
  await query(
    `UPDATE dining_sessions SET qr_token = $1, qr_generated_at = NOW() WHERE id = $2`,
    [qrToken, sessionId]
  );
}

async function setCheckinWindow(sessionId, opensAt, closesAt) {
  await query(
    `UPDATE dining_sessions
     SET checkin_opens_at = $1, checkin_closes_at = $2, status = 'ACTIVE'
     WHERE id = $3`,
    [opensAt, closesAt, sessionId]
  );
}

async function createJoinRequest({ sessionId, requesterId, transportMode, message }) {
  const result = await query(
    `INSERT INTO join_requests (session_id, requester_id, transport_mode, message)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [sessionId, requesterId, transportMode, message || null]
  );
  return result.rows[0];
}

async function findJoinRequest(id) {
  const result = await query(
    `SELECT * FROM join_requests WHERE id = $1`,
    [id]
  );
  return result.rows[0] || null;
}

async function updateJoinRequestStatus(id, status) {
  const result = await query(
    `UPDATE join_requests SET status = $1, reviewed_at = NOW() WHERE id = $2 RETURNING *`,
    [status, id]
  );
  return result.rows[0] || null;
}

async function addAttendee({ sessionId, userId, joinRequestId, transportMode, billSharePct, isHost }) {
  const result = await query(
    `INSERT INTO session_attendees
       (session_id, user_id, join_request_id, transport_mode, bill_share_pct, is_host)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [sessionId, userId, joinRequestId, transportMode, billSharePct || null, isHost || false]
  );
  return result.rows[0];
}

async function getAttendees(sessionId) {
  const result = await query(
    `SELECT sa.*, u.full_name, u.display_name, u.avatar_url, u.baraqah_score
     FROM session_attendees sa
     JOIN users u ON u.id = sa.user_id
     WHERE sa.session_id = $1
     ORDER BY sa.joined_at`,
    [sessionId]
  );
  return result.rows;
}

async function isAttendee(sessionId, userId) {
  const result = await query(
    `SELECT id FROM session_attendees WHERE session_id = $1 AND user_id = $2`,
    [sessionId, userId]
  );
  return !!result.rows[0];
}

async function updateTransport(sessionId, userId, transportMode) {
  await query(
    `UPDATE session_attendees SET transport_mode = $1
     WHERE session_id = $2 AND user_id = $3`,
    [transportMode, sessionId, userId]
  );
}

async function updateRideSeats(sessionId, seats) {
  await query(
    `UPDATE dining_sessions SET available_ride_seats = $1 WHERE id = $2`,
    [seats, sessionId]
  );
}

async function updateRideAvailability(sessionId, hasRide, seats, vehicleInfo) {
  await query(
    `UPDATE dining_sessions
     SET has_ride_available = $1, available_ride_seats = $2, vehicle_info = $3
     WHERE id = $4`,
    [hasRide, seats, vehicleInfo ? JSON.stringify(vehicleInfo) : null, sessionId]
  );
}

async function getPendingRequests(sessionId) {
  const result = await query(
    `SELECT jr.*, u.full_name, u.display_name, u.avatar_url, u.baraqah_score
     FROM join_requests jr
     JOIN users u ON u.id = jr.requester_id
     WHERE jr.session_id = $1 AND jr.status = 'PENDING'
     ORDER BY jr.created_at`,
    [sessionId]
  );
  return result.rows;
}

async function getUserSessions(userId) {
  const result = await query(
    `SELECT ds.* FROM dining_sessions ds
     JOIN session_attendees sa ON sa.session_id = ds.id
     WHERE sa.user_id = $1
     ORDER BY ds.scheduled_at DESC`,
    [userId]
  );
  return result.rows;
}

module.exports = {
  findById,
  create,
  findOpenNearby,
  updateStatus,
  updateQrToken,
  setCheckinWindow,
  createJoinRequest,
  findJoinRequest,
  updateJoinRequestStatus,
  addAttendee,
  getAttendees,
  isAttendee,
  updateTransport,
  updateRideSeats,
  updateRideAvailability,
  getPendingRequests,
  getUserSessions,
  withTransaction,
};
