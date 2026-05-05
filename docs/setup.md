# Setup

## Prerequisites

### External Docker network

Create the shared Docker bridge network once before any services are started:

```shell
docker network create energo
```

### Environment file

Runtime secrets and settings live in `.env` at the project root (not committed). Copy or create it before starting services.

### SSL certificates

Certificates must be placed in the `ssl/` directory before starting Traefik:

```plain
ssl
├── mqtt
│   ├── server.crt
│   └── server.key
└── proxy
    ├── server.crt
    └── server.key
```

- The **proxy** certificate must be a wildcard covering `*.<DOMAIN_SUFFIX>`.
- The **MQTT** certificate is for `mqtt.<DOMAIN_SUFFIX>`.
- Both services use a custom CA. Clients (e.g. PLCs) must trust that CA.

Client certificates for PLCs are generated and deployed separately via the configurator.

## Initial configuration generation

The `config` profile runs a one-time container that generates the initial `.env` template and certificates:

```shell
export DOMAIN_SUFFIX=docker.localhost
docker compose -f datahub-core.yml --profile=config up
```

This uses the `config-make` container. After it exits, edit the generated `.env` as needed.
