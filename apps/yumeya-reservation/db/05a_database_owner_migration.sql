-- DB所有者の移行。対象DB以外（通常はpostgres）へ接続して管理者が実行する。
-- 05_privilege_migration.sqlと同じテスト専用DBで先に検証する。
ALTER DATABASE yumeya_portfolio OWNER TO yumeya_owner;
