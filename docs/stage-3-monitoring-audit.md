# Stage 3 - Prometheus and Node Exporter Audit

> Integrator: Trung Nguyên - `52400141`
> Branch: `Nguyen`
> Validation date: `2026-11-10`

## 1. Version decisions

| Component | Pinned image | Reason |
|---|---|---|
| Prometheus | `prom/prometheus:v3.13.5` | Supported LTS release at integration time |
| Node Exporter | `quay.io/prometheus/node-exporter:v1.12.1` | Current official exporter release at integration time |

Both tags passed registry manifest checks. Prometheus configuration was checked
with `promtool` from the same pinned Prometheus image.

References:

- <https://prometheus.io/download/>
- <https://prometheus.io/docs/introduction/release-cycle/>
- <https://github.com/prometheus/node_exporter/blob/master/README.md>

## 2. Implemented files

- `monitoring-prometheus-server/prometheus.yml`.
- `monitoring-prometheus-server/README.md`.
- `docker-compose.yml` Stage 3 services.
- `scripts/test-monitoring.ps1` automated B7/E7 acceptance test.
- Web Dockerfile line-ending normalization for the static metrics file.

## 3. Service contract

| Service | IP | Published port | Restart policy |
|---|---|---|---|
| `web-frontend-server` | `10.10.10.10` | `8080:80` | `unless-stopped` |
| `node-exporter` | `10.10.10.60` | None | `unless-stopped` |
| `monitoring-prometheus-server` | `10.10.10.61` | `9090:9090` | `unless-stopped` |

Node Exporter joins `cloud-net`, uses host PID namespace and mounts the Docker
Linux host root read-only at `/host`. Port 9100 is reachable only inside the
Docker network.

## 4. Prometheus scrape jobs

| Job | Target | Result |
|---|---|---|
| `node` | `node-exporter:9100` | UP |
| `web` | `web-frontend-server:80/metrics` | UP |

Prometheus uses a 15-second scrape/evaluation interval and 10-second scrape
timeout. The Web job specifies `PrometheusText0.0.4` as fallback protocol for
the static text exposition endpoint.

## 5. Validation performed

Passed checks:

- Docker Compose rendered successfully.
- `promtool check config` returned SUCCESS.
- Web image built from source.
- `nginx -t` returned successful configuration validation.
- All three Stage 3 containers are running.
- All three containers have the required static IPs in `cloud-net`.
- All three use `restart: unless-stopped`.
- Node Exporter has no host port binding.
- Prometheus has named volume `myminicloud_prometheus_data` mounted at
  `/prometheus`.
- Prometheus remained functional after container restart.
- The automated monitoring acceptance test passed before and after restart.

Acceptance result:

```text
node -> http://node-exporter:9100/metrics is UP
web  -> http://web-frontend-server:80/metrics is UP
node_cpu_seconds_total: 96 series returned
web_up: 1
```

## 6. Cross-platform corrections

### Docker bind propagation

Docker Desktop rejected `rslave` propagation for its root filesystem mount.
The final Stage 3 configuration uses a read-only root bind without propagation.
This exposes the metrics required by the assignment on Docker Desktop and EC2.
New nested mounts created after Node Exporter starts may require restarting the
exporter.

### Prometheus static metric line endings

Windows checked the extensionless `html/metrics` file out with CRLF. Prometheus
then rejected the metric type as `gauge\r`. The Web Dockerfile now normalizes the
file to LF during image build, making the image reproducible regardless of each
member's Git line-ending settings.

## 7. Environment interpretation

On Docker Desktop for Windows, Node Exporter monitors Docker's Linux VM, not the
native Windows host. On AWS EC2/Linux, the same configuration monitors the EC2
Linux host, which is the final deployment target.

## 8. Remaining evidence work

Technical acceptance is complete. During the evidence/report stage, capture:

- `B7_prometheus_node_target.png` showing Node Exporter UP.
- `B7_prometheus_cpu_query.png` showing `node_cpu_seconds_total` data.
- `E7_prometheus_web_target.png` showing Web UP.
- A terminal capture of `scripts/test-monitoring.ps1` passing.

Do not treat this Markdown audit as a substitute for the screenshots required
in the final report.
