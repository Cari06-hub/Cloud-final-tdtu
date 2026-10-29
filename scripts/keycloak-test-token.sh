#!/bin/bash
# ============================================================
# Test lấy JWT token từ Keycloak – realm_52400001
# MSSV: 52400001 – Tuấn Anh (TV2)
# ============================================================

REALM="realm_52400001"
CLIENT_ID="flask-app"
KC_URL="http://localhost:8081"

echo "======================================"
echo "  Keycloak Token Test – $REALM"
echo "======================================"

echo ""
echo "[1] Token cho sv01:"
curl -s -X POST "$KC_URL/realms/$REALM/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=$CLIENT_ID" \
  -d "username=sv01" \
  -d "password=Sv01@1234" \
  -d "grant_type=password" | python3 -m json.tool 2>/dev/null || \
  curl -s -X POST "$KC_URL/realms/$REALM/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=$CLIENT_ID" \
  -d "username=sv01" \
  -d "password=Sv01@1234" \
  -d "grant_type=password"

echo ""
echo "[2] Token cho sv02:"
curl -s -X POST "$KC_URL/realms/$REALM/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=$CLIENT_ID" \
  -d "username=sv02" \
  -d "password=Sv02@1234" \
  -d "grant_type=password" | python3 -m json.tool 2>/dev/null || \
  curl -s -X POST "$KC_URL/realms/$REALM/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=$CLIENT_ID" \
  -d "username=sv02" \
  -d "password=Sv02@1234" \
  -d "grant_type=password"

echo ""
echo "======================================"
echo "  Done! Paste access_token vào https://jwt.io để decode"
echo "======================================"
