#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if ! command -v docker >/dev/null 2>&1; then echo 'Khong tim thay docker'; exit 1; fi
python3 scripts/setup_local.py
if ! docker info >/dev/null 2>&1; then echo 'Docker Engine khong san sang'; exit 1; fi
docker compose --env-file .env config --quiet
docker compose --env-file .env up -d --build
docker compose --env-file .env ps
python3 scripts/provision_demo.py
printf '%s\n' 'Website/Gateway: http://localhost/' 'Smoke test: python3 scripts/verify_local.py'
