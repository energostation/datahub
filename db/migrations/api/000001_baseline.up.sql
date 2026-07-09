-- Baseline schema for the api database.
-- Applied idempotently: safe to run against a fresh database or one already
-- provisioned by the legacy db/init/energo-setup.sh script.

GRANT CONNECT, TEMPORARY ON DATABASE api TO api;
GRANT USAGE, CREATE ON SCHEMA public TO api;
