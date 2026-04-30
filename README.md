# Energostation DataHub

## Setup

### ENV

However `docker compose` can be run immediately, `.env` file is used for configuration, and it is almost inevitable to use it.

### SSL

Certificates have to be provided for the following services:

- MQTT broker, server certificate
- HTTP proxy, server *wildcard* certificate

Client certificate for PLC is generated elsewhere and is already deployed.

The server certificates must be placed in the `ssl` directory.

```plain
ssl
├── mqtt
│   ├── server.crt
│   └── server.key
└── proxy
    ├── server.crt
    └── server.key
```

#### Trusted CA

The MQTT broker and HTTP proxy use custom CA.

### Docker

#### Initial setup run

```shell
docker network create energo
```
to create an external network for services.

Then create `.env` file and generate certificates.

Use ENV `DOMAIN_SUFFIX=docker.localhost` for custom domain suffix.
Note that it is the suffix part, whole DNS name will look like `api.docker.localhost`.

```shell
export DOMAIN_SUFFIX=docker.localhost
docker compose -f datahub-core.yml --profile=config up
```

#### Running services

```shell
docker compose -f datahub-core.yml --profile=base up -d
docker compose -f datahub-services.yml --profile=base up -d
```

this will start core services:
- API
- App
- Database
- Grafana
- HTTP proxy
- MQTT broker 
- Subscriber

For monitoring services run
```shell
docker compose -f datahub-services.yml --profile=base --profile=monitoring up -d
```

this will also start:
- Gatus
- Prometheus
- Postgres exporter

For debug tools run
```shell
docker compose -f datahub-services.yml --profile=base --profile=monitoring  --profile=debug up
```

this will also start:
- Adminer

#### Key Connections:

- HTTP proxy routes external traffic to: API, App, Grafana, MQTT, Gatus, Adminer
- MQTT broker uses a database for authentication and authorization
- Subscriber connects to MQTT broker via MQTTS and writes to a database
- Data API reads/writes a database and manages MQTT users
- Grafana visualizes data from database
- Gatus monitors health of all services
- Prometheus scrapes metrics from proxy and database
- Adminer provides database lookup and management

#### Dependency graph

```plain
postgres
├─ api
│  └─ collectstatic
├─ mqtt
│  └─ subscriber
├─ grafana
└─ exporter-postgres

api
└─ mqtt
   └─ subscriber
```

### Usage

#### Via domain name (default)

Services are exposed on port `443` with TLS through the HTTP proxy.

- [https://api.docker.localhost](https://api.docker.localhost) - Data REST API
- [https://app.docker.localhost](https://app.docker.localhost) - Web application for communicating with PLCs
- [https://grafana.docker.localhost](https://grafana.docker.localhost) - Data visualization tool
- [https://status.docker.localhost](https://status.docker.localhost) - monitoring tool (only if monitoring profile is enabled)
- [https://mqtt.docker.localhost/status](https://mqtt.docker.localhost/status) - MQTT broker web status
- [https://proxy.docker.localhost](https://proxy.docker.localhost) - HTTP proxy dashboard
- [https://adminer.docker.localhost](https://adminer.docker.localhost) - database management tool (only if debug profile is enabled)
- [https://config.docker.localhost](https://config.docker.localhost) - configuration (`.env` and certificates) management tool

MQTT broker is exposed on port `8883` with TLS through the TCP proxy, SNI routing requires the correct hostname.

- `mqtt.docker.localhost:8883`

#### Via IP address and port (direct access)

Port bindings can be enabled using the provided override files:

```shell
docker compose -f datahub-core.yml -f datahub-core.ports.yml --profile=base up -d
docker compose -f datahub-services.yml -f datahub-services.ports.yml --profile=base up -d
```

| Service | Host port | Description |
|---------|-----------|-------------|
| postgres | 5432 | TimescaleDB |
| mqtt | 1883 | MQTT broker (plain TCP, no TLS) |
| api | 8000 | Data REST API |
| app | 8001 | Web application |
| grafana | 3000 | Data visualization |
| gatus | 8082 | Monitoring (monitoring profile) |
| prometheus | 9090 | Metrics (monitoring profile) |
| adminer | 8081 | Database management (debug profile) |
| config | 5000 | Configuration management |

### Systemd services

Copy files from `./systemd/` to `/etc/systemd/system/` run `systemctl daemon-reload`. 

Then enable and start services.
```shell
systemctl enable datahub-core.service datahub-services.service datahub-updater.service
systemctl start datahub-core.service datahub-services.service datahub-updater.service
```

Check status

```shell
systemctl status datahub-core.service datahub-services.service datahub-updater.service
```

## MQTT

### Setup client (PLC)

PLC configuration is deployed elsewhere via configurator, using the "Deploy embedded API" button.

However, for PLC to be able to connect to the broker, configuration must be deployed to DataHub.

From the configurator get the necessary (encrypted) configuration bundle and send it to the DataHub `config.docker.localhost` GUI interface.

```shell
curl \
  -X POST \
  -H "Authorization: Token $ENERGO__DATA_API__MANAGE_API_TOKEN" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "password=$PASSWORD_BUNDLE" \
  -d "content=$ENCRYPTED_CONFIG_BUNDLE" \
  "https://api.docker.localhost/manage/config/"
```

### Publish data

```shell
mosquitto_pub \
  -h <IP_ADDRESS_OF_MQTT_BROKER> \
  -p 1883 \
  -i $CLIENT_ID \
  -u $MQTT_USERNAME \
  -P $MQTT_PASSWORD \
  -t plc/v1/${PROJECT_ID}/${PLC_ID}/message \
  -m '{"timestamp": "2025-10-17 10:22:19.030705", "argument": "FB_TEST.TEST_ARG", "value": 3.14}'
```

```shell
mosquitto_pub \
  -h mqtt.docker.localhost \
  -p 8883 \
  --cafile $MQTT_CA \
  --cert $MQTT_CERT \
  --key $MQTT_KEY \
  -i $CLIENT_ID \
  -u $MQTT_USERNAME \
  -P $MQTT_PASSWORD \
  -t plc/v1/${PROJECT_ID}/${PLC_ID}/message \
  -m '{"timestamp": "2025-10-17 10:22:19.030705", "argument": "FB_TEST.TEST_ARG", "value": 3.14}'
```

## Data API

see: [API swagger](https://api.docker.localhost/api/schema/swagger-ui/) at `https://api.docker.localhost/api/schema/swagger-ui`


# TODO
- backups
- updates
