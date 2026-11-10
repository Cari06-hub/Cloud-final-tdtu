[CmdletBinding()]
param(
    [int]$TimeoutSeconds = 180,
    [string]$EnvFile = ".env",
    [string]$GrafanaAdminUser = $env:GF_SECURITY_ADMIN_USER,
    [string]$GrafanaAdminPassword = $env:GF_SECURITY_ADMIN_PASSWORD
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($GrafanaAdminUser)) {
    $GrafanaAdminUser = "admin"
}
if ([string]::IsNullOrWhiteSpace($GrafanaAdminPassword)) {
    throw "Provide -GrafanaAdminPassword or set GF_SECURITY_ADMIN_PASSWORD."
}
if (-not (Test-Path -LiteralPath $EnvFile)) {
    throw "Environment file does not exist: $EnvFile"
}

$expectedServices = [ordered]@{
    "web-frontend-server" = "10.10.10.10"
    "web-frontend-server2" = "10.10.10.11"
    "application-backend-server" = "10.10.10.20"
    "relational-database-server" = "10.10.10.25"
    "object-storage-server" = "10.10.10.30"
    "authentication-identity-server" = "10.10.10.40"
    "internal-dns-server" = "10.10.10.50"
    "node-exporter" = "10.10.10.60"
    "monitoring-prometheus-server" = "10.10.10.61"
    "monitoring-grafana-dashboard-server" = "10.10.10.62"
    "api-gateway-proxy-server" = "10.10.10.70"
}

$volumeContracts = [ordered]@{
    "relational-database-server" = @("/var/lib/mysql", "mariadb_data")
    "authentication-identity-server" = @("/opt/keycloak/data", "keycloak_data")
    "object-storage-server" = @("/bitnami/minio/data", "minio_data")
    "monitoring-prometheus-server" = @("/prometheus", "prometheus_data")
    "monitoring-grafana-dashboard-server" = @("/var/lib/grafana", "grafana_data")
}

function Get-ContainerInspection {
    param([Parameter(Mandatory)][string]$Name)

    $raw = docker inspect $Name 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Container does not exist: $Name"
    }
    return ($raw | ConvertFrom-Json)[0]
}

Write-Host "[1/8] Validating the rendered Compose service list..."
$composeServices = @(docker compose --env-file $EnvFile config --services)
if ($LASTEXITCODE -ne 0) {
    throw "docker compose config failed."
}
if ($composeServices.Count -ne 11) {
    throw "Expected 11 Compose services, found $($composeServices.Count)."
}
foreach ($name in $expectedServices.Keys) {
    if ($name -notin $composeServices) {
        throw "Compose is missing service: $name"
    }
}

Write-Host "[2/8] Checking state, IP and restart policy for 11 containers..."
foreach ($entry in $expectedServices.GetEnumerator()) {
    $container = Get-ContainerInspection -Name $entry.Key
    if (-not $container.State.Running) {
        throw "Container is not running: $($entry.Key)"
    }
    if ($container.HostConfig.RestartPolicy.Name -ne "unless-stopped") {
        throw "Incorrect restart policy: $($entry.Key)"
    }
    $network = $container.NetworkSettings.Networks."cloud-net"
    if ($null -eq $network -or $network.IPAddress -ne $entry.Value) {
        throw "Incorrect cloud-net IP for $($entry.Key): $($network.IPAddress)"
    }
    Write-Host "  PASS: $($entry.Key) -> $($entry.Value)"
}

Write-Host "[3/8] Checking named-volume contracts..."
foreach ($entry in $volumeContracts.GetEnumerator()) {
    $container = Get-ContainerInspection -Name $entry.Key
    $destination = $entry.Value[0]
    $volumeSuffix = $entry.Value[1]
    $mount = $container.Mounts | Where-Object {
        $_.Type -eq "volume" -and $_.Destination -eq $destination
    } | Select-Object -First 1
    if ($null -eq $mount -or $mount.Name -notlike "*$volumeSuffix") {
        throw "Missing $volumeSuffix mount for $($entry.Key)."
    }
    Write-Host "  PASS: $($mount.Name) -> $destination"
}

Write-Host "[4/8] Checking non-public infrastructure ports..."
$web2 = Get-ContainerInspection -Name "web-frontend-server2"
$database = Get-ContainerInspection -Name "relational-database-server"
$exporter = Get-ContainerInspection -Name "node-exporter"
if ($null -ne $web2.NetworkSettings.Ports."80/tcp") {
    throw "Web 2 unexpectedly publishes host port 80."
}
if ($null -ne $database.NetworkSettings.Ports."3306/tcp") {
    throw "MariaDB unexpectedly publishes host port 3306."
}
if ($null -ne $exporter.NetworkSettings.Ports."9100/tcp") {
    throw "Node Exporter unexpectedly publishes host port 9100."
}

Write-Host "[5/8] Checking authoritative DNS records..."
foreach ($entry in $expectedServices.GetEnumerator()) {
    $answer = docker exec internal-dns-server `
        dig +short '@127.0.0.1' "$($entry.Key).cloud.local" A
    if ($LASTEXITCODE -ne 0 -or $answer.Trim() -ne $entry.Value) {
        throw "DNS mismatch for $($entry.Key): $answer"
    }
}

Write-Host "[6/8] Checking MariaDB and MinIO application paths..."
$databaseRows = @(
    (Invoke-RestMethod `
        -Uri "http://localhost:8085/students-db" `
        -TimeoutSec 15) | ForEach-Object { $_ }
)
if ($databaseRows.Count -ne 5) {
    throw "Expected 5 database students, found $($databaseRows.Count)."
}
$minioHealth = Invoke-WebRequest `
    -Uri "http://localhost:9000/minio/health/live" `
    -UseBasicParsing `
    -TimeoutSec 15
if ($minioHealth.StatusCode -ne 200) {
    throw "MinIO health endpoint is not HTTP 200."
}

Write-Host "[7/8] Running monitoring and dashboard regression tests..."
& "$PSScriptRoot/test-monitoring.ps1" -TimeoutSeconds $TimeoutSeconds
& "$PSScriptRoot/test-grafana.ps1" `
    -TimeoutSeconds $TimeoutSeconds `
    -AdminUser $GrafanaAdminUser `
    -AdminPassword $GrafanaAdminPassword

Write-Host "[8/8] Running Gateway B9/E9/E10 regression tests..."
& "$PSScriptRoot/test-gateway.ps1" `
    -TimeoutSeconds $TimeoutSeconds `
    -RoundRobinRequests 6

Write-Host "Integrated Compose acceptance test PASSED." -ForegroundColor Green
Write-Host "Containers: 11/11 running on cloud-net"
Write-Host "Persistent volumes: MariaDB, Keycloak, MinIO, Prometheus, Grafana"
Write-Host "Database students: $($databaseRows.Count)"
Write-Host "DNS records: 11/11"
