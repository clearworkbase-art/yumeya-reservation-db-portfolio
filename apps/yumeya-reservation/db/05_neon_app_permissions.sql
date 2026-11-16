-- Run only against the dedicated demo database, as its schema owner.
-- First create a LOGIN role named yumeya_demo_app in Neon (with its own secret),
-- and execute 01_schema.sql as the OWNER role before running this file.
-- No credentials should be stored in this SQL file or in git.
GRANT USAGE ON SCHEMA public TO yumeya_demo_app;
GRANT SELECT ON TABLE public.rooms TO yumeya_demo_app;
GRANT SELECT, INSERT, UPDATE ON TABLE public.reservations TO yumeya_demo_app;
-- Deliberately not granting DELETE, TRUNCATE, CREATE, ALTER or DROP.
-- The GENERATED ALWAYS AS IDENTITY insert is performed without a direct nextval().
