'use strict';

const { query } = require('../../config/database');
const { pointWkt } = require('../../utils/geo.utils');

async function findById(id) {
  const result = await query(
    `SELECT id, google_place_id, name, address, city, country,
            ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng,
            phone_number, website_url, cuisine_tags, price_range,
            avg_rating, verified_review_count, opening_hours, photo_urls,
            is_active, created_at
     FROM restaurants WHERE id = $1`,
    [id]
  );
  return result.rows[0] || null;
}

async function findByGooglePlaceId(googlePlaceId) {
  const result = await query(
    `SELECT id FROM restaurants WHERE google_place_id = $1`,
    [googlePlaceId]
  );
  return result.rows[0] || null;
}

async function create(data) {
  const result = await query(
    `INSERT INTO restaurants
       (google_place_id, name, address, city, country, location,
        phone_number, website_url, cuisine_tags, price_range, opening_hours, photo_urls)
     VALUES ($1, $2, $3, $4, $5, ST_GeomFromText($6, 4326), $7, $8, $9, $10, $11, $12)
     RETURNING id, name, city`,
    [
      data.googlePlaceId || null,
      data.name,
      data.address,
      data.city,
      data.country || 'Pakistan',
      pointWkt(data.lng, data.lat),
      data.phoneNumber || null,
      data.websiteUrl || null,
      data.cuisineTags || [],
      data.priceRange || null,
      data.openingHours ? JSON.stringify(data.openingHours) : null,
      data.photoUrls || [],
    ]
  );
  return result.rows[0];
}

async function searchNearby(lat, lng, radiusKm = 10, limit = 50) {
  const result = await query(
    `SELECT id, name, address, city, cuisine_tags, price_range, avg_rating,
            ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng,
            ST_Distance(
              location::geography,
              ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography
            ) / 1000 AS distance_km
     FROM restaurants
     WHERE is_active = TRUE
       AND ST_DWithin(
             location::geography,
             ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography,
             $3 * 1000
           )
     ORDER BY distance_km
     LIMIT $4`,
    [lat, lng, radiusKm, limit]
  );
  return result.rows;
}

async function updateReviewStats(restaurantId, avgRating, reviewCount) {
  await query(
    `UPDATE restaurants SET avg_rating = $1, verified_review_count = $2, updated_at = NOW()
     WHERE id = $3`,
    [avgRating, reviewCount, restaurantId]
  );
}

async function findAll(limit = 100) {
  const result = await query(
    `SELECT id, name, address, city, country,
            ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng,
            cuisine_tags, price_range, avg_rating, verified_review_count
     FROM restaurants
     WHERE is_active = TRUE
     ORDER BY name
     LIMIT $1`,
    [limit]
  );
  return result.rows;
}

module.exports = {
  findById,
  findByGooglePlaceId,
  create,
  searchNearby,
  updateReviewStats,
  findAll,
};
