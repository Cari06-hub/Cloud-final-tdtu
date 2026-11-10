# Stage 2 - Integration Audit

> Integrator: Trung Nguyên - `52400141`
> Branch: `Nguyen`
> Audit date: `2026-11-10`

## 1. Source provenance

TV1 content was imported by path allowlist from:

```text
origin/Quang @ 6885541
```

Allowed TV1 paths:

- `web-frontend-server/`.
- `application-backend-server/`.
- `relational-database-server/`.

The committed `.env` and `docker-compose.tv1.local.yml` were deliberately not
imported. The `Nguyen` branch therefore does not inherit the credential-bearing
TV1 commit as a parent.

TV2 content was imported by path allowlist from:

```text
origin/feature/auth-storage-dns @ 93a721b
```

Allowed TV2 paths:

- `authentication-identity-server/`.
- `object-storage-server/`.
- `internal-dns-server/`.
- `scripts/keycloak-test-token.sh`.
- `scripts/ping-test.sh`.
- `scripts/ping-test.ps1`.
- `test-upload/`.
- `docker-compose.tv2.yml`.

Old evidence images and report drafts were not imported because they may not
match the final integrated configuration.

## 2. TV1 normalization

- Added visible `Server 1` identity to Web 1.
- Preserved `Server 2` identity in Web 2.
- Verified static `/metrics` content contains `web_up 1`.
- Verified Nginx config contains exact `/metrics` location.
- Changed Flask DB connection to read `DB_NAME` instead of hard-coding
  `studentdb`.
- Verified Flask reads OIDC issuer, JWKS URL and audience from environment.
- Verified `students.json` contains five records with required fields.
- Verified SQL creates `minicloud.notes` and `studentdb.students`.
- Verified SQL grants application user access to `studentdb`.

Runtime build and endpoint tests remain scheduled for the integrated Compose
stage because Docker Desktop was not running during this audit.

## 3. TV2 normalization

- Pinned Keycloak to `quay.io/keycloak/keycloak:26.8.2` after manifest check.
- Replaced hard-coded admin values with `.env` interpolation.
- Added `keycloak_data:/opt/keycloak/data`.
- Pinned MinIO to the available archive image
  `bitnamilegacy/minio:2024.6.13` after manifest check.
- Standardized MinIO persistence as
  `minio_data:/bitnami/minio/data`.
- Removed old hard-coded test-user passwords from scripts and documentation.
- Token script now requires `SV01_PASSWORD` and `SV02_PASSWORD` from the local
  environment.
- Corrected `ns.cloud.local` from `10.10.10.1` to DNS container IP
  `10.10.10.50`.
- Updated the DNS serial to `2026111001`.
- Added static IPAM to the isolated TV2 Compose.
- Rewrote Keycloak and MinIO setup documentation to match integrated values.

## 4. Validation results

Passed:

- `docker compose --env-file .env.example -f docker-compose.tv2.yml config`.
- Python syntax compilation for Flask.
- JSON structure check for five students.
- Bash syntax for Keycloak token and ping scripts.
- PowerShell AST syntax for `ping-test.ps1`.
- PDF/JPEG signature checks for test-upload fixtures.
- Static contract checks for Web identity, `/metrics`, DB/OIDC environment,
  SQL schema/grant and DNS records.
- Search for known old credential literals.

Deferred until Docker daemon is running:

- Build Web and Flask images.
- `nginx -t` inside the Web image.
- `named-checkconf` and `named-checkzone` inside the Bind9 image.
- Keycloak/MinIO startup and persistence test.
- Full endpoint and token test.
- Ping test across all eleven final containers.

## 5. Review required from owners

- [ ] TV1 accepts the `Server 1` marker and `DB_NAME` environment change.
- [ ] TV2 accepts Keycloak `26.8.2` and named-volume persistence.
- [ ] TV2 accepts Bitnami legacy MinIO image/path as the reproducible baseline.
- [ ] TV2 confirms the corrected DNS NS address `10.10.10.50`.
- [ ] Group confirms `GROUP_MSSV=52400001` and `realm_52400001`.

These reviews may refine documentation or configuration, but any change must
follow the process in `docs/integration-contract.md`.
