# API Gateway, Reverse Proxy and Load Balancer

The Nginx gateway is the public entry point for Stage 5 and listens on host
port `80`. It joins `cloud-net` at `10.10.10.70` and calls every upstream by
Docker service name.

## Route contract

| Public route | Internal destination | Expected result |
|---|---|---|
| `/` | `web_pool` | Round-robin Web 1 and Web 2 |
| `/api/hello` | `application-backend-server:8081/hello` | Flask greeting JSON |
| `/auth/` | `authentication-identity-server:8080/` | Keycloak redirect |
| `/student/` | `application-backend-server:8081/student` | Five-student JSON |

`web_pool` deliberately has no balancing directive because Nginx uses
round-robin by default. Web 1 contains `Server 1` and Web 2 contains
`Server 2`, making the distribution observable. The lab Gateway uses one
worker so a short six-request E10 capture alternates deterministically; a
high-throughput production deployment can restore `worker_processes auto`.

## Validate and run

```powershell
docker run --rm `
  --mount "type=bind,src=$((Resolve-Path ./api-gateway-proxy-server/nginx.conf)),dst=/etc/nginx/nginx.conf,readonly" `
  nginx:1.30.6-alpine nginx -t

docker compose --env-file .env up -d api-gateway-proxy-server
./scripts/test-gateway.ps1
```

Use a real local `.env`; never place passwords in this configuration or in
screenshots.
