#!/usr/bin/env bash

set -e


echo "Creating databases"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d $POSTGRES_DB <<-EOSQL
    CREATE DATABASE $ENERGO_POSTGRES__DATA_API__DATABASE;
    CREATE DATABASE $ENERGO_POSTGRES__DATA_LOGGER__DATABASE;
    CREATE DATABASE $ENERGO_POSTGRES__MQTT__DATABASE;
EOSQL

echo "Creating users"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d $POSTGRES_DB <<-EOSQL
    CREATE USER $ENERGO_POSTGRES__DATA_API__USERNAME WITH PASSWORD '$ENERGO_POSTGRES__DATA_API__PASSWORD';
    CREATE USER $ENERGO_POSTGRES__DATA_LOGGER__USERNAME WITH PASSWORD '$ENERGO_POSTGRES__DATA_LOGGER__PASSWORD';
    CREATE USER $ENERGO_POSTGRES__MQTT__USERNAME WITH PASSWORD '$ENERGO_POSTGRES__MQTT__PASSWORD';
    CREATE USER $ENERGO_POSTGRES__GRAFANA__USERNAME WITH PASSWORD '$ENERGO_POSTGRES__GRAFANA__PASSWORD';
EOSQL

echo "Grants for: $ENERGO_POSTGRES__DATA_API__DATABASE"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d $ENERGO_POSTGRES__DATA_API__DATABASE <<-EOSQL
    GRANT CONNECT, TEMPORARY ON DATABASE $ENERGO_POSTGRES__DATA_API__DATABASE TO $ENERGO_POSTGRES__DATA_API__USERNAME;
    GRANT USAGE, CREATE ON SCHEMA public TO $ENERGO_POSTGRES__DATA_API__USERNAME;
EOSQL

echo "Grants for: $ENERGO_POSTGRES__DATA_LOGGER__DATABASE"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d $ENERGO_POSTGRES__DATA_LOGGER__DATABASE <<-EOSQL
    -- datalogger
    GRANT CONNECT, TEMPORARY ON DATABASE $ENERGO_POSTGRES__DATA_LOGGER__DATABASE TO $ENERGO_POSTGRES__DATA_LOGGER__USERNAME;
    GRANT USAGE, CREATE ON SCHEMA public TO $ENERGO_POSTGRES__DATA_LOGGER__USERNAME;
    -- grafana
    GRANT CONNECT ON DATABASE $ENERGO_POSTGRES__DATA_LOGGER__DATABASE TO $ENERGO_POSTGRES__GRAFANA__USERNAME;
    GRANT USAGE ON SCHEMA public TO $ENERGO_POSTGRES__GRAFANA__USERNAME;
EOSQL

echo "Grants for: $ENERGO_POSTGRES__MQTT__USERNAME"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d $ENERGO_POSTGRES__MQTT__DATABASE <<-EOSQL
    GRANT CONNECT, TEMPORARY ON DATABASE $ENERGO_POSTGRES__MQTT__DATABASE TO $ENERGO_POSTGRES__MQTT__USERNAME;
    GRANT USAGE, CREATE ON SCHEMA public TO $ENERGO_POSTGRES__MQTT__USERNAME;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO $ENERGO_POSTGRES__MQTT__USERNAME;
EOSQL

echo "Creating ACL table for MQTT broker"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d "$ENERGO_POSTGRES__MQTT__DATABASE" <<-EOSQL
    CREATE EXTENSION pgcrypto;
    CREATE TABLE vmq_auth_acl
    (
        mountpoint character varying(10) NOT NULL,
        client_id character varying(128) NOT NULL,
        username character varying(128) NOT NULL,
        password character varying(128),
        publish_acl json,
        subscribe_acl json,
        CONSTRAINT vmq_auth_acl_primary_key PRIMARY KEY (mountpoint, client_id, username)
    );
EOSQL

echo "Creating grant function for energo datalog tables"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d "$ENERGO_POSTGRES__DATA_LOGGER__DATABASE" <<-EOSQL
    CREATE OR REPLACE FUNCTION grant_permissions_on_datalog_tables()
    RETURNS event_trigger AS \$\$
    DECLARE
        obj record;
    BEGIN
        -- Loop through all newly created tables
        FOR obj IN SELECT * FROM pg_event_trigger_ddl_commands()
        WHERE object_type = 'table'
        LOOP
            -- Check if table name starts with 'datalog_'
            IF obj.object_identity LIKE 'public.datalog_%' THEN
                -- Grant SELECT permission to role
                EXECUTE format('GRANT SELECT ON TABLE %s TO $ENERGO_POSTGRES__GRAFANA__USERNAME', obj.object_identity);
                RAISE NOTICE 'Granted SELECT on % to $ENERGO_POSTGRES__GRAFANA__USERNAME', obj.object_identity;
            END IF;
        END LOOP;
    END;
    \$\$ LANGUAGE plpgsql;
EOSQL

echo "Creating trigger for datalog tables"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d "$ENERGO_POSTGRES__DATA_LOGGER__DATABASE" <<-EOSQL
    CREATE EVENT TRIGGER auto_grant_datalog_permissions
        ON ddl_command_end
        WHEN TAG IN ('CREATE TABLE')
        EXECUTE FUNCTION grant_permissions_on_datalog_tables();
EOSQL
