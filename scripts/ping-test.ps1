$NETWORK = "cloud-net"

$CONTAINERS = @(
    "web-frontend-server",
    "web-frontend-server2",
    "application-backend-server",
    "relational-database-server",
    "authentication-identity-server",
    "object-storage-server",
    "internal-dns-server",
    "monitoring-prometheus-server",
    "node-exporter",
    "monitoring-grafana-dashboard-server",
    "api-gateway-proxy-server"
)

Write-Host "=============================================="
Write-Host "  MyMiniCloud Ping Test - $($CONTAINERS.Count) containers"
Write-Host "  Network: $NETWORK"
Write-Host "  Time: $(Get-Date)"
Write-Host "=============================================="
Write-Host ""

$PASS = 0
$FAIL = 0

foreach ($container in $CONTAINERS) {
    Write-Host "--- Testing: $container ---"
    docker run --rm --network $NETWORK busybox ping -c 3 $container
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[PASS] $container" -ForegroundColor Green
        $PASS++
    } else {
        Write-Host "[FAIL] $container" -ForegroundColor Red
        $FAIL++
    }
    Write-Host ""
}

Write-Host "=============================================="
Write-Host "  PASS: $PASS / $($CONTAINERS.Count)" -ForegroundColor Green
Write-Host "  FAIL: $FAIL / $($CONTAINERS.Count)" -ForegroundColor Red
Write-Host "=============================================="
