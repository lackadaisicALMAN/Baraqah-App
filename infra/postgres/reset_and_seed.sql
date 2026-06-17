-- ============================================================
-- BARAQAH — Reset User Data & Seed Restaurants
-- Run this to clear all registrations and seed fresh restaurant data
-- Usage: docker exec baraqah-postgres psql -U baraqah -d baraqah -f /tmp/reset_and_seed.sql
-- ============================================================

-- Disable triggers temporarily for clean truncation
SET session_replication_role = replica;

-- Wipe all user-generated data (order matters for FK constraints)
TRUNCATE TABLE
  notifications,
  baraqah_score_events,
  attendance_logs,
  session_attendees,
  join_requests,
  dining_sessions,
  user_contacts,
  friendships,
  refresh_tokens,
  users
CASCADE;

-- Wipe existing restaurants
TRUNCATE TABLE restaurants CASCADE;

-- Re-enable triggers
SET session_replication_role = DEFAULT;

-- ============================================================
-- SEED: 7 Restaurants (Lahore, Pakistan)
-- ============================================================

INSERT INTO restaurants (
  id, name, address, city, country, location,
  cuisine_tags, price_range, avg_rating, verified_review_count,
  is_active
) VALUES
(
  uuid_generate_v4(),
  'Karachi Silver Spoon',
  'Near UCP, Lahore',
  'Lahore',
  'Pakistan',
  ST_SetSRID(ST_MakePoint(74.2733, 31.4698), 4326),
  ARRAY['Pakistani', 'BBQ', 'Grills'],
  2,
  0.00,
  0,
  TRUE
),
(
  uuid_generate_v4(),
  'Karachi Red Rock',
  'Johar Town, Lahore',
  'Lahore',
  'Pakistan',
  ST_SetSRID(ST_MakePoint(74.2786, 31.4697), 4326),
  ARRAY['Pakistani', 'Karahi', 'Seafood'],
  2,
  0.00,
  0,
  TRUE
),
(
  uuid_generate_v4(),
  'Tehzeeb Bakers',
  'MM Alam Road, Lahore',
  'Lahore',
  'Pakistan',
  ST_SetSRID(ST_MakePoint(74.3344, 31.4833), 4326),
  ARRAY['Bakery', 'Desserts', 'Sweets'],
  1,
  0.00,
  0,
  TRUE
),
(
  uuid_generate_v4(),
  'Crumble JT',
  'Johar Town, Lahore',
  'Lahore',
  'Pakistan',
  ST_SetSRID(ST_MakePoint(74.2790, 31.4695), 4326),
  ARRAY['Desserts', 'Waffles', 'Cafe'],
  2,
  0.00,
  0,
  TRUE
),
(
  uuid_generate_v4(),
  'Crumble MM Alam',
  'MM Alam Road, Lahore',
  'Lahore',
  'Pakistan',
  ST_SetSRID(ST_MakePoint(74.3346, 31.4834), 4326),
  ARRAY['Desserts', 'Waffles', 'Cafe'],
  2,
  0.00,
  0,
  TRUE
),
(
  uuid_generate_v4(),
  'Master Biryani',
  'Model Town Link Road, Lahore',
  'Lahore',
  'Pakistan',
  ST_SetSRID(ST_MakePoint(74.3089, 31.4842), 4326),
  ARRAY['Pakistani', 'Biryani', 'Rice'],
  1,
  0.00,
  0,
  TRUE
),
(
  uuid_generate_v4(),
  'Ouii',
  'Model Town C Block Market, Lahore',
  'Lahore',
  'Pakistan',
  ST_SetSRID(ST_MakePoint(74.3100, 31.4870), 4326),
  ARRAY['Cafe', 'Continental', 'Burgers'],
  2,
  0.00,
  0,
  TRUE
);

-- Confirm
SELECT name, address, avg_rating, verified_review_count
FROM restaurants
ORDER BY name;
