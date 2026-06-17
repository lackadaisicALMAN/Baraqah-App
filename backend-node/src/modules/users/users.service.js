'use strict';

const userModel = require('../../models/pg/user.model');
const UserProfile = require('../../models/mongo/UserProfile.model');
const { query } = require('../../config/database');
const { getRedis, RedisKeys, RedisTTL } = require('../../config/redis');

async function getProfile(userId) {
  const [user, profile] = await Promise.all([
    userModel.findById(userId),
    UserProfile.findOne({ userId }).lean(),
  ]);

  if (!user) {
    const err = new Error('User not found');
    err.statusCode = 404;
    throw err;
  }

  return { user, profile };
}

async function updateProfile(userId, data) {
  const updates = {};
  if (data.full_name) updates.full_name = data.full_name;
  if (data.display_name) updates.display_name = data.display_name;
  if (data.avatar_url) updates.avatar_url = data.avatar_url;
  if (data.bio) updates.bio = data.bio;
  if (data.email) updates.email = data.email;
  if (data.lat != null && data.lng != null) {
    updates.lat = data.lat;
    updates.lng = data.lng;
  }

  const hasRequired = data.full_name && data.display_name;
  if (hasRequired) updates.is_profile_complete = true;

  const user = await userModel.updateProfile(userId, updates);

  if (data.lat != null && data.lng != null) {
    const redis = getRedis();
    await redis.hset(RedisKeys.userLocation(userId), {
      lat: String(data.lat),
      lng: String(data.lng),
      accuracy: String(data.accuracy || 0),
      updated_at: new Date().toISOString(),
    });
    await redis.expire(RedisKeys.userLocation(userId), RedisTTL.USER_LOCATION);
  }

  return user;
}

async function updatePreferences(userId, prefs) {
  const profile = await UserProfile.findOne({ userId });
  if (!profile) {
    const err = new Error('Profile not found');
    err.statusCode = 404;
    throw err;
  }

  if (prefs.cuisine_weights) {
    profile.preference_vector.cuisine_weights = prefs.cuisine_weights;
  }
  if (prefs.price_range_preference != null) {
    profile.preference_vector.price_range_preference = prefs.price_range_preference;
  }
  if (prefs.transport_preference) {
    profile.preference_vector.transport_preference = prefs.transport_preference;
  }
  if (prefs.dietary_restrictions) {
    profile.preference_vector.dietary_restrictions = prefs.dietary_restrictions;
  }
  if (prefs.social_comfort_level != null) {
    profile.preference_vector.social_comfort_level = prefs.social_comfort_level;
  }

  await profile.save();
  return profile.toObject();
}

async function syncContacts(userId, contacts) {
  const results = [];

  for (const contact of contacts) {
    const matched = await userModel.findByPhone(contact.phone_number);

    await query(
      `INSERT INTO user_contacts (owner_user_id, contact_name, phone_number, matched_user_id)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (owner_user_id, phone_number)
       DO UPDATE SET contact_name = EXCLUDED.contact_name,
                     matched_user_id = EXCLUDED.matched_user_id,
                     synced_at = NOW()`,
      [userId, contact.contact_name || null, contact.phone_number, matched?.id || null]
    );

    results.push({
      phone_number: contact.phone_number,
      contact_name: contact.contact_name,
      matched_user_id: matched?.id || null,
      matched: !!matched,
    });
  }

  return results;
}

async function updateLocation(userId, lat, lng, accuracy) {
  await userModel.updateProfile(userId, { lat, lng });

  const redis = getRedis();
  await redis.hset(RedisKeys.userLocation(userId), {
    lat: String(lat),
    lng: String(lng),
    accuracy: String(accuracy || 0),
    updated_at: new Date().toISOString(),
  });
  await redis.expire(RedisKeys.userLocation(userId), RedisTTL.USER_LOCATION);

  return { lat, lng };
}

async function getScore(userId) {
  const redis = getRedis();
  const cached = await redis.hgetall(RedisKeys.scoreCache(userId));
  if (cached && cached.score) {
    return {
      score: parseFloat(cached.score),
      rank: cached.rank ? parseInt(cached.rank, 10) : null,
      cached: true,
    };
  }

  const user = await userModel.findById(userId);
  if (!user) {
    const err = new Error('User not found');
    err.statusCode = 404;
    throw err;
  }

  const rankResult = await query(
    `SELECT COUNT(*) + 1 AS rank FROM users
     WHERE baraqah_score > $1 AND deleted_at IS NULL`,
    [user.baraqah_score]
  );

  return {
    score: parseFloat(user.baraqah_score),
    rank: parseInt(rankResult.rows[0].rank, 10),
    cached: false,
  };
}

module.exports = {
  getProfile,
  updateProfile,
  updatePreferences,
  syncContacts,
  updateLocation,
  getScore,
};
