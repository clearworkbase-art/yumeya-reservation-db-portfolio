-- Run only in the dedicated demo database; creates and removes sample rows in a transaction.
-- The second overlapping INSERT must fail with SQLSTATE 23P01.
-- For an easy single-session demonstration, run each INSERT separately in pgAdmin.
-- Use an empty date range in the future with no real demo data.
BEGIN;
INSERT INTO reservations (room_code, check_in, check_out, guests)
VALUES ('MATSU', '2030-03-10', '2030-03-12', 2);
-- Expect ERROR: conflicting key value violates exclusion constraint.
INSERT INTO reservations (room_code, check_in, check_out, guests)
VALUES ('MATSU', '2030-03-11', '2030-03-13', 2);
ROLLBACK;
-- Note: after a constraint error the transaction is aborted until ROLLBACK.
