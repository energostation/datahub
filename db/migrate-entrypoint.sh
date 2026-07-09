#!/bin/sh
# Entrypoint for the one-shot `migrate` service. Applies each database's
# golang-migrate migrations as the postgres superuser (required for
# CREATE EXTENSION, event triggers and cross-role grants).
#
# Each `migrate up` is retried so we absorb the short window where postgres is
# accepting connections but not yet fully up (e.g. the first-boot initdb
# restart). A migration that keeps failing still exits non-zero after the cap,
# which blocks the rollout on purpose.
set -eu

PGHOST="${MIGRATE_DB_HOST:-postgres}"
PGPORT="${MIGRATE_DB_PORT:-5432}"
MAX_ATTEMPTS="${MIGRATE_MAX_ATTEMPTS:-30}"

apply() {
  path="$1"
  dbname="$2"
  url="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${PGHOST}:${PGPORT}/${dbname}?sslmode=disable"
  attempt=0
  until migrate -path="$path" -database "$url" up; do
    attempt=$((attempt + 1))
    if [ "$attempt" -ge "$MAX_ATTEMPTS" ]; then
      echo "migrate: giving up on '${dbname}' after ${attempt} attempts" >&2
      exit 1
    fi
    echo "migrate: '${dbname}' not ready or failed (attempt ${attempt}); retrying in 2s" >&2
    sleep 2
  done
}

apply /migrations/mqtt   "${ENERGO_POSTGRES__MQTT__DATABASE:-mqtt}"
apply /migrations/logger "${ENERGO_POSTGRES__DATA_LOGGER__DATABASE:-logger}"
apply /migrations/api    "${ENERGO_POSTGRES__DATA_API__DATABASE:-api}"

echo "migrate: all migrations applied"
