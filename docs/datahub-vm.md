# DataHub VM

Virtual disk contains pre-installed Debian Linux 13 (Trixie).

## Virtual disk

| Parameter | value  |
|-----------|--------|
| Format    | qcow2  |
| Bus       | virtio |
| Size      | 40 GB  |

## Networking
Network address is obtained via DHCP server.

**Note:** When deploying VM in different hypervisor, NIC identifier can change, so `/etc/network/interfaces` points to non-existent network interface card. It has to be resolved manually from server console.

Only TCP ports `443` (HTTPS) and `8883` (MQTT) are necessary to be exposed. 
TCP Port 80 (HTTP) is needed as a fallback, for configuration, when domain has not been set.

Do not expose other ports to the Internet (even port TCP 80).

Outbound connections are needed for updating DataHub.

## Published services
Custom domain name is expected to be set up and DNS pointing to DataHub IP address.

Let's assume domain: `ems.local`.

DataHub provides several services like:

```
config.ems.local
api.ems.local
mqtt.ems.local
...
```

All those domain names needs to be created. For complete list see [readme](../README.md).

### Certificates

All services are accessed over TLS.
For TLS to be working correctly, certificate for custom domain has to be deployed.

DataHub uses two certificates:

- MQTT server certificate, provided by Energostation
- HTTP proxy certificate

Certificates can be set using DataHub configuration web interface.
Configuration can be accessed also by HTTP (80) by typing `http://<ip-address>` to a browser.

