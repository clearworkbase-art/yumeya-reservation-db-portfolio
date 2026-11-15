-- 最小権限化のロールバック雛形。
-- <PREVIOUS_OWNER> は所有者監査で確認した元の所有者に置換する。
-- 実DBへ適用する前に、対象DB名と所有者を必ず確認する。

-- 例: 元の所有者が yumeya_app だった場合のみ、以下を置換して実行する。
-- ALTER DATABASE yumeya_portfolio OWNER TO <PREVIOUS_OWNER>; -- 対象DB以外から実行
-- publicスキーマはpg_database_ownerの標準所有関係を維持するため、通常は変更しない。
-- ALTER TABLE public.rooms OWNER TO <PREVIOUS_OWNER>;
-- ALTER TABLE public.reservations OWNER TO <PREVIOUS_OWNER>;
-- ALTER SEQUENCE public.reservations_reservation_id_seq OWNER TO <PREVIOUS_OWNER>;

-- 権限を元に戻す場合も、監査結果に基づき必要なものだけを個別に戻す。
-- GRANT CREATE ON DATABASE yumeya_portfolio TO yumeya_app;
-- GRANT CREATE ON SCHEMA public TO yumeya_app;
-- GRANT ALL ON TABLE public.rooms, public.reservations TO yumeya_app;
-- GRANT ALL ON SEQUENCE public.reservations_reservation_id_seq TO yumeya_app;
