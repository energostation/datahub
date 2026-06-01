# Hardware Requirements

All services run as Docker
containers on a single host; the platform is not currently designed for
multi-node clustering.

## Resource Drivers

| Component | Resource Pressure | Scales With |
|-----------|-------------------|-------------|
| **TimescaleDB** | CPU, RAM, disk I/O, storage | Number of PLCs × arguments × sampling rate |
| **VerneMQ** | RAM, sockets, CPU (TLS) | Concurrent MQTT connections |
| **Traefik** | CPU (TLS termination) | HTTPS + MQTTS request rate |
| **Subscribers** (datalogger, auditor, notifier) | CPU, RAM | Inbound message rate |

### Small Production (10–50 PLCs)

- **CPU:** 4–6 cores @ 2.5+ GHz
- **RAM:** 16 GB
- **Storage:** 256–512 GB NVMe SSD
- **Network:** 1OO Mbit/s

