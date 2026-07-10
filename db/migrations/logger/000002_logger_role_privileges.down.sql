-- Reverse of 000002 up. Assumes the default superuser name `postgres`
-- (matches POSTGRES_USER default and the original CREATE DATABASE owner).
ALTER DATABASE logger OWNER TO postgres;
ALTER ROLE logger NOCREATEROLE;
