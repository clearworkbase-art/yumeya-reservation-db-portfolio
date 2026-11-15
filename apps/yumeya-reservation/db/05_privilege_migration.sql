-- PostgreSQL最小権限化（管理者または現在の所有者として実行）
-- 注意: yumeya_portfolioへ直接適用する前に、所有者監査とバックアップを行い、承認を得ること。
-- このファイルはテストDBで先に実行する。
-- パスワードはこのファイルに記載しない。
-- DB所有者の変更は05a_database_owner_migration.sqlで対象DB以外から実行する。

-- 1. DDL所有者用ロール。アプリからログインできない。
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'yumeya_owner') THEN
        CREATE ROLE yumeya_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
    END IF;
END
$$;

ALTER ROLE yumeya_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
REVOKE yumeya_owner FROM yumeya_app;

-- 2. アプリがPUBLIC経由でDDLできないようにする。
-- 他アプリが同じDBを使う場合は影響を確認してから実行する。
REVOKE CREATE ON DATABASE yumeya_portfolio FROM PUBLIC;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE CREATE ON DATABASE yumeya_portfolio FROM yumeya_app;
REVOKE CREATE ON SCHEMA public FROM yumeya_app;
GRANT CONNECT ON DATABASE yumeya_portfolio TO yumeya_app;
GRANT USAGE ON SCHEMA public TO yumeya_app;

-- ALTER ... OWNER TOには新所有者のスキーマCREATEが必要なため、
-- 所有権移行の瞬間だけ管理ロールへ付与する。
GRANT CREATE ON SCHEMA public TO yumeya_owner;

-- 3. アプリ用テーブル権限を一度明示的に絞る。
REVOKE ALL ON TABLE public.rooms, public.reservations FROM yumeya_app;
REVOKE ALL ON SEQUENCE public.reservations_reservation_id_seq FROM yumeya_app;

GRANT SELECT ON TABLE public.rooms TO yumeya_app;
GRANT SELECT ON TABLE public.reservations TO yumeya_app;
GRANT INSERT (room_code, check_in, check_out, guests, status)
    ON TABLE public.reservations TO yumeya_app;
GRANT UPDATE (status, cancelled_at)
    ON TABLE public.reservations TO yumeya_app;
-- IDENTITY列の通常INSERTに個別sequence権限は付与しない。
-- 直接nextval()を使う権限もアプリには不要。

-- 4. テーブルとidentity sequenceの所有権をNOLOGINロールへ移す。
-- publicスキーマはpg_database_ownerの標準所有関係を維持する。
ALTER TABLE public.rooms OWNER TO yumeya_owner;
ALTER TABLE public.reservations OWNER TO yumeya_owner;
ALTER SEQUENCE public.reservations_reservation_id_seq OWNER TO yumeya_owner;
REVOKE CREATE ON SCHEMA public FROM yumeya_owner;
