# Stage 5 - Gateway and Round Robin Audit

> Integrator: Trung Nguyên - `52400141`
> Branch: `Nguyen`
> Validation date: `2026-11-10`

## 1. Implemented scope

Stage 5 adds the services required to test the gateway end to end:

| Service | Image | Static IP | Published port |
|---|---|---|---|
| `web-frontend-server` | `myminicloud-web:stage3` | `10.10.10.10` | `8080:80` |
| `web-frontend-server2` | `myminicloud-web2:stage5` | `10.10.10.11` | None |
| `application-backend-server` | `myminicloud-backend:stage5` | `10.10.10.20` | `8085:8081` |
| `authentication-identity-server` | `quay.io/keycloak/keycloak:26.8.2` | `10.10.10.40` | `8081:8080` |
| `api-gateway-proxy-server` | `nginx:1.30.6-alpine` | `10.10.10.70` | `80:80` |

All five services use `restart: unless-stopped` and join `cloud-net`. Web 2 is
internal-only. Keycloak uses the named volume `myminicloud_keycloak_data` so
the identity database survives container recreation.

Both Web Dockerfiles use the explicit base `nginx:1.30.6`; the Gateway uses
the matching Alpine tag. Both exact tags passed registry pull/manifest
resolution before the final build.

## 2. Gateway routing contract

| Public route | Upstream request | Runtime result |
|---|---|---|
| `/` | Round-robin `web-frontend-server:80` and `web-frontend-server2:80` | HTTP 200 |
| `/api/hello` | `application-backend-server:8081/hello` | `Hello from App Server!` |
| `/auth/` | `authentication-identity-server:8080/` | HTTP 302 |
| `/student/` | `application-backend-server:8081/student` | HTTP 200, five records |

The trailing slash in `proxy_pass http://application_backend/` removes the
`/api/` prefix. The exact-match `/student/` location maps explicitly to
`/student`, preventing a trailing-slash 404. The `/auth` route normalizes to
`/auth/` before proxying.

## 3. B9 validation

Observed results:

```text
GET /           -> HTTP 200
GET /api/hello  -> {"message":"Hello from App Server!"}
GET /auth/      -> HTTP 302
Location        -> http://localhost/auth/admin/
```

Nginx configuration validation also passed:

```text
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

## 4. E9 validation

`GET /student/` returned HTTP 200 with exactly five JSON records. Every record
contains `id`, `name`, `major` and `gpa`. No direct database or identity-server
dependency is required by this static Flask endpoint.

## 5. E10 validation

Nginx's default upstream algorithm is round-robin. Web 1 and Web 2 contain
distinct visible markers. The lab Gateway deliberately uses one worker because
round-robin state is maintained per worker; this makes the short E10 sequence
deterministic. Six consecutive acceptance-test requests produced:

```text
Server 1 -> Server 2 -> Server 1 -> Server 2 -> Server 1 -> Server 2
```

An earlier eight-request run produced the same alternating pattern. Gateway
access logs independently recorded alternating upstream addresses
`10.10.10.10:80` and `10.10.10.11:80`.

## 6. Automated acceptance test

Run after the services are started:

```powershell
./scripts/test-gateway.ps1 -RoundRobinRequests 6
```

The script validates:

- readiness of Nginx, Flask and Keycloak;
- root HTTP status and Web identity;
- `/api/` prefix removal;
- the non-followed Keycloak 302 response and Location header;
- five student records and all required fields;
- access to both Web servers with a strictly alternating sequence.

The script supports Windows PowerShell 5.1 and PowerShell 7. It uses bounded
HTTP timeouts so an unavailable upstream cannot hold the test indefinitely.

## 7. Restart verification

The Gateway container was restarted independently. After restart:

- `nginx -t` passed again;
- B9, E9 and E10 all passed again;
- all upstream services remained reachable.

## 8. Remaining evidence work

Technical acceptance is complete. During Stage 7, capture:

- `B9_gateway_routes.png` showing the three B9 route results;
- `E9_gateway_student.png` showing all five JSON records;
- `E10_round_robin.png` showing both server identities in sequence;
- a terminal capture of `scripts/test-gateway.ps1` passing.

Do not expose environment passwords or Keycloak administrator credentials in
the screenshots.
