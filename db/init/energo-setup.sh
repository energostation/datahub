#!/usr/bin/env bash

set -e

# Cluster bootstrap only. This script runs once, on a fresh (empty) data
# directory, via /docker-entrypoint-initdb.d. It creates the databases and
# roles; everything else (grants, extensions, functions, triggers, and all
# future schema) is owned by golang-migrate migrations in db/migrations/,
# applied by the `migrate` service. See CLAUDE.md and docs/running.md.

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
