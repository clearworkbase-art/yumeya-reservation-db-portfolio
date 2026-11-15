-- Execute in psql or pgAdmin Query Tool after schema creation.
-- 1. JOIN: reservation list with room names.
SELECT r.reservation_id, m.room_name, r.check_in, r.check_out, r.guests, r.status
FROM reservations r JOIN rooms m ON m.room_code = r.room_code
ORDER BY r.created_at DESC, r.reservation_id DESC LIMIT 20;

-- 2. Report by room and status.
SELECT m.room_name, r.status, COUNT(*) AS reservation_count
FROM rooms m LEFT JOIN reservations r ON r.room_code = m.room_code
GROUP BY m.room_name, r.status ORDER BY m.room_name, r.status;

-- 3. Current confirmed booking interval search. Use dates of your choice.
SELECT reservation_id, room_code, check_in, check_out
FROM reservations
WHERE room_code = 'MATSU' AND status = 'CONFIRMED'
  AND daterange(check_in, check_out, '[)') && daterange('2026-11-19', '2026-11-21', '[)');

-- 4. Review actual planning details (results vary with row counts).
EXPLAIN (ANALYZE, BUFFERS)
SELECT reservation_id, room_code, check_in FROM reservations
WHERE room_code = 'MATSU' AND status = 'CONFIRMED'
ORDER BY created_at DESC LIMIT 100;
