'use strict';

const EARTH_RADIUS_KM = 6371;

/**
 * Haversine distance between two lat/lng points in kilometers.
 */
function haversineKm(lat1, lng1, lat2, lng2) {
  const toRad = (deg) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * Build PostGIS ST_MakePoint WKT for SRID 4326.
 */
function pointWkt(lng, lat) {
  return `SRID=4326;POINT(${lng} ${lat})`;
}

/**
 * Extract lat/lng from PostGIS geometry returned by pg.
 * pg returns GeoJSON-like or WKB; we use ST_X/ST_Y in queries instead.
 */
function parsePointFromRow(row) {
  if (!row) return null;
  if (row.lat != null && row.lng != null) {
    return { lat: parseFloat(row.lat), lng: parseFloat(row.lng) };
  }
  return null;
}

/**
 * Simple geohash for cache key (precision 6 ~ 1.2km).
 */
function simpleGeohash(lat, lng, precision = 6) {
  const latStr = lat.toFixed(precision);
  const lngStr = lng.toFixed(precision);
  return `${latStr}:${lngStr}`;
}

/**
 * Check if point is within radius of center.
 */
function isWithinRadius(lat, lng, centerLat, centerLng, radiusMeters) {
  const distKm = haversineKm(lat, lng, centerLat, centerLng);
  return distKm * 1000 <= radiusMeters;
}

module.exports = {
  haversineKm,
  pointWkt,
  parsePointFromRow,
  simpleGeohash,
  isWithinRadius,
  EARTH_RADIUS_KM,
};
