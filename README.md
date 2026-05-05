# Energostation DataHub

An MQTT-based industrial IoT data collection platform.
PLCs publish telemetry to a VerneMQ MQTT broker; data flows through subscriber services into TimescaleDB; Grafana visualizes it.
Everything runs as Docker Compose services managed by systemd.

## Documentation

- [Setup](docs/setup.md) — prerequisites, SSL certificates, environment variables, initial config generation
- [Running services](docs/running.md) — compose profiles, service endpoints, direct port access
- [Systemd](docs/systemd.md) — installing and managing systemd units, hot-reload mechanism
- [MQTT](docs/mqtt.md) — topic/payload format, PLC client setup, publishing data

## Architecture

### Data flow

```
PLC → MQTTS :8883 (Traefik TCP/SNI) → VerneMQ
                                        ├─ datalogger → TimescaleDB (logger DB)
                                        ├─ auditor    → auditing messages processing
                                        └─ notifier   → sends alerts

HTTPS :443 (Traefik) → api (Django REST)
                     → app (web UI)
                     → grafana
                     → status (Gatus)
                     → config UI
```

### Services

| Service | Image | Description |
|---|---|---|
| traefik | `traefik:v3.6` | Reverse proxy and TCP router |
| postgres | `timescale/timescaledb:2.22.0-pg16` | TimescaleDB (primary datastore) |
| mqtt | `vernemq/vernemq:2.1.1` | MQTT broker with PostgreSQL auth |
| api | `data-api` | Django REST API, manages MQTT users and PLC config |
| app | `data-app` | Web application for PLC communication |
| datalogger | `data-logger` | Subscribes to MQTT, writes to TimescaleDB |
| auditor | `data-auditor` | Subscribes to MQTT, validates incoming data |
| notifier | `data-notifier` | Subscribes to MQTT, sends alerts |
| grafana | `grafana/grafana` | Data visualization |
| config | `data-config` | Config UI for `.env` and certificate management |
| gatus | `twinproduction/gatus` | Health monitoring (monitoring profile) |
| prometheus | `prom/prometheus` | Metrics collection (monitoring profile) |
| exporter-postgres | `postgres-exporter` | PostgreSQL metrics for Prometheus (monitoring profile) |
| adminer | `adminer` | Database management UI (debug profile) |

## Accessing services

### Via domain name (default)

Services are exposed on port `443` with TLS through Traefik. Replace `docker.localhost` with your `DOMAIN_SUFFIX`.

| URL | Service |
|---|---|
| `https://api.docker.localhost` | Data REST API |
| `https://app.docker.localhost` | Web application |
| `https://grafana.docker.localhost` | Grafana dashboards |
| `https://status.docker.localhost` | Health monitoring (monitoring profile) |
| `https://mqtt.docker.localhost` | MQTT broker status (basic auth) |
| `https://proxy.docker.localhost` | Traefik dashboard (basic auth) |
| `https://config.docker.localhost` | Config UI (basic auth) |
| `https://adminer.docker.localhost` | Database management (debug profile) |

MQTT broker: `mqtt.docker.localhost:8883` (TLS, TCP/SNI routing).

### Via static IP and port

Enable port bindings using the `*.ports.yml` override files (see [Running services](docs/running.md#direct-access-via-host-ports)):

| Service | Host port |
|---|---|
| api | 8000 |
| app | 8001 |
| grafana | 3000 |
| status | 8082 |
| adminer | 8091 |
| config | 5000 |

## TODO

- Backups
