# Prometheus and Node Exporter

## Integrated versions

| Component | Image |
|---|---|
| Prometheus | `prom/prometheus:v3.13.5` |
| Node Exporter | `quay.io/prometheus/node-exporter:v1.12.1` |

Prometheus uses an LTS release. Both image tags were checked in their registries
before integration. Do not replace them with `latest` without rerunning the full
monitoring test.

Official references:

- <https://prometheus.io/download/>
- <https://github.com/prometheus/node_exporter/blob/master/README.md>
- <https://prometheus.io/docs/prometheus/latest/configuration/configuration/>

## Scrape contract

| Job | Target | Metrics path | Acceptance |
|---|---|---|---|
| `node` | `node-exporter:9100` | `/metrics` | Target UP and `node_cpu_seconds_total` exists |
| `web` | `web-frontend-server:80` | `/metrics` | Target UP and `web_up == 1` |

Prometheus and Node Exporter communicate only over `cloud-net`. Node Exporter
port 9100 is intentionally not published to the host or Internet.

## Host metric behavior

Node Exporter is configured with:

```text
pid: host
/:/host:ro
--path.rootfs=/host
```

On AWS EC2/Linux this exposes metrics for the EC2 host. On Docker Desktop for
Windows, containers run inside a Linux VM, so Node Exporter reports the Docker
Linux VM rather than native Windows host metrics. This is expected and does not
affect the EC2 deployment objective. Bind propagation is intentionally omitted
because Docker Desktop rejects `rslave` on its root mount. Existing host mounts
remain visible; newly created nested mounts may require restarting Node Exporter.

## Validate configuration

```bash
docker run --rm \
  --entrypoint promtool \
  -v "${PWD}/monitoring-prometheus-server/prometheus.yml:/etc/prometheus/prometheus.yml:ro" \
  prom/prometheus:v3.13.5 \
  check config /etc/prometheus/prometheus.yml
```

PowerShell:

```powershell
docker run --rm `
  --entrypoint promtool `
  -v "${PWD}/monitoring-prometheus-server/prometheus.yml:/etc/prometheus/prometheus.yml:ro" `
  prom/prometheus:v3.13.5 `
  check config /etc/prometheus/prometheus.yml
```

## Start Stage 3 stack

```bash
docker compose config --quiet
docker compose up -d --build web-frontend-server node-exporter monitoring-prometheus-server
docker compose ps
```

## Automated acceptance test

PowerShell:

```powershell
./scripts/test-monitoring.ps1
```

Manual endpoints:

```text
http://localhost:8080/metrics
http://localhost:9090/-/ready
http://localhost:9090/targets
```

Required PromQL:

```promql
node_cpu_seconds_total
```

```promql
web_up
```

## Persistence and cleanup

Prometheus data is stored in named volume `prometheus_data` at `/prometheus`.

Stop containers while retaining data:

```bash
docker compose stop monitoring-prometheus-server node-exporter web-frontend-server
```

Do not use `docker compose down -v` unless the group intentionally wants to
delete all monitoring history and other named volumes in the project.
