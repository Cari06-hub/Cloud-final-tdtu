#!/usr/bin/env bash
set -euo pipefail

# Test token cho Realm của nhóm. Không hard-code mật khẩu test trong Git.
GROUP_MSSV="${GROUP_MSSV:-52400001}"
REALM="${KEYCLOAK_REALM:-realm_${GROUP_MSSV}}"
CLIENT_ID="${OIDC_AUDIENCE:-flask-app}"
KC_URL="${KEYCLOAK_BASE_URL:-http://localhost:8081}"

: "${SV01_PASSWORD:?Set SV01_PASSWORD in the environment or local .env}"
: "${SV02_PASSWORD:?Set SV02_PASSWORD in the environment or local .env}"

request_token() {
  local username="$1"
  local password="$2"

  curl --fail-with-body --silent --show-error \
    --request POST \
    "${KC_URL}/realms/${REALM}/protocol/openid-connect/token" \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "client_id=${CLIENT_ID}" \
    --data-urlencode "username=${username}" \
    --data-urlencode "password=${password}" \
    --data-urlencode "grant_type=password"
}

echo "======================================"
echo "  Keycloak Token Test – $REALM"
echo "======================================"

echo ""
echo "[1] Token cho sv01 (hãy che token khi chụp ảnh):"
request_token "sv01" "${SV01_PASSWORD}" | python3 -m json.tool

echo ""
echo "[2] Token cho sv02 (hãy che token khi chụp ảnh):"
request_token "sv02" "${SV02_PASSWORD}" | python3 -m json.tool

echo ""
echo "======================================"
echo "  Hoàn tất. Không lưu hoặc commit access_token."
echo "======================================"
