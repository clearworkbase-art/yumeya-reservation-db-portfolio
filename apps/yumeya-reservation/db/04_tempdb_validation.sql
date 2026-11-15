-- v2追加検証: 専用の一時DBで実行すること。
-- yumeya_portfolio（既存のローカルDB）では実行しない。
-- 事前に01_schema.sqlを実行し、このファイルは最後にROLLBACKする。

BEGIN;

-- 境界条件: [check_in, check_out) のため、退室日=次の入室日は許可される。
INSERT INTO reservations (room_code, check_in, check_out, guests)
VALUES ('MATSU', DATE '2099-01-10', DATE '2099-01-12', 2);
INSERT INTO reservations (room_code, check_in, check_out, guests)
VALUES ('MATSU', DATE '2099-01-12', DATE '2099-01-14', 2);

-- CANCELLEDは排他制約の対象外なので、同じ期間を再登録できる。
INSERT INTO reservations (room_code, check_in, check_out, guests, status, cancelled_at)
VALUES ('UME', DATE '2099-03-10', DATE '2099-03-12', 2, 'CANCELLED', CURRENT_TIMESTAMP);
INSERT INTO reservations (room_code, check_in, check_out, guests)
VALUES ('UME', DATE '2099-03-10', DATE '2099-03-12', 2);

-- SELECTだけの実行計画。更新処理にはEXPLAIN ANALYZEを付けない。
EXPLAIN (COSTS, VERBOSE, BUFFERS)
SELECT r.reservation_id, r.room_code, r.check_in, r.check_out, r.status
FROM reservations r
WHERE r.room_code = 'MATSU' AND r.status = 'CONFIRMED'
ORDER BY r.created_at DESC
LIMIT 100;

-- テスト用データを一時DBから残さない。
ROLLBACK;
