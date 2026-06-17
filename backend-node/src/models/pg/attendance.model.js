'use strict';

const { query } = require('../../config/database');
const { pointWkt } = require('../../utils/geo.utils');

async function createLog({ sessionId, attendeeUserId, status, lat, lng, deviceInfo }) {
  const result = await query(
    `INSERT INTO attendance_logs
       (session_id, attendee_user_id, status, scan_location, scan_device_info)
     VALUES ($1, $2, $3,
             ${lat != null ? 'ST_GeomFromText($4, 4326)' : 'NULL'},
             ${lat != null ? '$5' : '$4'})
     RETURNING *`,
    lat != null
      ? [sessionId, attendeeUserId, status, pointWkt(lng, lat), deviceInfo ? JSON.stringify(deviceInfo) : null]
      : [sessionId, attendeeUserId, status, deviceInfo ? JSON.stringify(deviceInfo) : null]
  );
  return result.rows[0];
}

async function findBySessionAndUser(sessionId, userId) {
  const result = await query(
    `SELECT * FROM attendance_logs WHERE session_id = $1 AND attendee_user_id = $2`,
    [sessionId, userId]
  );
  return result.rows[0] || null;
}

async function getSessionAttendance(sessionId) {
  const result = await query(
    `SELECT al.*, u.full_name, u.display_name, u.avatar_url
     FROM attendance_logs al
     JOIN users u ON u.id = al.attendee_user_id
     WHERE al.session_id = $1
     ORDER BY al.scanned_at`,
    [sessionId]
  );
  return result.rows;
}

async function markNoShows(sessionId) {
  const result = await query(
    `INSERT INTO attendance_logs (session_id, attendee_user_id, status)
     SELECT sa.session_id, sa.user_id, 'NO_SHOW'
     FROM session_attendees sa
     WHERE sa.session_id = $1
       AND NOT EXISTS (
         SELECT 1 FROM attendance_logs al
         WHERE al.session_id = sa.session_id AND al.attendee_user_id = sa.user_id
       )
     RETURNING *`,
    [sessionId]
  );
  return result.rows;
}

async function countConfirmed(sessionId) {
  const result = await query(
    `SELECT COUNT(*)::int AS count FROM attendance_logs
     WHERE session_id = $1 AND status = 'CONFIRMED'`,
    [sessionId]
  );
  return result.rows[0].count;
}

module.exports = {
  createLog,
  findBySessionAndUser,
  getSessionAttendance,
  markNoShows,
  countConfirmed,
};
