# Running Services

## Compose files and profiles

The project uses two compose files, each with named profiles:

| Compose file | Profile | Services started |
|---|---|---|
| `datahub-core.yml` | `config` | `config-make` (one-time init) |
| `datahub-core.yml` | `base` | Traefik (reverse proxy), config UI |
| `datahub-services.yml` | `base` | postgres, migrate, mqtt, api, app, datalogger, auditor, notifier, grafana, static, collectstatic |
| `datahub-services.yml` | `monitoring` | gatus, prometheus, exporter-postgres |
| `datahub-services.yml` | `debug` | adminer |

## Starting services

### Base services

```shell
docker compose -f datahub-core.yml --profile=base up -d
docker compose -f datahub-services.yml --profile=base up -d
```

Starts: Traefik, config UI, postgres, mqtt, api, app, datalogger, auditor, notifier, grafana, static.

### With monitoring

```shell
docker compose -f datahub-services.yml --profile=base --profile=monitoring up -d
```

Additionally starts: Gatus, Prometheus, Postgres exporter.

### With debug tools

```shell
docker compose -f datahub-services.yml --profile=base --profile=monitoring --profile=debug up
```

Additionally starts: Adminer.

## Database migrations

The one-shot `migrate` service ([golang-migrate](https://github.com/golang-migrate/migrate))
runs automatically as part of the `base` profile. On every `up` it applies any pending
migrations from `db/migrations/<database>/` (one folder per database) as the postgres
superuser, then exits. Services that use the database wait for it to finish
(`depends_on: migrate: condition: service_completed_successfully`), so a failed migration
blocks the rollout instead of starting services against a half-migrated schema.

The databases and roles themselves are still created once by `db/init/energo-setup.sh`
(cluster bootstrap); migrations own all schema inside those databases.

**Adding a migration:**

```shell
# create the next version pair for a database (e.g. logger)
db/migrations/logger/00000N_<title>.up.sql     # forward change
db/migrations/logger/00000N_<title>.down.sql   # reverse change
```

Keep migrations idempotent (`... IF EXISTS`, `CREATE OR REPLACE`,
`CREATE EXTENSION IF NOT EXISTS`, `GRANT`) so re-runs and first-time runs against an
already-provisioned instance are safe no-ops. They take effect on the next
`docker compose ... up` (or the next `datahub-services.service` restart).

## Service endpoints (via domain name)

Services are exposed on port `443` with TLS through Traefik. The hostname suffix is set by `DOMAIN_SUFFIX` (default: `docker.localhost`).

| Service | URL | Notes |
|---|---|---|
| Data REST API | `https://api.docker.localhost` | Swagger UI at `/api/schema/swagger-ui/` |
| Web application | `https://app.docker.localhost` | PLC communication UI |
| Grafana | `https://grafana.docker.localhost` | Data visualization |
| Gatus (status) | `https://status.docker.localhost` | Health monitoring (monitoring profile) |
| MQTT broker status | `https://mqtt.docker.localhost` | VerneMQ HTTP status (basic auth) |
| Traefik dashboard | `https://proxy.docker.localhost` | Reverse proxy dashboard (basic auth) |
| Config UI | `https://config.docker.localhost` | `.env` and certificate management (basic auth) |
| Adminer | `https://adminer.docker.localhost` | Database management (debug profile, basic auth) |

MQTT broker is accessible directly on port `8883` with TLS via Traefik TCP/SNI routing:

```
mqtt.docker.localhost:8883
```

## Direct access via host ports

Port bindings can be enabled using the provided override files. Pass them alongside the base compose files:

```shell
docker compose -f datahub-core.yml -f datahub-core.ports.yml --profile=base up -d
docker compose -f datahub-services.yml -f datahub-services.ports.yml --profile=base up -d
```

| Service | Host port | Description |
|---|---|---|
| api | 8000 | Data REST API |
| app | 8001 | Web application |
| grafana | 3000 | Data visualization |
| status (gatus) | 8082 | Health monitoring (monitoring profile) |
| adminer | 8091 | Database management (debug profile) |
| config | 5000 | Configuration management UI |

This can also be controlled via `ENERGO__COMPOSE_EXPOSE_PORTS=true` in `.env` when managed through the config UI.
