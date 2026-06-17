'use strict';

const { query, withTransaction } = require('../../config/database');
const { pointWkt } = require('../../utils/geo.utils');
const crypto = require('crypto');

async function findById(id) {
  const result = await query(
    `SELECT id, phone_number, email, full_name, display_name, avatar_url, bio,
            baraqah_score, total_sessions, total_hosted, total_no_shows,
            ST_Y(last_known_location::geometry) AS lat,
            ST_X(last_known_location::geometry) AS lng,
            location_updated_at, is_profile_complete, is_phone_verified,
            is_active, created_at, updated_at
     FROM users WHERE id = $1 AND deleted_at IS NULL`,
    [id]
  );
  return result.rows[0] || null;
}

async function findByPhone(phoneNumber) {
  const result = await query(
    `SELECT id, phone_number, email, password_hash, full_name, display_name,
            avatar_url, bio, baraqah_score, is_profile_complete, is_phone_verified,
            is_active, created_at
     FROM users WHERE phone_number = $1 AND deleted_at IS NULL`,
    [phoneNumber]
  );
  return result.rows[0] || null;
}

async function create({ phoneNumber, email, passwordHash, fullName, displayName }) {
  const result = await query(
    `INSERT INTO users (phone_number, email, password_hash, full_name, display_name)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING id, phone_number, email, full_name, display_name, baraqah_score,
               is_profile_complete, created_at`,
    [phoneNumber, email || null, passwordHash, fullName, displayName || null]
  );
  return result.rows[0];
}

async function updateProfile(id, fields) {
  const allowed = ['full_name', 'display_name', 'avatar_url', 'bio', 'email'];
  const sets = [];
  const params = [];
  let idx = 1;

  for (const key of allowed) {
    if (fields[key] !== undefined) {
      sets.push(`${key} = $${idx++}`);
      params.push(fields[key]);
    }
  }

  if (fields.lat != null && fields.lng != null) {
    sets.push(`last_known_location = ST_GeomFromText($${idx++}, 4326)`);
    params.push(pointWkt(fields.lng, fields.lat));
    sets.push(`location_updated_at = NOW()`);
  }

  if (fields.is_profile_complete !== undefined) {
    sets.push(`is_profile_complete = $${idx++}`);
    params.push(fields.is_profile_complete);
  }

  if (fields.is_phone_verified !== undefined) {
    sets.push(`is_phone_verified = $${idx++}`);
    params.push(fields.is_phone_verified);
  }

  if (sets.length === 0) return findById(id);

  params.push(id);
  await query(`UPDATE users SET ${sets.join(', ')} WHERE id = $${idx}`, params);
  return findById(id);
}

async function updateScore(userId, newScore) {
  await query(
    `UPDATE users SET baraqah_score = $1 WHERE id = $2`,
    [newScore, userId]
  );
}

async function findNearby(lat, lng, radiusKm = 5, limit = 20) {
  const result = await query(
    `SELECT id, full_name, display_name, avatar_url, baraqah_score,
            ST_Y(last_known_location::geometry) AS lat,
            ST_X(last_known_location::geometry) AS lng,
            ST_Distance(
              last_known_location::geography,
              ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography
            ) / 1000 AS distance_km
     FROM users
     WHERE deleted_at IS NULL
       AND last_known_location IS NOT NULL
       AND ST_DWithin(
             last_known_location::geography,
             ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography,
             $3 * 1000
           )
     ORDER BY distance_km
     LIMIT $4`,
    [lat, lng, radiusKm, limit]
  );
  return result.rows;
}

async function storeRefreshToken({ userId, rawToken, deviceInfo, ipAddress, expiresAt }) {
  const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');
  const result = await query(
    `INSERT INTO refresh_tokens (user_id, token_hash, device_info, ip_address, expires_at)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING id`,
    [userId, tokenHash, deviceInfo ? JSON.stringify(deviceInfo) : null, ipAddress, expiresAt]
  );
  return result.rows[0];
}

async function findRefreshToken(rawToken) {
  const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');
  const result = await query(
    `SELECT rt.*, u.phone_number, u.is_active
     FROM refresh_tokens rt
     JOIN users u ON u.id = rt.user_id
     WHERE rt.token_hash = $1 AND rt.is_revoked = FALSE AND rt.expires_at > NOW()
       AND u.deleted_at IS NULL`,
    [tokenHash]
  );
  return result.rows[0] || null;
}

async function revokeRefreshToken(rawToken) {
  const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');
  await query(
    `UPDATE refresh_tokens SET is_revoked = TRUE WHERE token_hash = $1`,
    [tokenHash]
  );
}

async function revokeAllUserTokens(userId) {
  await query(
    `UPDATE refresh_tokens SET is_revoked = TRUE WHERE user_id = $1 AND is_revoked = FALSE`,
    [userId]
  );
}

async function recordScoreEvent(client, data) {
  const isClient = client && typeof client.query === 'function';
  const db = isClient ? client : { query };
  const payload = isClient ? data : (data || client);

  const { userId, eventType, sessionId, delta, scoreBefore, scoreAfter, metadata } = payload;
  await db.query(
    `INSERT INTO baraqah_score_events
       (user_id, event_type, session_id, delta, score_before, score_after, metadata)
     VALUES ($1, $2, $3, $4, $5, $6, $7)`,
    [userId, eventType, sessionId || null, delta, scoreBefore, scoreAfter, JSON.stringify(metadata || {})]
  );
}

module.exports = {
  findById,
  findByPhone,
  create,
  updateProfile,
  updateScore,
  findNearby,
  storeRefreshToken,
  findRefreshToken,
  revokeRefreshToken,
  revokeAllUserTokens,
  recordScoreEvent,
  withTransaction,
};
