# Stage 7 - Local Integration Test and Evidence Audit

> Integrator: Trung Nguyen - `52400141`
>
> Branch: `Nguyen`
>
> Validation date: `2026-11-11`

## 1. Scope and result

The final local stack was validated against the complete assignment matrix,
not only the TV3 services. All 20 tests passed:

```text
PASS: 20 / 20
FAIL: 0 / 20
Integration smoke test PASSED.
```

The reproducible log is stored at
`docs/evidence/local/stage-7-smoke-test.log`. The validation stack contained
all eleven required containers on `cloud-net`.

## 2. Reproducible preparation

Run the following from the repository root after creating a private `.env`
from `.env.example` and replacing every placeholder:

```powershell
docker compose --env-file .env up -d
./scripts/provision-demo.ps1 -EnvFile .env
bash ./scripts/smoke-test.sh .env
./scripts/capture-evidence.ps1 -EnvFile .env
```

`scripts/provision-demo.ps1` is idempotent. It prepares and verifies the demo
state required by the assignment:

- Keycloak realm `realm_52400001`, client `flask-app`, audience mapper, and
  users `sv01` and `sv02`;
- a valid access token and HTTP 200 response from Flask `/secure` for both
  students;
- MinIO object `demo/index.html`;
- public object `profile-pics/avatar.jpg`;
- private bucket object `documents/document.pdf`.

Credentials are read from the selected environment file. The script does not
embed or print passwords, access tokens, access keys, or client secrets.

## 3. Automated matrix

`scripts/smoke-test.sh` covers every basic and extended assignment item:

| Group | Covered checks | Result |
|---|---|---|
| B1-B3 | Web/Blog, direct versus Gateway API, MariaDB sample | Passed |
| B4-B6 | Keycloak user, MinIO demo object, Web DNS record | Passed |
| B7-B8 | Node target, CPU metric, Grafana CPU/RAM/Network | Passed |
| B9-B10 | Gateway routes and connectivity of 11 containers | Passed |
| E1-E3 | Three blog posts, five JSON students, five DB students | Passed |
| E4-E6 | OIDC audience and `/secure`, MinIO objects, extended DNS | Passed |
| E7-E8 | Web target and three-panel personal dashboard | Passed |
| E9-E10 | Gateway student JSON and six-request round robin | Passed |

The runner exits non-zero when any test fails. It supports native Linux Docker
and the Windows `docker.exe` fallback when invoked from WSL without Docker
Desktop WSL integration.

## 4. Evidence inventory

All required TV3 evidence is stored under `docs/evidence/local/`:

| Requirement | Evidence file | Verified content |
|---|---|---|
| B7 | `B7_prometheus_node_target.png` | Node target is `UP` |
| B7 | `B7_prometheus_cpu_query.png` | `node_cpu_seconds_total` returns series |
| B8 | `B8_grafana_node_exporter_full.png` | CPU, RAM and network panels contain data |
| B9 | `B9_gateway_routes.png` | `/`, `/api/hello`, `/auth/` return expected results |
| E7 | `E7_prometheus_web_target.png` | Web target is `UP` |
| E8 | `E8_system_health_52400141.png` | Personal CPU, Memory and Network panels contain data |
| E9 | `E9_gateway_student.png` | Gateway returns the five-student JSON array |
| E10 | `E10_round_robin.png` | Six requests alternate Server 1 and Server 2 |

The HTML files beside the B9, E9 and E10 screenshots are deterministic
evidence pages produced by `scripts/capture-evidence.ps1`. They preserve the
exact command and response shown in each image.

## 5. Visual and security review

Each final PNG was inspected at original resolution. URLs or commands, target
names, dashboard titles, panel names and results remain readable and are not
cropped. The screenshots show the final running configuration and contain no
password, bearer token, MinIO access key, private key, or AWS credential.

Grafana authentication state is written only to a temporary file outside the
repository while Playwright captures the dashboards. The capture script
removes that temporary state in its cleanup block.

## 6. Local credential note

The committed smoke log was produced with the disposable placeholder values
from `.env.example` on an isolated local stack. This demonstrates functional
coverage only. Before a live demo or EC2 deployment, create an untracked `.env`
with strong unique values and rerun provisioning, the 20-test matrix, and the
evidence capture.
