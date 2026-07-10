-- Elevate the logger role and give it ownership of its own database.
-- Idempotent: ALTER ROLE ... CREATEROLE and ALTER DATABASE ... OWNER TO are
-- no-ops when the attribute/owner is already set, so the first run against an
-- already-provisioned instance is a safe baseline. Runs as the postgres
-- superuser (via db/migrate-entrypoint.sh), which is required to change role
-- attributes and reassign database ownership.

ALTER ROLE logger CREATEROLE;
ALTER DATABASE logger OWNER TO logger;
