[CmdletBinding()]
param(
    [int]$TimeoutSeconds = 120,
    [string]$GrafanaBaseUrl = "http://localhost:3000",
    [string]$AdminUser = $env:GF_SECURITY_ADMIN_USER,
    [string]$AdminPassword = $env:GF_SECURITY_ADMIN_PASSWORD
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($AdminUser)) {
    $AdminUser = "admin"
}
if ([string]::IsNullOrWhiteSpace($AdminPassword)) {
    throw "Provide -AdminPassword or set GF_SECURITY_ADMIN_PASSWORD."
}

$pair = "${AdminUser}:${AdminPassword}"
$encodedPair = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($pair))
$headers = @{ Authorization = "Basic $encodedPair" }

function Wait-GrafanaHealthy {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        try {
            $health = Invoke-RestMethod -Uri "$GrafanaBaseUrl/api/health" -TimeoutSec 5
            if ($health.database -eq "ok") {
                return
            }
        } catch {
            Start-Sleep -Seconds 2
        }
    } while ((Get-Date) -lt $deadline)

    throw "Timed out waiting for Grafana health."
}

function Invoke-GrafanaPrometheusQuery {
    param(
        [Parameter(Mandatory)]
        [string]$Query
    )

    $encodedQuery = [Uri]::EscapeDataString($Query)
    $uri = "$GrafanaBaseUrl/api/datasources/proxy/uid/prometheus/api/v1/query?query=$encodedQuery"
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -TimeoutSec 15
    if ($response.status -ne "success") {
        throw "Grafana datasource query failed: $Query"
    }
    return @($response.data.result)
}

Write-Host "[1/6] Waiting for Grafana health..."
Wait-GrafanaHealthy

Write-Host "[2/6] Validating the provisioned Prometheus datasource..."
$datasource = Invoke-RestMethod `
    -Uri "$GrafanaBaseUrl/api/datasources/uid/prometheus" `
    -Headers $headers `
    -TimeoutSec 10
if ($datasource.name -ne "Prometheus") {
    throw "Provisioned datasource name is not Prometheus."
}
if ($datasource.url -ne "http://monitoring-prometheus-server:9090") {
    throw "Provisioned datasource URL is incorrect: $($datasource.url)"
}
if (-not $datasource.isDefault) {
    throw "Prometheus is not the default datasource."
}

Write-Host "[3/6] Validating Node Exporter Full..."
$nodeDashboard = Invoke-RestMethod `
    -Uri "$GrafanaBaseUrl/api/dashboards/uid/rYdddlPWk" `
    -Headers $headers `
    -TimeoutSec 10
if ($nodeDashboard.dashboard.title -ne "Node Exporter Full") {
    throw "Node Exporter Full was not provisioned."
}
if (@($nodeDashboard.dashboard.panels).Count -lt 1) {
    throw "Node Exporter Full contains no panels."
}

Write-Host "[4/6] Validating System Health of 52400141..."
$systemDashboard = Invoke-RestMethod `
    -Uri "$GrafanaBaseUrl/api/dashboards/uid/system-health-52400141" `
    -Headers $headers `
    -TimeoutSec 10
$dashboard = $systemDashboard.dashboard
if ($dashboard.title -ne "System Health of 52400141") {
    throw "The personal dashboard title is incorrect."
}
$panels = @($dashboard.panels)
if ($panels.Count -ne 3) {
    throw "Expected exactly 3 personal dashboard panels, found $($panels.Count)."
}

$requiredPanels = @{
    "CPU Usage (%)" = @{
        Unit = "percent"
        Expression = '100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)'
    }
    "Memory Usage (%)" = @{
        Unit = "percent"
        Expression = '100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)'
    }
    "Network Traffic - Receive" = @{
        Unit = "Bps"
        Expression = 'sum by(instance) (rate(node_network_receive_bytes_total{device!="lo"}[5m]))'
    }
}
foreach ($title in $requiredPanels.Keys) {
    $panel = $panels | Where-Object { $_.title -eq $title } | Select-Object -First 1
    if (-not $panel) {
        throw "Missing required panel: $title"
    }
    if ($panel.fieldConfig.defaults.unit -ne $requiredPanels[$title].Unit) {
        throw "Panel unit is incorrect for $title."
    }
    if ($panel.datasource.uid -ne "prometheus") {
        throw "Panel datasource UID is incorrect for $title."
    }
    if (@($panel.targets).Count -ne 1 -or $panel.targets[0].expr -ne $requiredPanels[$title].Expression) {
        throw "Panel PromQL is incorrect for $title."
    }
}

Write-Host "[5/6] Querying CPU, Memory and Network through Grafana..."
$queries = @{
    CPU = '100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)'
    Memory = '100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)'
    Network = 'sum by(instance) (rate(node_network_receive_bytes_total{device!="lo"}[5m]))'
}
foreach ($name in $queries.Keys) {
    # PowerShell unwraps a single pipeline object. Force array semantics so a
    # valid Prometheus vector containing one series is counted as one, not null.
    $series = @(Invoke-GrafanaPrometheusQuery -Query $queries[$name])
    if ($series.Count -lt 1) {
        throw "$name query returned no data through Grafana."
    }
    Write-Host "  PASS: $name returned $($series.Count) series"
}

Write-Host "[6/6] Checking dashboard folder metadata..."
if ($systemDashboard.meta.folderUid -ne "myminicloud") {
    throw "Personal dashboard is not in the MyMiniCloud folder."
}
if ($nodeDashboard.meta.folderUid -ne "myminicloud") {
    throw "Node Exporter Full is not in the MyMiniCloud folder."
}

Write-Host "Grafana acceptance test PASSED." -ForegroundColor Green
Write-Host "Datasource: $($datasource.name) -> $($datasource.url)"
Write-Host "Dashboards: Node Exporter Full; System Health of 52400141"
