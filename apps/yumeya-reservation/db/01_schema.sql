-- Demo-only PostgreSQL schema: run in a dedicated local database.
-- The excluded overlap includes [check_in, check_out): same-day checkout/checkin is allowed.
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE IF NOT EXISTS rooms (
    room_code varchar(8) PRIMARY KEY,
    room_name varchar(40) NOT NULL UNIQUE,
    capacity integer NOT NULL CHECK (capacity BETWEEN 1 AND 4)
);

CREATE TABLE IF NOT EXISTS reservations (
    reservation_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    room_code varchar(8) NOT NULL REFERENCES rooms(room_code),
    check_in date NOT NULL,
    check_out date NOT NULL,
    guests integer NOT NULL CHECK (guests BETWEEN 1 AND 4),
    status varchar(12) NOT NULL DEFAULT 'CONFIRMED' CHECK (status IN ('CONFIRMED','CANCELLED')),
    created_at timestamptz NOT NULL DEFAULT now(),
    cancelled_at timestamptz,
    CONSTRAINT valid_stay_dates CHECK (check_out > check_in AND check_out <= check_in + 14),
    CONSTRAINT cancellation_status_consistency CHECK (
        (status='CONFIRMED' AND cancelled_at IS NULL) OR
        (status='CANCELLED' AND cancelled_at IS NOT NULL)
    ),
    CONSTRAINT no_overlapping_active_reservations EXCLUDE USING gist (
        room_code WITH =,
        daterange(check_in, check_out, '[)') WITH &&
    ) WHERE (status='CONFIRMED')
);

INSERT INTO rooms (room_code, room_name, capacity) VALUES
  ('MATSU', '桂松の間', 4),
  ('TAKE', '梧竹の間', 4),
  ('UME', '梅響の間', 4)
ON CONFLICT (room_code) DO NOTHING;

CREATE INDEX IF NOT EXISTS idx_reservations_created ON reservations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reservations_room_status ON reservations(room_code, status);
