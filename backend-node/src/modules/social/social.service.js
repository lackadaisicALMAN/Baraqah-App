'use strict';

const { query } = require('../../config/database');
const userModel = require('../../models/pg/user.model');
const { getRedis, RedisKeys, RedisTTL } = require('../../config/redis');
const checkinService = require('../checkin/checkin.service');

async function sendFriendRequest(requesterId, addresseeId) {
  if (requesterId === addresseeId) {
    const err = new Error('Cannot friend yourself');
    err.statusCode = 400;
    throw err;
  }

  const addressee = await userModel.findById(addresseeId);
  if (!addressee) {
    const err = new Error('User not found');
    err.statusCode = 404;
    throw err;
  }

  const result = await query(
    `INSERT INTO friendships (requester_id, addressee_id, status)
     VALUES ($1, $2, 'PENDING')
     ON CONFLICT (requester_id, addressee_id) DO NOTHING
     RETURNING *`,
    [requesterId, addresseeId]
  );

  return result.rows[0] || null;
}

async function acceptFriendRequest(addresseeId, friendshipId) {
  const result = await query(
    `UPDATE friendships SET status = 'ACCEPTED'
     WHERE id = $1 AND addressee_id = $2 AND status = 'PENDING'
     RETURNING *`,
    [friendshipId, addresseeId]
  );

  if (!result.rows[0]) {
    const err = new Error('Friend request not found');
    err.statusCode = 404;
    throw err;
  }

  const friendship = result.rows[0];
  await checkinService.applyScoreEvent(
    friendship.requester_id,
    'VOUCHED_BY_FRIEND',
    null,
    0.25
  );

  return friendship;
}

async function getFriends(userId) {
  const result = await query(
    `SELECT f.*,
            CASE WHEN f.requester_id = $1 THEN f.addressee_id ELSE f.requester_id END AS friend_id,
            u.full_name, u.display_name, u.avatar_url, u.baraqah_score
     FROM friendships f
     JOIN users u ON u.id = CASE WHEN f.requester_id = $1 THEN f.addressee_id ELSE f.requester_id END
     WHERE (f.requester_id = $1 OR f.addressee_id = $1)
       AND f.status = 'ACCEPTED'
       AND u.deleted_at IS NULL`,
    [userId]
  );
  return result.rows;
}

async function getPendingRequests(userId) {
  const result = await query(
    `SELECT f.*, u.full_name, u.display_name, u.avatar_url
     FROM friendships f
     JOIN users u ON u.id = f.requester_id
     WHERE f.addressee_id = $1 AND f.status = 'PENDING'`,
    [userId]
  );
  return result.rows;
}

async function getLeaderboard(city, limit = 50) {
  const redis = getRedis();
  const key = city
    ? RedisKeys.scoreLeaderboardCity(city)
    : RedisKeys.scoreLeaderboard;

  const entries = await redis.zrevrange(key, 0, limit - 1, 'WITHSCORES');
  const results = [];

  for (let i = 0; i < entries.length; i += 2) {
    const userId = entries[i];
    const score = parseFloat(entries[i + 1]);
    const user = await userModel.findById(userId);
    if (user) {
      results.push({
        user_id: userId,
        full_name: user.full_name,
        display_name: user.display_name,
        avatar_url: user.avatar_url,
        baraqah_score: score,
      });
    }
  }

  if (results.length === 0) {
    const pgResult = await query(
      `SELECT id AS user_id, full_name, display_name, avatar_url, baraqah_score
       FROM users WHERE deleted_at IS NULL
       ORDER BY baraqah_score DESC LIMIT $1`,
      [limit]
    );
    return pgResult.rows;
  }

  return results;
}

async function syncContactsAndSuggest(userId, contacts) {
  const usersService = require('../users/users.service');
  const synced = await usersService.syncContacts(userId, contacts);

  const matched = synced.filter((c) => c.matched);
  const suggestions = [];

  for (const contact of matched) {
    const existing = await query(
      `SELECT id FROM friendships
       WHERE ((requester_id = $1 AND addressee_id = $2)
          OR (requester_id = $2 AND addressee_id = $1))
         AND status IN ('PENDING', 'ACCEPTED')`,
      [userId, contact.matched_user_id]
    );
    if (!existing.rows[0]) {
      const user = await userModel.findById(contact.matched_user_id);
      suggestions.push({ ...contact, user });
    }
  }

  return { synced, suggestions };
}

module.exports = {
  sendFriendRequest,
  acceptFriendRequest,
  getFriends,
  getPendingRequests,
  getLeaderboard,
  syncContactsAndSuggest,
};
