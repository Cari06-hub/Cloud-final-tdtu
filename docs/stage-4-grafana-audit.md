# Stage 4 - Grafana and Dashboard Audit

> Integrator: Trung Nguyên - `52400141`
> Branch: `Nguyen`
> Validation date: `2026-11-10`

## 1. Version and source decisions

| Component | Pinned version/source | Purpose |
|---|---|---|
| Grafana | `grafana/grafana:13.3.0` | Dashboard server |
| Node Exporter Full | Grafana.com ID `1860`, revision `45` | B8 dashboard |

The Node Exporter Full JSON is downloaded by
`scripts/fetch-node-exporter-dashboard.py`. The script pins both dashboard ID
and revision, verifies the title, replaces the external datasource variable
with the local stable UID `prometheus`, and refuses to write a partially
normalized result.

References:

- <https://grafana.com/docs/grafana/latest/setup-grafana/installation/docker/>
- <https://grafana.com/docs/grafana/latest/administration/provisioning/>
- <https://grafana.com/grafana/dashboards/1860-node-exporter-full/>

## 2. Provisioning contract

| Item | Value |
|---|---|
| Service/container | `monitoring-grafana-dashboard-server` |
| Static IP | `10.10.10.62` |
| Published port | `3000:3000` |
| Datasource name | `Prometheus` |
| Datasource UID | `prometheus` |
| Datasource URL | `http://monitoring-prometheus-server:9090` |
| Default datasource | Yes |
| Dashboard folder | `MyMiniCloud` |
| Persistent volume | `myminicloud_grafana_data` |
| Restart policy | `unless-stopped` |

Grafana credentials are read from `GF_SECURITY_ADMIN_USER` and
`GF_SECURITY_ADMIN_PASSWORD`. No real password is stored in the repository.

## 3. Provisioned dashboards

### B8 - Node Exporter Full

- Title: `Node Exporter Full`.
- UID: `rYdddlPWk`.
- Provisioned panel count: 31 top-level panels.
- All Prometheus panel datasource references use UID `prometheus`.
- The source contains CPU, memory, receive-network and transmit-network metric
  families required for the assignment.

### E8 - Personal dashboard

- Title: `System Health of 52400141`.
- UID: `system-health-52400141`.
- Exactly three panels are provisioned:

| Panel | Unit | Runtime result |
|---|---|---|
| `CPU Usage (%)` | `percent` | 1 series |
| `Memory Usage (%)` | `percent` | 1 series |
| `Network Traffic - Receive` | `Bps` | 1 series |

## 4. Validation performed

Passed checks:

- Docker Compose renders successfully with `.env.example`.
- Both dashboard JSON files pass JSON parsing.
- PowerShell acceptance script passes AST parsing.
- Node Exporter Full contains no `${ds_prometheus}` placeholder.
- Grafana health reports database status `ok`.
- Provisioned datasource has UID `prometheus`, the required internal URL and
  is the default datasource.
- Grafana API returns both required dashboard UIDs in folder `MyMiniCloud`.
- The personal dashboard has exactly the required titles and units.
- CPU, memory and network PromQL each return one series through Grafana's
  authenticated datasource proxy.
- All four Stage 4 containers are running; Node Exporter remains internal and
  has no host port mapping.

Acceptance command:

```powershell
./scripts/test-grafana.ps1 `
  -AdminUser $env:GF_SECURITY_ADMIN_USER `
  -AdminPassword $env:GF_SECURITY_ADMIN_PASSWORD
```

## 5. Fresh-volume reproducibility test

The Grafana container was stopped and removed. The exact named volume
`myminicloud_grafana_data` was verified from the container mount metadata and
then removed. After starting the service with a newly created empty volume,
the log reported:

```text
inserting datasource from configuration name=Prometheus uid=prometheus
starting to provision dashboards
finished to provision dashboards
```

The complete automated acceptance test then passed again. This proves the
datasource and both dashboards are recreated from version-controlled files,
not from residual SQLite state.

## 6. Remaining evidence work

Technical acceptance for B8 and E8 is complete. During Stage 7, capture:

- `B8_grafana_node_exporter_full.png` with CPU, RAM and Network visible.
- `E8_system_health_52400141.png` with the dashboard title and all three panels.
- A terminal capture of `scripts/test-grafana.ps1` passing.

Wait at least five minutes after startup before taking dashboard screenshots so
rate-based panels have a complete time window. Do not use screenshots that show
`No data` or expose the Grafana password.
