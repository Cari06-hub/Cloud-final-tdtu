#!/bin/bash
# ===========================================================
# Ping Test Script – Kiểm tra kết nối tới 11 container
# MyMiniCloud – Tuấn Anh (TV2)
# ===========================================================

NETWORK="cloud-net"

CONTAINERS=(
    "web-frontend-server"
    "web-frontend-server2"
    "application-backend-server"
    "relational-database-server"
    "authentication-identity-server"
    "object-storage-server"
    "internal-dns-server"
    "monitoring-prometheus-server"
    "node-exporter"
    "monitoring-grafana-dashboard-server"
    "api-gateway-proxy-server"
)

echo "=============================================="
echo "  MyMiniCloud – Ping Test (${#CONTAINERS[@]} containers)"
echo "  Network: $NETWORK"
echo "  Thời gian: $(date)"
echo "=============================================="
echo ""

PASS=0
FAIL=0

for container in "${CONTAINERS[@]}"; do
    echo "----------------------------------------------"
    echo "[TEST] Ping tới: $container"
    echo "----------------------------------------------"

    docker run --rm --network "$NETWORK" busybox ping -c 3 "$container"

    if [ $? -eq 0 ]; then
        echo "[✔] $container – KẾT NỐI THÀNH CÔNG"
        ((PASS++))
    else
        echo "[✘] $container – KẾT NỐI THẤT BẠI"
        ((FAIL++))
    fi
    echo ""
done

echo "=============================================="
echo "  KẾT QUẢ TỔNG HỢP"
echo "  Thành công: $PASS / ${#CONTAINERS[@]}"
echo "  Thất bại:   $FAIL / ${#CONTAINERS[@]}"
echo "=============================================="

if [ $FAIL -gt 0 ]; then
    exit 1
fi

exit 0
