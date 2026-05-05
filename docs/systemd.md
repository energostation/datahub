# Systemd

The project includes systemd service units in `systemd/`. They expect the project to be deployed at `/srv/datahub`.

## Installing

```shell
cp systemd/*.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable datahub-core.service datahub-services.service datahub-updater.service
systemctl start datahub-core.service datahub-services.service datahub-updater.service
```

## Checking status

```shell
systemctl status datahub-core.service datahub-services.service datahub-updater.service
```

## Services

| Unit | Description |
|---|---|
| `datahub-core.service` | Runs `datahub-core.yml --profile base` |
| `datahub-services.service` | Runs `datahub-services.yml --profile base` (and optionally monitoring/debug) |
| `datahub-core-ports.service` | Variant of core with port bindings override |
| `datahub-services-ports.service` | Variant of services with port bindings override |
| `datahub-updater.service` | Hot-reload watcher (see below) |

## Hot-reload mechanism (`datahub-updater.service`)

`bin/updater.sh` uses `inotifywait` to watch for a `.core-update.lock` file in the project directory. When that file appears, it:

1. Waits 10 seconds.
2. Stops and restarts `datahub-core.service`.
3. Removes the lock file.

The config UI triggers this mechanism after updating the configuration, so that core services pick up changes without manual intervention.
