# Grafana Dashboard Server

## Integrated version

```text
grafana/grafana:13.3.0
```

The image tag is pinned and passed a registry manifest check. Grafana data is
stored in `grafana_data`; datasource and dashboard definitions are provisioned
from version-controlled files.

Official references:

- <https://grafana.com/docs/grafana/latest/setup-grafana/installation/docker/>
- <https://grafana.com/docs/grafana/latest/administration/provisioning/>
- <https://grafana.com/grafana/dashboards/1860-node-exporter-full/>

## Provisioned datasource

| Field | Value |
|---|---|
| Name | `Prometheus` |
| UID | `prometheus` |
| URL | `http://monitoring-prometheus-server:9090` |
| Access | Server/proxy |
| Default | Yes |

Grafana must not use `localhost:9090`; inside the Grafana container,
`localhost` refers to Grafana itself.

## Provisioned dashboards

### B8 - Node Exporter Full

- Grafana.com ID: `1860`.
- Revision: `45`.
- Title: `Node Exporter Full`.
- Source is downloaded and normalized by
  `scripts/fetch-node-exporter-dashboard.py`.
- The Grafana.com datasource variable is replaced with the stable UID
  `prometheus`.

Refresh the pinned source intentionally with:

```bash
python scripts/fetch-node-exporter-dashboard.py
```

Do not silently change the dashboard ID or revision because screenshots and
panel behavior must remain reproducible.

### E8 - Personal dashboard

```text
System Health of 52400141
```

The dashboard has exactly three required panels:

1. CPU Usage (%) - unit `percent`.
2. Memory Usage (%) - unit `percent`.
3. Network Traffic - Receive - unit `Bps`.

Source file:

```text
dashboards/system-health-52400141.json
```

## Start Grafana

Create a local `.env` from `.env.example` and replace the Grafana password, or
use `.env.example` only for disposable local validation:

```bash
docker compose --env-file .env config --quiet
docker compose --env-file .env up -d monitoring-grafana-dashboard-server
docker compose --env-file .env ps
```

Open `http://localhost:3000` and log in with `GF_SECURITY_ADMIN_USER` and
`GF_SECURITY_ADMIN_PASSWORD` from the local `.env`.

## Automated acceptance test

PowerShell:

```powershell
./scripts/test-grafana.ps1 `
  -AdminUser $env:GF_SECURITY_ADMIN_USER `
  -AdminPassword $env:GF_SECURITY_ADMIN_PASSWORD
```

The test verifies:

- Grafana health.
- Provisioned Prometheus datasource URL and UID.
- Both required dashboards.
- Three required personal-dashboard panels and units.
- CPU, Memory and Network queries return data through Grafana's datasource
  proxy.

## Persistence test

Provisioning must recreate dashboards on a fresh volume. During controlled
testing only:

```bash
docker compose --env-file .env stop monitoring-grafana-dashboard-server
docker compose --env-file .env rm -f monitoring-grafana-dashboard-server
docker volume rm myminicloud_grafana_data
docker compose --env-file .env up -d monitoring-grafana-dashboard-server
```

Run the automated acceptance test again. Do not remove the volume later if it
contains manual changes that have not been exported.
