# Baraqah – FoodPool: System Architecture Document
**Version:** 1.0.0 | **Status:** Foundation Review  
**Stack:** Flutter · Node.js (Express) · Python (FastAPI) · PostgreSQL · MongoDB · Redis

---

## Table of Contents
1. [Directory Tree Structure](#1-directory-tree-structure)
2. [PostgreSQL Relational Schema (DDL)](#2-postgresql-relational-schema-ddl)
3. [MongoDB Document Schemas](#3-mongodb-document-schemas)
4. [Redis Key-Value Mapping Architecture](#4-redis-key-value-mapping-architecture)
5. [Cross-Database Relationship Map](#5-cross-database-relationship-map)
6. [Design Rationale Notes](#6-design-rationale-notes)

---

## 1. Directory Tree Structure

```
baraqah/
│
├── README.md
├── docker-compose.yml                    # Orchestrates all services locally
├── .env.example                          # Master environment variable template
│
├── mobile/                               # Flutter cross-platform app (iOS + Android)
│   ├── pubspec.yaml
│   ├── pubspec.lock
│   ├── analysis_options.yaml
│   ├── android/
│   ├── ios/
│   └── lib/
│       ├── main.dart                     # App entry point, provider setup
│       ├── app.dart                      # MaterialApp, theme, router config
│       ├── core/
│       │   ├── constants/
│       │   │   ├── api_endpoints.dart    # All backend URL constants
│       │   │   ├── app_colors.dart       # Design system color tokens
│       │   │   └── app_strings.dart      # i18n strings (English + Urdu)
│       │   ├── errors/
│       │   │   ├── exceptions.dart       # Custom exception classes
│       │   │   └── failures.dart         # Failure sealed classes (Either<>)
│       │   ├── network/
│       │   │   ├── api_client.dart       # Dio HTTP client with interceptors
│       │   │   ├── auth_interceptor.dart # JWT attach + refresh logic
│       │   │   └── socket_client.dart    # Socket.IO wrapper for real-time
│       │   ├── storage/
│       │   │   ├── secure_storage.dart   # FlutterSecureStorage wrapper
│       │   │   └── local_db.dart         # Hive local cache wrapper
│       │   └── utils/
│       │       ├── location_utils.dart   # Geolocator helper functions
│       │       ├── qr_utils.dart         # QR code generation/scanning utils
│       │       └── date_utils.dart       # Date formatting helpers
│       │
│       ├── features/
│       │   ├── auth/
│       │   │   ├── data/
│       │   │   │   ├── datasources/
│       │   │   │   │   ├── auth_remote_datasource.dart
│       │   │   │   │   └── auth_local_datasource.dart
│       │   │   │   ├── models/
│       │   │   │   │   ├── user_model.dart
│       │   │   │   │   └── token_model.dart
│       │   │   │   └── repositories/
│       │   │   │       └── auth_repository_impl.dart
│       │   │   ├── domain/
│       │   │   │   ├── entities/
│       │   │   │   │   └── user_entity.dart
│       │   │   │   ├── repositories/
│       │   │   │   │   └── auth_repository.dart
│       │   │   │   └── usecases/
│       │   │   │       ├── login_usecase.dart
│       │   │   │       ├── register_usecase.dart
│       │   │   │       └── refresh_token_usecase.dart
│       │   │   └── presentation/
│       │   │       ├── bloc/
│       │   │       │   ├── auth_bloc.dart
│       │   │       │   ├── auth_event.dart
│       │   │       │   └── auth_state.dart
│       │   │       └── pages/
│       │   │           ├── login_page.dart
│       │   │           ├── register_page.dart
│       │   │           └── profile_setup_page.dart
│       │   │
│       │   ├── sessions/
│       │   │   ├── data/
│       │   │   │   ├── datasources/
│       │   │   │   │   └── sessions_remote_datasource.dart
│       │   │   │   ├── models/
│       │   │   │   │   ├── session_model.dart
│       │   │   │   │   └── join_request_model.dart
│       │   │   │   └── repositories/
│       │   │   │       └── sessions_repository_impl.dart
│       │   │   ├── domain/
│       │   │   │   ├── entities/
│       │   │   │   │   ├── session_entity.dart
│       │   │   │   │   └── join_request_entity.dart
│       │   │   │   ├── repositories/
│       │   │   │   │   └── sessions_repository.dart
│       │   │   │   └── usecases/
│       │   │   │       ├── create_session_usecase.dart
│       │   │   │       ├── browse_sessions_usecase.dart
│       │   │   │       ├── join_session_usecase.dart
│       │   │   │       └── qr_checkin_usecase.dart
│       │   │   └── presentation/
│       │   │       ├── bloc/
│       │   │       │   ├── session_bloc.dart
│       │   │       │   ├── session_event.dart
│       │   │       │   └── session_state.dart
│       │   │       ├── pages/
│       │   │       │   ├── create_session_page.dart
│       │   │       │   ├── browse_sessions_page.dart
│       │   │       │   ├── session_detail_page.dart
│       │   │       │   └── qr_checkin_page.dart
│       │   │       └── widgets/
│       │   │           ├── session_card_widget.dart
│       │   │           ├── map_view_widget.dart
│       │   │           └── split_selector_widget.dart
│       │   │
│       │   ├── transport/
│       │   │   ├── data/
│       │   │   │   └── datasources/
│       │   │   │       └── transport_remote_datasource.dart
│       │   │   ├── domain/
│       │   │   │   └── usecases/
│       │   │   │       └── toggle_ride_together_usecase.dart
│       │   │   └── presentation/
│       │   │       └── widgets/
│       │   │           └── transport_option_widget.dart
│       │   │
│       │   ├── reviews/
│       │   │   ├── data/
│       │   │   │   ├── models/
│       │   │   │   │   └── review_model.dart
│       │   │   │   └── repositories/
│       │   │   │       └── reviews_repository_impl.dart
│       │   │   ├── domain/
│       │   │   │   └── usecases/
│       │   │   │       └── submit_verified_review_usecase.dart
│       │   │   └── presentation/
│       │   │       ├── bloc/
│       │   │       │   └── review_bloc.dart
│       │   │       └── pages/
│       │   │           └── submit_review_page.dart
│       │   │
│       │   ├── social/
│       │   │   ├── data/
│       │   │   │   └── datasources/
│       │   │   │       └── contacts_remote_datasource.dart
│       │   │   ├── domain/
│       │   │   │   └── usecases/
│       │   │   │       └── sync_contacts_usecase.dart
│       │   │   └── presentation/
│       │   │       ├── bloc/
│       │   │       │   └── friends_bloc.dart
│       │   │       └── pages/
│       │   │           ├── friends_page.dart
│       │   │           └── baraqah_score_page.dart
│       │   │
│       │   └── chat/
│       │       ├── data/
│       │       │   └── datasources/
│       │       │       └── chat_remote_datasource.dart
│       │       ├── domain/
│       │       │   └── usecases/
│       │       │       └── send_message_usecase.dart
│       │       └── presentation/
│       │           ├── bloc/
│       │           │   └── chat_bloc.dart
│       │           └── pages/
│       │               └── group_chat_page.dart
│       │
│       └── shared/
│           ├── widgets/
│           │   ├── baraqah_button.dart
│           │   ├── baraqah_text_field.dart
│           │   ├── score_badge_widget.dart
│           │   └── loading_overlay.dart
│           └── theme/
│               ├── app_theme.dart
│               └── text_styles.dart
│
├── backend-node/                         # Node.js Express — Core API Gateway
│   ├── package.json
│   ├── package-lock.json
│   ├── .env.example
│   ├── Dockerfile
│   └── src/
│       ├── server.js                     # Express app bootstrap + middleware
│       ├── config/
│       │   ├── database.js               # PostgreSQL (pg-pool) config
│       │   ├── mongo.js                  # Mongoose connection config
│       │   ├── redis.js                  # ioredis client config
│       │   └── socket.js                 # Socket.IO server init + namespace
│       ├── middleware/
│       │   ├── auth.middleware.js        # JWT verification middleware
│       │   ├── rateLimiter.middleware.js # Redis-backed rate limiter
│       │   ├── validate.middleware.js    # Joi schema validation middleware
│       │   └── error.middleware.js       # Global error handler
│       ├── modules/
│       │   ├── auth/
│       │   │   ├── auth.routes.js
│       │   │   ├── auth.controller.js
│       │   │   ├── auth.service.js       # bcrypt, JWT sign/verify, refresh
│       │   │   └── auth.validation.js    # Joi schemas for request bodies
│       │   ├── users/
│       │   │   ├── users.routes.js
│       │   │   ├── users.controller.js
│       │   │   ├── users.service.js      # Profile CRUD, contact sync
│       │   │   └── users.validation.js
│       │   ├── sessions/
│       │   │   ├── sessions.routes.js
│       │   │   ├── sessions.controller.js
│       │   │   ├── sessions.service.js   # Session lifecycle, geospatial queries
│       │   │   ├── sessions.socket.js    # Socket events for real-time updates
│       │   │   └── sessions.validation.js
│       │   ├── transport/
│       │   │   ├── transport.routes.js
│       │   │   ├── transport.controller.js
│       │   │   └── transport.service.js  # Ride-together seat management
│       │   ├── checkin/
│       │   │   ├── checkin.routes.js
│       │   │   ├── checkin.controller.js
│       │   │   └── checkin.service.js    # QR gen, scan validation, attendance log
│       │   ├── reviews/
│       │   │   ├── reviews.routes.js
│       │   │   ├── reviews.controller.js
│       │   │   └── reviews.service.js    # Verified-session review gate
│       │   └── social/
│       │       ├── social.routes.js
│       │       ├── social.controller.js
│       │       └── social.service.js     # Friends, follow, contact import
│       ├── models/
│       │   ├── pg/                       # Raw SQL query functions (pg-pool)
│       │   │   ├── user.model.js
│       │   │   ├── session.model.js
│       │   │   ├── attendance.model.js
│       │   │   └── restaurant.model.js
│       │   └── mongo/                    # Mongoose schemas
│       │       ├── UserProfile.model.js
│       │       ├── Review.model.js
│       │       └── GroupChat.model.js
│       └── utils/
│           ├── logger.js                 # Winston structured logger
│           ├── qr.utils.js               # QR code generation (qrcode library)
│           ├── geo.utils.js              # Haversine + PostGIS helpers
│           └── response.utils.js         # Standard API response envelope
│
├── backend-python/                       # Python FastAPI — ML / Scoring Service
│   ├── requirements.txt
│   ├── Dockerfile
│   ├── .env.example
│   └── app/
│       ├── main.py                       # FastAPI app factory, lifespan events
│       ├── config/
│       │   ├── settings.py               # Pydantic BaseSettings (env vars)
│       │   ├── database.py               # SQLAlchemy async engine (PostgreSQL)
│       │   ├── mongo.py                  # Motor async MongoDB client
│       │   └── redis.py                  # aioredis async client
│       ├── api/
│       │   ├── v1/
│       │   │   ├── router.py             # Aggregate all v1 routers
│       │   │   ├── matching.py           # /match/sessions endpoint
│       │   │   └── scoring.py            # /score/baraqah endpoint
│       │   └── dependencies.py           # FastAPI Depends() providers
│       ├── services/
│       │   ├── matching_service.py       # Core matching algorithm logic
│       │   ├── scoring_service.py        # Baraqah Score computation
│       │   └── preference_service.py     # User preference vector management
│       ├── ml/
│       │   ├── feature_engineering.py    # Feature extraction from raw data
│       │   ├── similarity.py             # Cosine / weighted similarity funcs
│       │   └── score_model.py            # Baraqah Score formula + decay model
│       ├── schemas/
│       │   ├── matching.py               # Pydantic request/response schemas
│       │   └── scoring.py
│       └── utils/
│           ├── logger.py                 # structlog configuration
│           └── cache.py                  # Redis cache decorator helpers
│
├── infra/
│   ├── nginx/
│   │   └── nginx.conf                    # Reverse proxy (Node :3000, Python :8000)
│   ├── postgres/
│   │   └── init.sql                      # DDL schema (see Section 2)
│   └── scripts/
│       ├── seed_dev.js                   # Development seed data script
│       └── migrate.sh                    # Run Flyway/dbmate migrations
│
└── docs/
    ├── api/
    │   ├── node_openapi.yaml             # OpenAPI 3.0 spec for Node API
    │   └── python_openapi.yaml           # OpenAPI 3.0 spec for Python API
    └── architecture/
        ├── system_architecture.md        # This document
        └── data_flow_diagrams.md
```

---

## 2. PostgreSQL Relational Schema (DDL)

> **Engine:** PostgreSQL 15+ with `uuid-ossp` and `postgis` extensions.  
> **Convention:** All primary keys are UUIDs. Timestamps use `TIMESTAMPTZ`. Foreign keys enforce `ON DELETE` behaviors explicitly.

```sql
-- ============================================================
-- BARAQAH FOODPOOL — PostgreSQL DDL Script
-- Version: 1.0.0
-- Run order: Extensions → Enums → Core Tables → Join Tables
--            → Indexes → Triggers
-- ============================================================

-- ============================================================
-- EXTENSIONS
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";         -- Geospatial queries
CREATE EXTENSION IF NOT EXISTS "pg_trgm";         -- Trigram similarity for name search


-- ============================================================
-- CUSTOM ENUM TYPES
-- ============================================================

-- Lifecycle state of a dining session
CREATE TYPE session_status AS ENUM (
    'OPEN',          -- Accepting join requests
    'LOCKED',        -- Host confirmed attendees, no new requests
    'ACTIVE',        -- Check-in window is open (at venue)
    'COMPLETED',     -- All check-ins done, session over
    'CANCELLED'      -- Host or system cancelled
);

-- How a user joins the physical trip to the restaurant
CREATE TYPE transport_mode AS ENUM (
    'RIDE_TOGETHER', -- Carpool with the session host
    'MEET_THERE'     -- Self-navigate, arrive independently
);

-- The financial arrangement agreed on before the meal
CREATE TYPE split_type AS ENUM (
    'EQUAL',         -- Split evenly among all attendees
    'PERCENTAGE',    -- Custom percentages (stored in split_details JSONB)
    'HOST_PAYS',     -- Session creator covers everyone (100/0)
    'PAY_OWN'        -- Each person pays only for their own order
);

-- State machine for a single join request
CREATE TYPE request_status AS ENUM (
    'PENDING',       -- Awaiting host decision
    'ACCEPTED',      -- Host approved, user is a confirmed attendee
    'REJECTED',      -- Host declined this specific request
    'WITHDRAWN'      -- User cancelled their own request
);

-- Attendance verification result for each attendee
CREATE TYPE attendance_status AS ENUM (
    'CONFIRMED',     -- Successfully scanned the QR code at venue
    'NO_SHOW',       -- Session completed but user never scanned in
    'EXCUSED'        -- Manually excused by host (e.g. emergency)
);

-- Reputation event types that affect Baraqah Score
CREATE TYPE score_event_type AS ENUM (
    'SESSION_COMPLETED',    -- +positive: attended a session
    'HOST_COMPLETED',       -- +positive: successfully hosted a session
    'NO_SHOW',              -- -negative: confirmed but didn't attend
    'LATE_CANCELLATION',    -- -negative: cancelled < 2 hours before
    'REVIEW_RECEIVED',      -- +minor: received a positive peer review
    'VOUCHED_BY_FRIEND'     -- +bonus: a friend vouched for reliability
);


-- ============================================================
-- CORE TABLES
-- ============================================================

-- ----------------------------------------------------------
-- TABLE: users
-- The central identity table. Credential and profile data.
-- Rich preference data lives in MongoDB (UserProfile).
-- ----------------------------------------------------------
CREATE TABLE users (
    id                  UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number        VARCHAR(20)     NOT NULL UNIQUE,      -- Primary login identifier
    email               VARCHAR(255)    UNIQUE,               -- Optional, for recovery
    password_hash       TEXT            NOT NULL,
    full_name           VARCHAR(150)    NOT NULL,
    display_name        VARCHAR(80),                          -- Short nickname shown in app
    avatar_url          TEXT,                                 -- CDN URL to profile photo
    bio                 TEXT,                                 -- Short personal tagline
    baraqah_score       NUMERIC(5,2)    NOT NULL DEFAULT 50.00, -- 0.00 - 100.00 reputation score
    total_sessions      INTEGER         NOT NULL DEFAULT 0,
    total_hosted        INTEGER         NOT NULL DEFAULT 0,
    total_no_shows      INTEGER         NOT NULL DEFAULT 0,
    -- Location: stored as PostGIS geometry for geospatial queries
    last_known_location GEOMETRY(Point, 4326),
    location_updated_at TIMESTAMPTZ,
    -- Onboarding state
    is_profile_complete BOOLEAN         NOT NULL DEFAULT FALSE,
    is_phone_verified   BOOLEAN         NOT NULL DEFAULT FALSE,
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,
    -- Soft-delete support
    deleted_at          TIMESTAMPTZ     DEFAULT NULL,
    -- Audit timestamps
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- Index for geospatial "users near me" queries
CREATE INDEX idx_users_location ON users USING GIST (last_known_location);
-- Index for fast Baraqah Score leaderboard lookups
CREATE INDEX idx_users_baraqah_score ON users (baraqah_score DESC);
-- Partial index for phone lookups on active users only
CREATE UNIQUE INDEX idx_users_phone_active
    ON users (phone_number)
    WHERE deleted_at IS NULL;


-- ----------------------------------------------------------
-- TABLE: refresh_tokens
-- Server-side JWT refresh token store for token rotation.
-- ----------------------------------------------------------
CREATE TABLE refresh_tokens (
    id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash      TEXT        NOT NULL UNIQUE,  -- SHA-256 hash of the raw token
    device_info     JSONB,                        -- { "os": "iOS", "model": "iPhone 14" }
    ip_address      INET,
    is_revoked      BOOLEAN     NOT NULL DEFAULT FALSE,
    expires_at      TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens (user_id);
CREATE INDEX idx_refresh_tokens_hash ON refresh_tokens (token_hash);


-- ----------------------------------------------------------
-- TABLE: restaurants
-- Canonical restaurant data sourced from Google Places API
-- or manual entry. Acts as the reference entity for sessions.
-- ----------------------------------------------------------
CREATE TABLE restaurants (
    id                  UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- External reference IDs for deduplication
    google_place_id     VARCHAR(255) UNIQUE,
    name                VARCHAR(255) NOT NULL,
    address             TEXT        NOT NULL,
    city                VARCHAR(100) NOT NULL,
    country             VARCHAR(100) NOT NULL DEFAULT 'Pakistan',
    location            GEOMETRY(Point, 4326) NOT NULL,
    phone_number        VARCHAR(30),
    website_url         TEXT,
    cuisine_tags        TEXT[]      NOT NULL DEFAULT '{}',   -- e.g. ['Desi', 'BBQ', 'Karahi']
    price_range         SMALLINT    CHECK (price_range BETWEEN 1 AND 4), -- 1=cheap, 4=expensive
    -- Aggregated review stats (denormalized for fast display)
    avg_rating          NUMERIC(3,2) NOT NULL DEFAULT 0.00,
    verified_review_count INTEGER   NOT NULL DEFAULT 0,
    -- Operational hours stored as JSONB for flexibility
    -- e.g. { "mon": {"open":"12:00","close":"23:00"}, "sun": "closed" }
    opening_hours       JSONB,
    photo_urls          TEXT[]      DEFAULT '{}',
    is_active           BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_restaurants_location ON restaurants USING GIST (location);
CREATE INDEX idx_restaurants_cuisine ON restaurants USING GIN (cuisine_tags);
CREATE INDEX idx_restaurants_name_trgm ON restaurants USING GIN (name gin_trgm_ops);


-- ----------------------------------------------------------
-- TABLE: dining_sessions
-- The core FoodPool entity. A host creates a session which
-- other users browse and request to join.
-- ----------------------------------------------------------
CREATE TABLE dining_sessions (
    id                  UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    host_user_id        UUID            NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    restaurant_id       UUID            NOT NULL REFERENCES restaurants(id) ON DELETE RESTRICT,
    status              session_status  NOT NULL DEFAULT 'OPEN',
    -- Timing
    scheduled_at        TIMESTAMPTZ     NOT NULL,  -- When the group plans to eat
    checkin_opens_at    TIMESTAMPTZ,               -- QR check-in window opens
    checkin_closes_at   TIMESTAMPTZ,               -- QR check-in window closes (+30 min after open)
    -- Capacity and split
    max_attendees       SMALLINT        NOT NULL CHECK (max_attendees BETWEEN 2 AND 12),
    current_attendees   SMALLINT        NOT NULL DEFAULT 1, -- Host counts as 1
    food_category       TEXT            NOT NULL,           -- e.g. 'Desi', 'Chinese', 'Fast Food'
    split_type          split_type      NOT NULL DEFAULT 'EQUAL',
    -- Stores custom split ratios: [{"user_id":"...", "percentage": 50}, ...]
    split_details       JSONB           DEFAULT '[]'::JSONB,
    -- Transport carpooling
    has_ride_available  BOOLEAN         NOT NULL DEFAULT FALSE,
    available_ride_seats SMALLINT       DEFAULT 0 CHECK (available_ride_seats >= 0),
    vehicle_info        JSONB,          -- { "make": "Toyota", "color": "White", "plate": "LHR-..." }
    -- Location: where to meet (usually same as restaurant, but can differ for pickup)
    meeting_location    GEOMETRY(Point, 4326),
    meeting_note        TEXT,           -- e.g. "Meet at the main gate"
    -- Host's notes visible to potential joiners
    description         TEXT,
    -- QR Code data for check-in verification
    qr_token            UUID            UNIQUE DEFAULT uuid_generate_v4(),
    qr_generated_at     TIMESTAMPTZ,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    -- Ensure check-in window makes logical sense
    CONSTRAINT chk_checkin_window CHECK (
        checkin_closes_at IS NULL OR checkin_closes_at > checkin_opens_at
    ),
    -- Ensure scheduled time is in the future at creation
    CONSTRAINT chk_scheduled_future CHECK (scheduled_at > created_at)
);

CREATE INDEX idx_sessions_status ON dining_sessions (status);
CREATE INDEX idx_sessions_host ON dining_sessions (host_user_id);
CREATE INDEX idx_sessions_restaurant ON dining_sessions (restaurant_id);
CREATE INDEX idx_sessions_scheduled ON dining_sessions (scheduled_at);
-- Geospatial index on meeting location for "sessions near me" queries
CREATE INDEX idx_sessions_meeting_location ON dining_sessions USING GIST (meeting_location);
-- Partial index: only OPEN sessions need fast geospatial lookups
CREATE INDEX idx_sessions_open_location
    ON dining_sessions USING GIST (meeting_location)
    WHERE status = 'OPEN';


-- ----------------------------------------------------------
-- TABLE: join_requests
-- A user's formal request to join an OPEN dining session.
-- Approved requests become attendees in session_attendees.
-- ----------------------------------------------------------
CREATE TABLE join_requests (
    id              UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id      UUID            NOT NULL REFERENCES dining_sessions(id) ON DELETE CASCADE,
    requester_id    UUID            NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    transport_mode  transport_mode  NOT NULL DEFAULT 'MEET_THERE',
    message         TEXT,                       -- Optional note to the host
    status          request_status  NOT NULL DEFAULT 'PENDING',
    reviewed_at     TIMESTAMPTZ,               -- When host accepted/rejected
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    -- A user can only have one active request per session
    CONSTRAINT uq_join_request_per_session UNIQUE (session_id, requester_id)
);

CREATE INDEX idx_join_requests_session ON join_requests (session_id);
CREATE INDEX idx_join_requests_requester ON join_requests (requester_id);
CREATE INDEX idx_join_requests_status ON join_requests (status);


-- ----------------------------------------------------------
-- TABLE: session_attendees
-- Confirmed participants in a session (after join request
-- is ACCEPTED). This is the authoritative attendee list.
-- ----------------------------------------------------------
CREATE TABLE session_attendees (
    id              UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id      UUID            NOT NULL REFERENCES dining_sessions(id) ON DELETE CASCADE,
    user_id         UUID            NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    join_request_id UUID            REFERENCES join_requests(id) ON DELETE SET NULL,
    transport_mode  transport_mode  NOT NULL DEFAULT 'MEET_THERE',
    -- The attendee's agreed share of the bill (0-100, sum must = 100 for the group)
    bill_share_pct  NUMERIC(5,2)    DEFAULT NULL,
    is_host         BOOLEAN         NOT NULL DEFAULT FALSE,
    joined_at       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_attendee_per_session UNIQUE (session_id, user_id)
);

CREATE INDEX idx_attendees_session ON session_attendees (session_id);
CREATE INDEX idx_attendees_user ON session_attendees (user_id);


-- ----------------------------------------------------------
-- TABLE: attendance_logs
-- Immutable log of check-in events. Written when a user
-- scans the host's QR code at the venue.
-- ----------------------------------------------------------
CREATE TABLE attendance_logs (
    id                  UUID                PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id          UUID                NOT NULL REFERENCES dining_sessions(id) ON DELETE RESTRICT,
    attendee_user_id    UUID                NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    status              attendance_status   NOT NULL DEFAULT 'CONFIRMED',
    -- Geolocation at time of scan for fraud detection
    scan_location       GEOMETRY(Point, 4326),
    scan_device_info    JSONB,              -- { "device_id": "...", "os": "Android 13" }
    scanned_at          TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    -- Only one log entry per attendee per session
    CONSTRAINT uq_attendance_per_session UNIQUE (session_id, attendee_user_id)
);

CREATE INDEX idx_attendance_session ON attendance_logs (session_id);
CREATE INDEX idx_attendance_user ON attendance_logs (attendee_user_id);
-- Index for no-show detection query (sessions completed, no attendance log)
CREATE INDEX idx_attendance_status ON attendance_logs (status);


-- ----------------------------------------------------------
-- TABLE: baraqah_score_events
-- Immutable audit ledger of every event that changes a
-- user's Baraqah Score. Source of truth for scoring.
-- ----------------------------------------------------------
CREATE TABLE baraqah_score_events (
    id              UUID                PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID                NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_type      score_event_type    NOT NULL,
    session_id      UUID                REFERENCES dining_sessions(id) ON DELETE SET NULL,
    delta           NUMERIC(5,2)        NOT NULL,  -- Positive = gain, Negative = penalty
    score_before    NUMERIC(5,2)        NOT NULL,
    score_after     NUMERIC(5,2)        NOT NULL,
    metadata        JSONB               DEFAULT '{}',  -- Extra context for the event
    created_at      TIMESTAMPTZ         NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_score_events_user ON baraqah_score_events (user_id);
CREATE INDEX idx_score_events_type ON baraqah_score_events (event_type);
CREATE INDEX idx_score_events_session ON baraqah_score_events (session_id);


-- ----------------------------------------------------------
-- TABLE: friendships
-- Self-referential social graph. A friendship is directional
-- at creation (requester → addressee) but symmetric once
-- ACCEPTED. Enforced by CHECK constraint on IDs.
-- ----------------------------------------------------------
CREATE TABLE friendships (
    id              UUID    PRIMARY KEY DEFAULT uuid_generate_v4(),
    requester_id    UUID    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    addressee_id    UUID    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- 'PENDING' | 'ACCEPTED' | 'BLOCKED'
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                    CHECK (status IN ('PENDING', 'ACCEPTED', 'BLOCKED')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_friendship UNIQUE (requester_id, addressee_id),
    CONSTRAINT chk_no_self_friendship CHECK (requester_id <> addressee_id)
);

CREATE INDEX idx_friendships_requester ON friendships (requester_id);
CREATE INDEX idx_friendships_addressee ON friendships (addressee_id);


-- ----------------------------------------------------------
-- TABLE: user_contacts
-- Phone book contacts synced from device. Used to suggest
-- friends who are already on Baraqah.
-- ----------------------------------------------------------
CREATE TABLE user_contacts (
    id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_user_id   UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    contact_name    VARCHAR(150),
    phone_number    VARCHAR(20) NOT NULL,
    -- If this contact is a registered Baraqah user, link them
    matched_user_id UUID        REFERENCES users(id) ON DELETE SET NULL,
    synced_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_contact UNIQUE (owner_user_id, phone_number)
);

CREATE INDEX idx_contacts_owner ON user_contacts (owner_user_id);
CREATE INDEX idx_contacts_phone ON user_contacts (phone_number);


-- ----------------------------------------------------------
-- TABLE: notifications
-- Persistent notification store. Redis handles real-time
-- delivery; this table is the durable fallback for missed
-- notifications when user is offline.
-- ----------------------------------------------------------
CREATE TABLE notifications (
    id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    recipient_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- Notification types for client-side routing
    type            VARCHAR(50) NOT NULL,
    -- e.g. 'JOIN_REQUEST', 'REQUEST_ACCEPTED', 'SESSION_LOCKED',
    --      'CHECKIN_OPEN', 'NO_SHOW_PENALTY', 'REVIEW_UNLOCKED'
    title           VARCHAR(150) NOT NULL,
    body            TEXT        NOT NULL,
    -- Deep-link payload for navigation
    payload         JSONB       DEFAULT '{}',
    is_read         BOOLEAN     NOT NULL DEFAULT FALSE,
    read_at         TIMESTAMPTZ,
    -- Reference to the relevant entity
    session_id      UUID        REFERENCES dining_sessions(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_recipient ON notifications (recipient_id, is_read);
CREATE INDEX idx_notifications_created ON notifications (created_at DESC);


-- ============================================================
-- DATABASE TRIGGERS
-- ============================================================

-- ----------------------------------------------------------
-- TRIGGER: Auto-update updated_at timestamps
-- Applied to every table that has an updated_at column.
-- ----------------------------------------------------------
CREATE OR REPLACE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to tables with updated_at
DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'users', 'dining_sessions', 'join_requests',
        'session_attendees', 'friendships'
    ]
    LOOP
        EXECUTE FORMAT(
            'CREATE TRIGGER trg_%s_updated_at
             BEFORE UPDATE ON %s
             FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();',
            t, t
        );
    END LOOP;
END $$;


-- ----------------------------------------------------------
-- TRIGGER: Increment/decrement current_attendees on session
-- when a session_attendees row is inserted or deleted.
-- ----------------------------------------------------------
CREATE OR REPLACE FUNCTION trigger_sync_attendee_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE dining_sessions
        SET current_attendees = current_attendees + 1
        WHERE id = NEW.session_id;

    ELSIF TG_OP = 'DELETE' THEN
        UPDATE dining_sessions
        SET current_attendees = GREATEST(0, current_attendees - 1)
        WHERE id = OLD.session_id;
    END IF;

    RETURN NULL; -- AFTER trigger, return value ignored
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_attendee_count
AFTER INSERT OR DELETE ON session_attendees
FOR EACH ROW EXECUTE FUNCTION trigger_sync_attendee_count();


-- ----------------------------------------------------------
-- TRIGGER: Auto-lock session when attendee capacity is full
-- ----------------------------------------------------------
CREATE OR REPLACE FUNCTION trigger_auto_lock_session()
RETURNS TRIGGER AS $$
BEGIN
    -- After insertion, check if session is now full
    IF TG_OP = 'INSERT' THEN
        UPDATE dining_sessions
        SET status = 'LOCKED'
        WHERE id = NEW.session_id
          AND current_attendees >= max_attendees
          AND status = 'OPEN';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_lock_session
AFTER INSERT ON session_attendees
FOR EACH ROW EXECUTE FUNCTION trigger_auto_lock_session();


-- ----------------------------------------------------------
-- TRIGGER: Update user aggregate stats when attendance is logged
-- ----------------------------------------------------------
CREATE OR REPLACE FUNCTION trigger_update_user_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'CONFIRMED' THEN
        UPDATE users
        SET total_sessions = total_sessions + 1
        WHERE id = NEW.attendee_user_id;

    ELSIF NEW.status = 'NO_SHOW' THEN
        UPDATE users
        SET total_no_shows = total_no_shows + 1
        WHERE id = NEW.attendee_user_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_user_stats
AFTER INSERT ON attendance_logs
FOR EACH ROW EXECUTE FUNCTION trigger_update_user_stats();
```

---

## 3. MongoDB Document Schemas

> **Engine:** MongoDB 7.0+ with Mongoose 8.x.  
> **Strategy:** Documents here are deliberately schema-flexible — they store data that evolves with user behavior or doesn't fit a rigid relational model. The `userId` field always mirrors `users.id` from PostgreSQL as the cross-database join key.

### 3.1 — `userprofiles` Collection

Stores rich, evolving preference data and social metadata. The `preference_vector` powers the Python matching algorithm.

```json
{
  "$jsonSchema": {
    "bsonType": "object",
    "title": "UserProfile",
    "description": "Rich preference and social context data for a Baraqah user.",
    "required": ["userId", "createdAt"],
    "properties": {

      "_id": {
        "bsonType": "objectId",
        "description": "MongoDB internal document ID."
      },

      "userId": {
        "bsonType": "string",
        "description": "UUID from PostgreSQL users.id — the cross-database join key. Always indexed."
      },

      "preference_vector": {
        "bsonType": "object",
        "description": "Numerical and categorical features for the matching algorithm. Updated incrementally after each session.",
        "properties": {

          "cuisine_weights": {
            "bsonType": "object",
            "description": "Map of cuisine tag to preference weight (0.0 to 1.0). e.g. { 'Desi': 0.9, 'Chinese': 0.5 }",
            "additionalProperties": { "bsonType": "double" }
          },

          "price_range_preference": {
            "bsonType": "int",
            "minimum": 1,
            "maximum": 4,
            "description": "Preferred restaurant price tier."
          },

          "preferred_group_size": {
            "bsonType": "object",
            "properties": {
              "min": { "bsonType": "int" },
              "max": { "bsonType": "int" }
            }
          },

          "preferred_meal_times": {
            "bsonType": "array",
            "description": "List of preferred dining time windows.",
            "items": {
              "bsonType": "object",
              "properties": {
                "day_of_week": { "bsonType": "string", "enum": ["MON","TUE","WED","THU","FRI","SAT","SUN"] },
                "start_hour":  { "bsonType": "int", "minimum": 0, "maximum": 23 },
                "end_hour":    { "bsonType": "int", "minimum": 0, "maximum": 23 }
              }
            }
          },

          "transport_preference": {
            "bsonType": "string",
            "enum": ["RIDE_TOGETHER", "MEET_THERE", "NO_PREFERENCE"]
          },

          "social_comfort_level": {
            "bsonType": "double",
            "minimum": 0.0,
            "maximum": 1.0,
            "description": "Derived metric: comfort dining with strangers vs. friends-only. 0=strangers OK, 1=friends only."
          },

          "dietary_restrictions": {
            "bsonType": "array",
            "items": { "bsonType": "string" },
            "description": "e.g. ['Halal Only', 'No Beef', 'Vegetarian']"
          },

          "avg_session_rating_given": {
            "bsonType": "double",
            "description": "Rolling average of ratings this user gives to others — indicates generosity/strictness."
          }
        }
      },

      "session_history_summary": {
        "bsonType": "object",
        "description": "Lightweight embedded summary for quick profile display. Full history is in PostgreSQL.",
        "properties": {
          "favorite_restaurants": {
            "bsonType": "array",
            "description": "Top 3 most visited restaurant IDs (PostgreSQL UUIDs).",
            "items": { "bsonType": "string" },
            "maxItems": 3
          },
          "favorite_cuisines": {
            "bsonType": "array",
            "items": { "bsonType": "string" },
            "maxItems": 5
          },
          "frequent_dining_partners": {
            "bsonType": "array",
            "description": "User IDs (PostgreSQL UUIDs) most frequently dined with.",
            "items": { "bsonType": "string" },
            "maxItems": 10
          }
        }
      },

      "device_tokens": {
        "bsonType": "array",
        "description": "FCM/APNs push notification tokens. Array to support multi-device.",
        "items": {
          "bsonType": "object",
          "required": ["token", "platform"],
          "properties": {
            "token":      { "bsonType": "string" },
            "platform":   { "bsonType": "string", "enum": ["android", "ios"] },
            "added_at":   { "bsonType": "date" },
            "is_active":  { "bsonType": "bool" }
          }
        }
      },

      "privacy_settings": {
        "bsonType": "object",
        "properties": {
          "show_location_to":    { "bsonType": "string", "enum": ["EVERYONE", "FRIENDS", "NOBODY"] },
          "show_score_to":       { "bsonType": "string", "enum": ["EVERYONE", "FRIENDS", "NOBODY"] },
          "allow_contact_sync":  { "bsonType": "bool" }
        }
      },

      "createdAt":  { "bsonType": "date" },
      "updatedAt":  { "bsonType": "date" }
    }
  }
}
```

**Mongoose Indexes:**
```javascript
// Unique index — one profile document per PostgreSQL user
userProfileSchema.index({ userId: 1 }, { unique: true });

// For cuisine-based matching queries
userProfileSchema.index({ "preference_vector.cuisine_weights": 1 });

// For finding users by dietary restriction
userProfileSchema.index({ "preference_vector.dietary_restrictions": 1 });
```

---

### 3.2 — `reviews` Collection

Stores rich, structured review objects. Only written after a verified multi-person QR check-in. The schema is flexible to allow evolving review dimensions without schema migrations.

```json
{
  "$jsonSchema": {
    "bsonType": "object",
    "title": "Review",
    "description": "A verified, multi-party restaurant review. Can only be created post QR check-in.",
    "required": ["sessionId", "restaurantId", "authorId", "ratings", "isVerified", "createdAt"],
    "properties": {

      "_id": { "bsonType": "objectId" },

      "sessionId": {
        "bsonType": "string",
        "description": "UUID of the PostgreSQL dining_sessions row that unlocked this review."
      },

      "restaurantId": {
        "bsonType": "string",
        "description": "UUID of the PostgreSQL restaurants row being reviewed."
      },

      "authorId": {
        "bsonType": "string",
        "description": "UUID of the PostgreSQL user who wrote this review."
      },

      "isVerified": {
        "bsonType": "bool",
        "description": "Always TRUE — set by the backend at creation after QR check-in validation. Never client-set."
      },

      "attendee_count": {
        "bsonType": "int",
        "description": "Number of people who checked in during the session. Higher count = more trustworthy review."
      },

      "ratings": {
        "bsonType": "object",
        "description": "Multi-dimensional rating breakdown.",
        "required": ["overall"],
        "properties": {
          "overall":      { "bsonType": "double", "minimum": 1.0, "maximum": 5.0 },
          "food_quality": { "bsonType": "double", "minimum": 1.0, "maximum": 5.0 },
          "value":        { "bsonType": "double", "minimum": 1.0, "maximum": 5.0 },
          "service":      { "bsonType": "double", "minimum": 1.0, "maximum": 5.0 },
          "ambiance":     { "bsonType": "double", "minimum": 1.0, "maximum": 5.0 },
          "group_friendliness": {
            "bsonType": "double", "minimum": 1.0, "maximum": 5.0,
            "description": "How suitable is this restaurant for group dining?"
          }
        }
      },

      "review_text": {
        "bsonType": "string",
        "maxLength": 1500,
        "description": "Written review body. Optional."
      },

      "tags": {
        "bsonType": "array",
        "description": "Quick-select descriptive tags. e.g. ['Must try biryani', 'Noisy but fun', 'Great naans']",
        "items": { "bsonType": "string" },
        "maxItems": 8
      },

      "media": {
        "bsonType": "array",
        "description": "Photos or short videos attached to the review.",
        "items": {
          "bsonType": "object",
          "required": ["url", "type"],
          "properties": {
            "url":        { "bsonType": "string" },
            "type":       { "bsonType": "string", "enum": ["image", "video"] },
            "caption":    { "bsonType": "string" },
            "uploaded_at":{ "bsonType": "date" }
          }
        },
        "maxItems": 6
      },

      "dishes_ordered": {
        "bsonType": "array",
        "description": "Dishes the author ordered — used for menu-level recommendation features later.",
        "items": {
          "bsonType": "object",
          "properties": {
            "name":       { "bsonType": "string" },
            "rating":     { "bsonType": "double", "minimum": 1.0, "maximum": 5.0 },
            "is_recommended": { "bsonType": "bool" }
          }
        }
      },

      "helpful_votes": {
        "bsonType": "int",
        "description": "Count of 'helpful' upvotes from other users. Denormalized counter.",
        "minimum": 0
      },

      "moderation": {
        "bsonType": "object",
        "description": "Content moderation metadata. Populated by the Python service's text analysis.",
        "properties": {
          "status":           { "bsonType": "string", "enum": ["PENDING", "APPROVED", "FLAGGED", "REMOVED"] },
          "flagged_reason":   { "bsonType": "string" },
          "reviewed_by":      { "bsonType": "string" },
          "reviewed_at":      { "bsonType": "date" }
        }
      },

      "createdAt":  { "bsonType": "date" },
      "updatedAt":  { "bsonType": "date" }
    }
  }
}
```

**Mongoose Indexes:**
```javascript
// Primary lookup: all verified reviews for a restaurant
reviewSchema.index({ restaurantId: 1, isVerified: 1, createdAt: -1 });

// Ensure one review per author per session (prevents duplicate submission)
reviewSchema.index({ sessionId: 1, authorId: 1 }, { unique: true });

// For author's review history
reviewSchema.index({ authorId: 1, createdAt: -1 });

// For moderation queue
reviewSchema.index({ "moderation.status": 1, createdAt: 1 });
```

---

### 3.3 — `groupchats` Collection

Stores the chat history for each dining session. Messages are embedded as an array for fast retrieval of recent chat. Older messages can be archived to cold storage.

```json
{
  "$jsonSchema": {
    "bsonType": "object",
    "title": "GroupChat",
    "description": "Chat history for a single FoodPool dining session.",
    "required": ["sessionId", "messages"],
    "properties": {

      "_id": { "bsonType": "objectId" },

      "sessionId": {
        "bsonType": "string",
        "description": "UUID from PostgreSQL dining_sessions.id — foreign key."
      },

      "participant_ids": {
        "bsonType": "array",
        "description": "User IDs (PostgreSQL UUIDs) of all chat participants. Denormalized for quick permission checks.",
        "items": { "bsonType": "string" }
      },

      "messages": {
        "bsonType": "array",
        "description": "Embedded message log. Capped at 500 messages per document before overflow document is created.",
        "items": {
          "bsonType": "object",
          "required": ["messageId", "senderId", "type", "sentAt"],
          "properties": {
            "messageId":    { "bsonType": "objectId" },
            "senderId":     { "bsonType": "string" },
            "type":         { "bsonType": "string", "enum": ["TEXT", "IMAGE", "SYSTEM", "LOCATION_SHARE"] },
            "content":      { "bsonType": "string", "description": "Text body or media URL." },
            "metadata":     {
              "bsonType": "object",
              "description": "Type-specific extra data. e.g. { 'lat': 31.5, 'lng': 74.3 } for LOCATION_SHARE."
            },
            "is_deleted":   { "bsonType": "bool" },
            "sentAt":       { "bsonType": "date" },
            "read_by":      {
              "bsonType": "array",
              "items": {
                "bsonType": "object",
                "properties": {
                  "userId":   { "bsonType": "string" },
                  "readAt":   { "bsonType": "date" }
                }
              }
            }
          }
        }
      },

      "is_archived":  { "bsonType": "bool" },
      "createdAt":    { "bsonType": "date" },
      "updatedAt":    { "bsonType": "date" }
    }
  }
}
```

**Mongoose Indexes:**
```javascript
// Primary lookup: chat for a specific session
groupChatSchema.index({ sessionId: 1 }, { unique: true });

// For participant permission checks
groupChatSchema.index({ participant_ids: 1 });
```

---

## 4. Redis Key-Value Mapping Architecture

> **Client:** ioredis (Node.js), aioredis (Python).  
> **Strategy:** All keys are namespaced with `baraqah:` prefix. TTLs are enforced on every ephemeral key. Permanent keys must be justified.

### 4.1 — Key Namespace Conventions

```
baraqah:{domain}:{entity_id}:{sub_key}
```

---

### 4.2 — Authentication & Session Tokens

| Key Pattern | Type | TTL | Value | Purpose |
|---|---|---|---|---|
| `baraqah:auth:access_token:{user_id}:{jti}` | String | 15 min | `"valid"` | Allowlist for issued access tokens — enables instant revocation |
| `baraqah:auth:otp:{phone_number}` | String | 5 min | `"123456"` | Phone OTP for registration/login. Deleted after verification |
| `baraqah:auth:otp_attempts:{phone_number}` | String | 15 min | `"3"` | OTP brute-force counter — max 5 attempts before lockout |
| `baraqah:auth:rate:{ip_address}` | String | 1 min | `"12"` | API rate limit counter per IP per minute |

---

### 4.3 — Active Dining Sessions (Real-Time State)

| Key Pattern | Type | TTL | Value | Purpose |
|---|---|---|---|---|
| `baraqah:session:state:{session_id}` | Hash | 4 hours | `{ status, current_attendees, checkin_opens_at, qr_token }` | Hot copy of session state for real-time display without DB hits |
| `baraqah:session:attendees:{session_id}` | Set | 4 hours | `{ user_id_1, user_id_2, ... }` | Fast O(1) membership check: "is this user in this session?" |
| `baraqah:session:pending_requests:{session_id}` | Sorted Set | 4 hours | `user_id` → `UNIX timestamp` | Pending join requests ordered by submission time |
| `baraqah:session:ride_seats:{session_id}` | String | 4 hours | `"2"` | Available carpool seats counter (INCR/DECR atomically) |
| `baraqah:sessions:active:geo` | Geo | None (managed) | `longitude latitude session_id` | Redis GEO set for "sessions near me" queries via GEORADIUS |

---

### 4.4 — QR Check-In Flow

| Key Pattern | Type | TTL | Value | Purpose |
|---|---|---|---|---|
| `baraqah:checkin:qr:{qr_token}` | Hash | 90 min | `{ session_id, valid_from, valid_until, checkin_count }` | Validates QR scans. Generated when host opens check-in |
| `baraqah:checkin:scanned:{session_id}` | Set | 2 hours | `{ user_id_1, user_id_2, ... }` | Users who have already scanned — prevents double scan |
| `baraqah:checkin:geo_lock:{session_id}` | String | 90 min | `"31.5204,74.3587:200"` | `lat,lng:radius_meters` — geofence for valid check-in location |

---

### 4.5 — User Location & Presence

| Key Pattern | Type | TTL | Value | Purpose |
|---|---|---|---|---|
| `baraqah:user:location:{user_id}` | Hash | 10 min | `{ lat, lng, accuracy, updated_at }` | Last known location. Refreshed on movement, expires when app closes |
| `baraqah:user:online:{user_id}` | String | 30 sec | `"socket_id"` | Presence indicator. Heartbeat-renewed by Socket.IO connection |
| `baraqah:user:socket:{user_id}` | String | 30 min | `"socket_id_abc"` | Maps user to their active Socket.IO connection ID |

---

### 4.6 — Notification Queue

| Key Pattern | Type | TTL | Value | Purpose |
|---|---|---|---|---|
| `baraqah:notifications:unread:{user_id}` | String | 7 days | `"5"` | Unread count badge shown on app icon. Decremented when opened |
| `baraqah:notifications:push_queue` | List | None | `JSON payload` | LPUSH/BRPOP worker queue for FCM/APNs push delivery |
| `baraqah:notifications:failed:{user_id}` | List | 24 hours | `JSON payload` | Failed push deliveries for retry — max 3 attempts |

---

### 4.7 — Matching & Scoring Cache

| Key Pattern | Type | TTL | Value | Purpose |
|---|---|---|---|---|
| `baraqah:match:results:{user_id}:{geohash}` | String | 5 min | `JSON array of session_ids` | Cached matching results from Python service. Keyed by location geohash for locality |
| `baraqah:score:cache:{user_id}` | Hash | 15 min | `{ score, rank, last_calculated_at }` | Cached Baraqah Score output from Python service — reduces load on scoring engine |
| `baraqah:score:leaderboard` | Sorted Set | None | `user_id` → `score` | Global leaderboard. Updated by Python service after score recalculation |
| `baraqah:score:leaderboard:city:{city_name}` | Sorted Set | None | `user_id` → `score` | City-scoped leaderboard for locality |

---

### 4.8 — Pub/Sub Channels (Socket.IO Events via Redis Adapter)

| Channel | Publisher | Subscribers | Event Payload |
|---|---|---|---|
| `baraqah:pubsub:session:{session_id}` | Node.js | All session attendees | `{ event: 'JOIN_REQUEST', data: {...} }` |
| `baraqah:pubsub:user:{user_id}` | Node.js / Python | The specific user's socket | `{ event: 'SCORE_UPDATED', data: {...} }` |
| `baraqah:pubsub:checkin:{session_id}` | Node.js | All session attendees | `{ event: 'ATTENDEE_CHECKED_IN', data: {...} }` |
| `baraqah:pubsub:system` | Node.js | All connected sockets | `{ event: 'MAINTENANCE_NOTICE', data: {...} }` |

---

## 5. Cross-Database Relationship Map

```
PostgreSQL (Source of Truth)          MongoDB                Redis
────────────────────────────          ─────────────────      ─────────────────────
users.id ─────────────────────────►  userprofiles.userId    baraqah:user:*:{user_id}
users.id ─────────────────────────►  reviews.authorId
users.id ─────────────────────────►  groupchats.participant_ids[]

dining_sessions.id ───────────────►  reviews.sessionId      baraqah:session:*:{session_id}
dining_sessions.id ───────────────►  groupchats.sessionId   baraqah:checkin:*:{session_id}
dining_sessions.qr_token ─────────────────────────────────► baraqah:checkin:qr:{qr_token}

restaurants.id ────────────────────► reviews.restaurantId

attendance_logs ──► triggers ──► users.baraqah_score ──────► baraqah:score:cache:{user_id}
                                                    ──────► baraqah:score:leaderboard (ZADD)
```

**Join strategy in Node.js services:** When a response needs data spanning databases (e.g., session detail with chat preview), the service layer makes parallel async calls — one to PostgreSQL for the session/attendee data, one to MongoDB for the chat tail, and one to Redis for real-time state — then merges at the service layer before sending the API response.

---

## 6. Design Rationale Notes

**Why no payment processing in PostgreSQL?** By design decision. Baraqah's philosophy eliminates in-app financial flow. The `split_details` JSONB column in `dining_sessions` records the *agreed* split for social accountability and bill calculation display only — no actual monetary transactions are stored or processed.

**Why UUIDs over serial integers?** UUIDs prevent enumeration attacks on session/user IDs in API routes, allow offline ID generation for the Flutter app, and facilitate future database sharding.

**Why PostGIS over application-layer geo calculations?** `GEORADIUS` queries ("sessions within 5km") are 10-100x faster at the database level with spatial indexing versus pulling records and filtering in Node.js. The Python matching service also uses the PostGIS output as input features.

**Why embedding messages in MongoDB instead of a messages collection?** For a chat with <500 messages, a single document fetch is one round-trip. A separate collection query requires an index lookup + document fetch. The 500-message overflow threshold is enforced in `groupchats.service.js` with a new overflow document created when exceeded.

**Why Redis GEO for active sessions instead of PostGIS?** Redis GEO is appropriate for volatile, real-time data (sessions that open/close rapidly). PostGIS `idx_sessions_open_location` handles durable queries. The Redis GEO set is the primary lookup for the browse map and expires with the session; PostGIS is the audit-grade record.

**Baraqah Score precision:** `NUMERIC(5,2)` allows scores from 0.00 to 999.99. With a design range of 0–100, this gives two decimal places of precision for smooth scoring transitions and ties in leaderboards.
```

---

**Document Complete.** This architecture is ready for implementation Phase 2: Backend Route Generation (Node.js modules) and the Python FastAPI matching algorithm.
