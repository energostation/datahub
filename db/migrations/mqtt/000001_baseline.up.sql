-- Baseline schema for the mqtt database (VerneMQ auth/ACL).
-- Applied idempotently: safe to run against a fresh database or one already
-- provisioned by the legacy db/init/energo-setup.sh script.

GRANT CONNECT, TEMPORARY ON DATABASE mqtt TO mqtt;
GRANT USAGE, CREATE ON SCHEMA public TO mqtt;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO mqtt;

-- Required by VerneMQ's postgres auth (crypt password hashing).
CREATE EXTENSION IF NOT EXISTS pgcrypto;
