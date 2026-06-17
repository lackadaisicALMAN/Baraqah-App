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
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";


-- ============================================================
-- CUSTOM ENUM TYPES
-- ============================================================

CREATE TYPE session_status AS ENUM (
    'OPEN',
    'LOCKED',
    'ACTIVE',
    'COMPLETED',
    'CANCELLED'
);

CREATE TYPE transport_mode AS ENUM (
    'RIDE_TOGETHER',
    'MEET_THERE'
);

CREATE TYPE split_type AS ENUM (
    'EQUAL',
    'PERCENTAGE',
    'HOST_PAYS',
    'PAY_OWN'
);

CREATE TYPE request_status AS ENUM (
    'PENDING',
    'ACCEPTED',
    'REJECTED',
    'WITHDRAWN'
);

CREATE TYPE attendance_status AS ENUM (
    'CONFIRMED',
    'NO_SHOW',
    'EXCUSED'
);

CREATE TYPE score_event_type AS ENUM (
    'SESSION_COMPLETED',
    'HOST_COMPLETED',
    'NO_SHOW',
    'LATE_CANCELLATION',
    'REVIEW_RECEIVED',
    'VOUCHED_BY_FRIEND'
);


-- ============================================================
-- CORE TABLES
-- ============================================================

CREATE TABLE users (
    id                  UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number        VARCHAR(20)     NOT NULL UNIQUE,
    email               VARCHAR(255)    UNIQUE,
    password_hash       TEXT            NOT NULL,
    full_name           VARCHAR(150)    NOT NULL,
    display_name        VARCHAR(80),
    avatar_url          TEXT,
    bio                 TEXT,
    baraqah_score       NUMERIC(5,2)    NOT NULL DEFAULT 5.00 CHECK (baraqah_score >= 0.00 AND baraqah_score <= 7.00),
    total_sessions      INTEGER         NOT NULL DEFAULT 0,
    total_hosted        INTEGER         NOT NULL DEFAULT 0,
    total_no_shows      INTEGER         NOT NULL DEFAULT 0,
    last_known_location GEOMETRY(Point, 4326),
    location_updated_at TIMESTAMPTZ,
    is_profile_complete BOOLEAN         NOT NULL DEFAULT FALSE,
    is_phone_verified   BOOLEAN         NOT NULL DEFAULT FALSE,
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,
    deleted_at          TIMESTAMPTZ     DEFAULT NULL,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_location ON users USING GIST (last_known_location);
CREATE INDEX idx_users_baraqah_score ON users (baraqah_score DESC);
CREATE UNIQUE INDEX idx_users_phone_active
    ON users (phone_number)
    WHERE deleted_at IS NULL;


CREATE TABLE refresh_tokens (
    id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash      TEXT        NOT NULL UNIQUE,
    device_info     JSONB,
    ip_address      INET,
    is_revoked      BOOLEAN     NOT NULL DEFAULT FALSE,
    expires_at      TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens (user_id);
CREATE INDEX idx_refresh_tokens_hash ON refresh_tokens (token_hash);


CREATE TABLE restaurants (
    id                  UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    google_place_id     VARCHAR(255) UNIQUE,
    name                VARCHAR(255) NOT NULL,
    address             TEXT        NOT NULL,
    city                VARCHAR(100) NOT NULL,
    country             VARCHAR(100) NOT NULL DEFAULT 'Pakistan',
    location            GEOMETRY(Point, 4326) NOT NULL,
    phone_number        VARCHAR(30),
    website_url         TEXT,
    cuisine_tags        TEXT[]      NOT NULL DEFAULT '{}',
    price_range         SMALLINT    CHECK (price_range BETWEEN 1 AND 4),
    avg_rating          NUMERIC(3,2) NOT NULL DEFAULT 0.00,
    verified_review_count INTEGER   NOT NULL DEFAULT 0,
    opening_hours       JSONB,
    photo_urls          TEXT[]      DEFAULT '{}',
    is_active           BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_restaurants_location ON restaurants USING GIST (location);
CREATE INDEX idx_restaurants_cuisine ON restaurants USING GIN (cuisine_tags);
CREATE INDEX idx_restaurants_name_trgm ON restaurants USING GIN (name gin_trgm_ops);


CREATE TABLE dining_sessions (
    id                  UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    host_user_id        UUID            NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    restaurant_id       UUID            NOT NULL REFERENCES restaurants(id) ON DELETE RESTRICT,
    status              session_status  NOT NULL DEFAULT 'OPEN',
    scheduled_at        TIMESTAMPTZ     NOT NULL,
    checkin_opens_at    TIMESTAMPTZ,
    checkin_closes_at   TIMESTAMPTZ,
    max_attendees       SMALLINT        NOT NULL CHECK (max_attendees BETWEEN 2 AND 12),
    current_attendees   SMALLINT        NOT NULL DEFAULT 1,
    food_category       TEXT            NOT NULL,
    split_type          split_type      NOT NULL DEFAULT 'EQUAL',
    split_details       JSONB           DEFAULT '[]'::JSONB,
    has_ride_available  BOOLEAN         NOT NULL DEFAULT FALSE,
    available_ride_seats SMALLINT       DEFAULT 0 CHECK (available_ride_seats >= 0),
    vehicle_info        JSONB,
    meeting_location    GEOMETRY(Point, 4326),
    meeting_note        TEXT,
    description         TEXT,
    qr_token            UUID            UNIQUE DEFAULT uuid_generate_v4(),
    qr_generated_at     TIMESTAMPTZ,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_checkin_window CHECK (
        checkin_closes_at IS NULL OR checkin_closes_at > checkin_opens_at
    ),
    CONSTRAINT chk_scheduled_future CHECK (scheduled_at > created_at)
);

CREATE INDEX idx_sessions_status ON dining_sessions (status);
CREATE INDEX idx_sessions_host ON dining_sessions (host_user_id);
CREATE INDEX idx_sessions_restaurant ON dining_sessions (restaurant_id);
CREATE INDEX idx_sessions_scheduled ON dining_sessions (scheduled_at);
CREATE INDEX idx_sessions_meeting_location ON dining_sessions USING GIST (meeting_location);
CREATE INDEX idx_sessions_open_location
    ON dining_sessions USING GIST (meeting_location)
    WHERE status = 'OPEN';


CREATE TABLE join_requests (
    id              UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id      UUID            NOT NULL REFERENCES dining_sessions(id) ON DELETE CASCADE,
    requester_id    UUID            NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    transport_mode  transport_mode  NOT NULL DEFAULT 'MEET_THERE',
    message         TEXT,
    status          request_status  NOT NULL DEFAULT 'PENDING',
    reviewed_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_join_request_per_session UNIQUE (session_id, requester_id)
);

CREATE INDEX idx_join_requests_session ON join_requests (session_id);
CREATE INDEX idx_join_requests_requester ON join_requests (requester_id);
CREATE INDEX idx_join_requests_status ON join_requests (status);


CREATE TABLE session_attendees (
    id              UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id      UUID            NOT NULL REFERENCES dining_sessions(id) ON DELETE CASCADE,
    user_id         UUID            NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    join_request_id UUID            REFERENCES join_requests(id) ON DELETE SET NULL,
    transport_mode  transport_mode  NOT NULL DEFAULT 'MEET_THERE',
    bill_share_pct  NUMERIC(5,2)    DEFAULT NULL,
    is_host         BOOLEAN         NOT NULL DEFAULT FALSE,
    joined_at       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_attendee_per_session UNIQUE (session_id, user_id)
);

CREATE INDEX idx_attendees_session ON session_attendees (session_id);
CREATE INDEX idx_attendees_user ON session_attendees (user_id);


CREATE TABLE attendance_logs (
    id                  UUID                PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id          UUID                NOT NULL REFERENCES dining_sessions(id) ON DELETE RESTRICT,
    attendee_user_id    UUID                NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    status              attendance_status   NOT NULL DEFAULT 'CONFIRMED',
    scan_location       GEOMETRY(Point, 4326),
    scan_device_info    JSONB,
    scanned_at          TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_attendance_per_session UNIQUE (session_id, attendee_user_id)
);

CREATE INDEX idx_attendance_session ON attendance_logs (session_id);
CREATE INDEX idx_attendance_user ON attendance_logs (attendee_user_id);
CREATE INDEX idx_attendance_status ON attendance_logs (status);


CREATE TABLE baraqah_score_events (
    id              UUID                PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID                NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_type      score_event_type    NOT NULL,
    session_id      UUID                REFERENCES dining_sessions(id) ON DELETE SET NULL,
    delta           NUMERIC(5,2)        NOT NULL,
    score_before    NUMERIC(5,2)        NOT NULL,
    score_after     NUMERIC(5,2)        NOT NULL,
    metadata        JSONB               DEFAULT '{}',
    created_at      TIMESTAMPTZ         NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_score_events_user ON baraqah_score_events (user_id);
CREATE INDEX idx_score_events_type ON baraqah_score_events (event_type);
CREATE INDEX idx_score_events_session ON baraqah_score_events (session_id);


CREATE TABLE friendships (
    id              UUID    PRIMARY KEY DEFAULT uuid_generate_v4(),
    requester_id    UUID    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    addressee_id    UUID    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                    CHECK (status IN ('PENDING', 'ACCEPTED', 'BLOCKED')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_friendship UNIQUE (requester_id, addressee_id),
    CONSTRAINT chk_no_self_friendship CHECK (requester_id <> addressee_id)
);

CREATE INDEX idx_friendships_requester ON friendships (requester_id);
CREATE INDEX idx_friendships_addressee ON friendships (addressee_id);


CREATE TABLE user_contacts (
    id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_user_id   UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    contact_name    VARCHAR(150),
    phone_number    VARCHAR(20) NOT NULL,
    matched_user_id UUID        REFERENCES users(id) ON DELETE SET NULL,
    synced_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_contact UNIQUE (owner_user_id, phone_number)
);

CREATE INDEX idx_contacts_owner ON user_contacts (owner_user_id);
CREATE INDEX idx_contacts_phone ON user_contacts (phone_number);


CREATE TABLE notifications (
    id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    recipient_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type            VARCHAR(50) NOT NULL,
    title           VARCHAR(150) NOT NULL,
    body            TEXT        NOT NULL,
    payload         JSONB       DEFAULT '{}',
    is_read         BOOLEAN     NOT NULL DEFAULT FALSE,
    read_at         TIMESTAMPTZ,
    session_id      UUID        REFERENCES dining_sessions(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_recipient ON notifications (recipient_id, is_read);
CREATE INDEX idx_notifications_created ON notifications (created_at DESC);


-- ============================================================
-- DATABASE TRIGGERS
-- ============================================================

CREATE OR REPLACE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

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

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_attendee_count
AFTER INSERT OR DELETE ON session_attendees
FOR EACH ROW EXECUTE FUNCTION trigger_sync_attendee_count();


CREATE OR REPLACE FUNCTION trigger_auto_lock_session()
RETURNS TRIGGER AS $$
BEGIN
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
