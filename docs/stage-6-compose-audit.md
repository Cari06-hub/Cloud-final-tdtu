# Stage 6 - Integrated Docker Compose Audit

> Integrator: Trung Nguyên - `52400141`
> Branch: `Nguyen`
> Validation date: `2026-11-11`

## 1. Integrated stack

The primary `docker-compose.yml` now defines all eleven required services:

| Service | Static IP | Host publication | Runtime result |
|---|---|---|---|
| `web-frontend-server` | `10.10.10.10` | `8080:80` | Running |
| `web-frontend-server2` | `10.10.10.11` | None | Running |
| `application-backend-server` | `10.10.10.20` | `8085:8081` | Running |
| `relational-database-server` | `10.10.10.25` | None | Running, healthy |
| `object-storage-server` | `10.10.10.30` | `9000:9000`, `9001:9001` | Running |
| `authentication-identity-server` | `10.10.10.40` | `8081:8080` | Running |
| `internal-dns-server` | `10.10.10.50` | `1053:53` TCP/UDP | Running |
| `node-exporter` | `10.10.10.60` | None | Running |
| `monitoring-prometheus-server` | `10.10.10.61` | `9090:9090` | Running |
| `monitoring-grafana-dashboard-server` | `10.10.10.62` | `3000:3000` | Running |
| `api-gateway-proxy-server` | `10.10.10.70` | `80:80` | Running |

All services join `cloud-net` and use `restart: unless-stopped`. MariaDB,
Web 2 and Node Exporter deliberately have no host port publication.

## 2. Added data and infrastructure services

### MariaDB

- Image: `mariadb:11.4.5`.
- Named volume: `myminicloud_mariadb_data:/var/lib/mysql`.
- Init path: `relational-database-server/init/01-init.sql`.
- Healthcheck: `healthcheck.sh --connect --innodb_initialized`.
- Flask waits for the database healthcheck before starting.
- `/students-db` returned the five initialized student records.

### MinIO

- Image: `bitnamilegacy/minio:2024.6.13`.
- Named volume: `myminicloud_minio_data:/bitnami/minio/data`.
- `/minio/health/live` returned HTTP 200.
- MinIO reported one online node.

### Bind9

- Image: `internetsystemsconsortium/bind9:9.18`.
- Configuration and zone are mounted read-only.
- `named-checkconf` passed.
- `named-checkzone cloud.local` loaded serial `2026111002` and returned `OK`.
- The zone contains records for all eleven service names.

## 3. Network and IPAM validation

`cloud-net` was inspected before adding the remaining services:

```text
Subnet:  10.10.10.0/24
Gateway: 10.10.10.1
```

The Windows route table contained no exact host/VPN route for
`10.10.10.0/24`. Runtime inspection confirmed all eleven container IPs match
the Compose IPAM contract. Authoritative `dig` queries against Bind9 returned
11/11 expected addresses.

The TV2 connectivity script returned:

```text
PASS: 11 / 11
FAIL: 0 / 11
```

Both ping scripts now use the pinned helper image `busybox:1.38.0`; the
PowerShell script exits non-zero if any ping fails.

## 4. Persistence validation

The following exact named-volume mounts were inspected:

| Service | Named volume | Destination |
|---|---|---|
| MariaDB | `myminicloud_mariadb_data` | `/var/lib/mysql` |
| Keycloak | `myminicloud_keycloak_data` | `/opt/keycloak/data` |
| MinIO | `myminicloud_minio_data` | `/bitnami/minio/data` |
| Prometheus | `myminicloud_prometheus_data` | `/prometheus` |
| Grafana | `myminicloud_grafana_data` | `/var/lib/grafana` |

Before `docker compose restart`, controlled markers were created in a dedicated
MariaDB test table and a dedicated MinIO test bucket. After restarting all
eleven services:

- MariaDB returned `stage6-mariadb-ok`.
- MinIO returned `stage6-minio-ok` from the stored object.
- Keycloak issued a master-realm admin token from its persisted database.
- Grafana retained and served its datasource and both provisioned dashboards.
- Prometheus retained its data volume and returned monitoring series.

The temporary MariaDB table and MinIO bucket were removed after verification.
No group demo data was deleted.

## 5. Integrated automated gate

Run with the real local environment file:

```powershell
./scripts/test-compose.ps1 `
  -EnvFile .env `
  -GrafanaAdminUser $env:GF_SECURITY_ADMIN_USER `
  -GrafanaAdminPassword $env:GF_SECURITY_ADMIN_PASSWORD
```

The gate checks:

- the exact eleven-service Compose list;
- running state, static IP and restart policy for every container;
- all five named-volume contracts;
- non-public Web 2, MariaDB and Node Exporter ports;
- all eleven authoritative DNS records;
- five rows through Flask `/students-db`;
- MinIO health;
- Prometheus B7/E7 regression;
- Grafana B8/E8 regression;
- Gateway B9/E9/E10 regression.

Final result:

```text
Integrated Compose acceptance test PASSED.
Containers: 11/11 running on cloud-net
Persistent volumes: MariaDB, Keycloak, MinIO, Prometheus, Grafana
Database students: 5
DNS records: 11/11
```

## 6. Security checks

- No real credential is stored in Compose, source code or documentation.
- Required passwords use Compose environment interpolation.
- `.env.example` contains disposable placeholders only.
- MariaDB and Node Exporter are not published to the host.
- No broad container or volume deletion command was used.

The validation in this audit used `.env.example` only for disposable local
testing. A strong untracked `.env` is required before demonstration or EC2
deployment.
