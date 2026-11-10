[CmdletBinding()]
param(
    [int]$TimeoutSeconds = 90,
    [string]$PrometheusBaseUrl = "http://localhost:9090",
    [string]$WebMetricsUrl = "http://localhost:8080/metrics"
)

$ErrorActionPreference = "Stop"

function Wait-HttpOk {
    param(
        [Parameter(Mandatory)]
        [string]$Uri,
        [Parameter(Mandatory)]
        [int]$Timeout
    )

    $deadline = (Get-Date).AddSeconds($Timeout)
    do {
        try {
            $response = Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                return $response
            }
        } catch {
            Start-Sleep -Seconds 2
        }
    } while ((Get-Date) -lt $deadline)

    throw "Timed out waiting for HTTP 200 from $Uri"
}

function Invoke-PrometheusQuery {
    param(
        [Parameter(Mandatory)]
        [string]$Query
    )

    $encoded = [Uri]::EscapeDataString($Query)
    $response = Invoke-RestMethod `
        -Uri "$PrometheusBaseUrl/api/v1/query?query=$encoded" `
        -TimeoutSec 10

    if ($response.status -ne "success") {
        throw "Prometheus query failed: $Query"
    }

    return @($response.data.result)
}

function Wait-PrometheusTargetsUp {
    param(
        [Parameter(Mandatory)]
        [hashtable]$ExpectedTargets,
        [Parameter(Mandatory)]
        [int]$Timeout
    )

    $deadline = (Get-Date).AddSeconds($Timeout)
    do {
        try {
            $targetsResponse = Invoke-RestMethod `
                -Uri "$PrometheusBaseUrl/api/v1/targets" `
                -TimeoutSec 10
            $targets = @($targetsResponse.data.activeTargets)
            $missing = @()

            foreach ($job in $ExpectedTargets.Keys) {
                $target = $targets | Where-Object {
                    $_.labels.job -eq $job -and $_.health -eq "up"
                } | Select-Object -First 1

                if (-not $target) {
                    $missing += $job
                }
            }

            if ($missing.Count -eq 0) {
                return $targets
            }
        } catch {
            # Prometheus may still be starting; retry until the shared deadline.
        }

        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $deadline)

    $details = if ($missing.Count) { $missing -join ", " } else { "unknown" }
    throw "Timed out waiting for required Prometheus targets: $details"
}

Write-Host "[1/5] Waiting for Prometheus readiness..."
Wait-HttpOk -Uri "$PrometheusBaseUrl/-/ready" -Timeout $TimeoutSeconds | Out-Null

Write-Host "[2/5] Checking the Web /metrics endpoint..."
$webResponse = Wait-HttpOk -Uri $WebMetricsUrl -Timeout $TimeoutSeconds
if ($webResponse.Content -notmatch '(?m)^web_up\s+1\s*$') {
    throw "The Web metrics endpoint does not expose 'web_up 1'."
}

Write-Host "[3/5] Checking Prometheus target health..."
$expectedTargets = @{
    node = "node-exporter:9100"
    web = "web-frontend-server:80"
}
$targets = Wait-PrometheusTargetsUp `
    -ExpectedTargets $expectedTargets `
    -Timeout $TimeoutSeconds

foreach ($job in $expectedTargets.Keys) {
    $target = $targets | Where-Object {
        $_.labels.job -eq $job -and $_.health -eq "up"
    } | Select-Object -First 1

    if (-not $target) {
        throw "Required Prometheus target is not UP: $job ($($expectedTargets[$job]))"
    }

    Write-Host "  PASS: $job -> $($target.scrapeUrl) is UP"
}

Write-Host "[4/5] Querying node_cpu_seconds_total..."
$cpuSeries = Invoke-PrometheusQuery -Query "node_cpu_seconds_total"
if ($cpuSeries.Count -lt 1) {
    throw "node_cpu_seconds_total returned no series."
}

Write-Host "[5/5] Querying web_up..."
$webSeries = Invoke-PrometheusQuery -Query "web_up"
$webUp = $webSeries | Where-Object { $_.value[1] -eq "1" } | Select-Object -First 1
if (-not $webUp) {
    throw "web_up did not return value 1."
}

Write-Host "Monitoring acceptance test PASSED." -ForegroundColor Green
Write-Host "CPU series returned: $($cpuSeries.Count)"
Write-Host "Web metric value: $($webUp.value[1])"
