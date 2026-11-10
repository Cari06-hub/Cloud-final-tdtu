[CmdletBinding()]
param(
    [string]$EnvFile = ".env",
    [string]$OutputDirectory = "docs/evidence/moi"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Net.Http

function Read-DotEnv {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Environment file does not exist: $Path"
    }
    $values = @{}
    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith("#")) {
            continue
        }
        $parts = $trimmed -split "=", 2
        if ($parts.Count -eq 2) {
            $values[$parts[0].Trim()] = $parts[1].Trim()
        }
    }
    return $values
}

function Get-RequiredValue {
    param(
        [Parameter(Mandatory)][hashtable]$Values,
        [Parameter(Mandatory)][string]$Name
    )

    $value = $Values[$Name]
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "Missing required environment value: $Name"
    }
    return $value
}

function Invoke-PlaywrightScreenshot {
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$OutputPath,
        [int]$WaitMilliseconds = 4000,
        [string]$StoragePath,
        [switch]$FullPage,
        [string]$Viewport = "1600,1000"
    )

    $arguments = @(
        "--yes", "playwright", "screenshot",
        "--channel", "chrome",
        "--viewport-size", $Viewport,
        "--timezone", "Asia/Ho_Chi_Minh",
        "--wait-for-timeout", $WaitMilliseconds.ToString()
    )
    if ($StoragePath) {
        $arguments += @("--load-storage", $StoragePath)
    }
    if ($FullPage) {
        $arguments += "--full-page"
    }
    $arguments += @($Url, $OutputPath)
    $npxCmd = Get-Command "npx.cmd" -ErrorAction SilentlyContinue
    if (-not $npxCmd) { $npxCmd = Get-Command "npx" -ErrorAction SilentlyContinue }
    if (-not $npxCmd) {
        throw "Khong tim thay npx tren PATH. Cai Node.js neu can tu dong chup anh bang Playwright."
    }
    & $npxCmd.Source @arguments
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $OutputPath)) {
        throw "Screenshot failed: $OutputPath"
    }
}

function New-TerminalEvidenceHtml {
    param(
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][array]$Sections,
        [Parameter(Mandatory)][string]$Path
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
    $sectionHtml = foreach ($section in $Sections) {
        $command = [Net.WebUtility]::HtmlEncode([string]$section.Command)
        $output = [Net.WebUtility]::HtmlEncode([string]$section.Output)
        "<section><div class='prompt'>PowerShell [MyMiniCloud]&gt; $command</div><pre>$output</pre></section>"
    }
    $safeTitle = [Net.WebUtility]::HtmlEncode($Title)
    $html = @"
<!doctype html>
<html lang="vi">
<head>
<meta charset="utf-8">
<title>$safeTitle</title>
<style>
body{margin:0;background:#0c111b;color:#e6edf3;font:20px/1.5 Consolas,monospace}
header{padding:28px 42px;background:#161b22;border-bottom:1px solid #30363d}
h1{margin:0 0 8px;color:#58a6ff;font:700 30px Segoe UI,sans-serif}
.meta{color:#8b949e;font:16px Segoe UI,sans-serif}
main{padding:28px 42px}section{margin:0 0 24px;border:1px solid #30363d;border-radius:8px;overflow:hidden}
.prompt{padding:14px 18px;background:#21262d;color:#7ee787;white-space:pre-wrap}
pre{margin:0;padding:18px;background:#0d1117;color:#f0f6fc;white-space:pre-wrap;word-break:break-word}
.pass{color:#3fb950}
</style>
</head>
<body><header><h1>$safeTitle</h1><div class="meta">Local evidence - $timestamp - MyMiniCloud final integrated</div></header>
<main>$($sectionHtml -join "`n")</main></body></html>
"@
    [IO.File]::WriteAllText($Path, $html, [Text.UTF8Encoding]::new($false))
}

$config = Read-DotEnv -Path $EnvFile
$grafanaUser = Get-RequiredValue -Values $config -Name "GF_SECURITY_ADMIN_USER"
$grafanaPassword = Get-RequiredValue -Values $config -Name "GF_SECURITY_ADMIN_PASSWORD"
$output = New-Item -ItemType Directory -Path $OutputDirectory -Force
$outputPath = $output.FullName

Write-Host "[1/8] Capturing Prometheus Node target..."
$targetsUrl = "http://localhost:9090/targets"
Invoke-PlaywrightScreenshot `
    -Url $targetsUrl `
    -OutputPath (Join-Path $outputPath "B7_prometheus_node_target.png") `
    -WaitMilliseconds 3000 `
    -FullPage

Write-Host "[2/8] Capturing Prometheus CPU query..."
$cpuUrl = "http://localhost:9090/query?g0.expr=node_cpu_seconds_total&g0.tab=table&g0.show_exemplars=0&g0.range_input=1h"
Invoke-PlaywrightScreenshot `
    -Url $cpuUrl `
    -OutputPath (Join-Path $outputPath "B7_prometheus_cpu_query.png") `
    -WaitMilliseconds 4000

Write-Host "[3/8] Capturing Prometheus Web target..."
Invoke-PlaywrightScreenshot `
    -Url $targetsUrl `
    -OutputPath (Join-Path $outputPath "E7_prometheus_web_target.png") `
    -WaitMilliseconds 3000 `
    -FullPage

Write-Host "[4/8] Creating an authenticated Grafana browser state..."
$grafanaBaseUri = [Uri]"http://localhost:3000"
$loginBody = @{
    user = $grafanaUser
    password = $grafanaPassword
} | ConvertTo-Json -Compress
$loginResponse = Invoke-WebRequest `
    -Method Post `
    -Uri "http://localhost:3000/login" `
    -ContentType "application/json" `
    -Body $loginBody `
    -SessionVariable grafanaSession `
    -UseBasicParsing `
    -TimeoutSec 20
if ($loginResponse.StatusCode -ne 200) {
    throw "Grafana login failed."
}
$cookies = @()
foreach ($cookie in $grafanaSession.Cookies.GetCookies($grafanaBaseUri)) {
    $cookies += @{
        name = $cookie.Name
        value = $cookie.Value
        domain = "localhost"
        path = $cookie.Path
        expires = -1
        httpOnly = $cookie.HttpOnly
        secure = $cookie.Secure
        sameSite = "Lax"
    }
}
if ($cookies.Count -lt 1) {
    throw "Grafana login returned no session cookie."
}
$statePath = Join-Path $env:TEMP "myminicloud-grafana-$PID.json"
$state = @{ cookies = $cookies; origins = @() } | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText($statePath, $state, [Text.UTF8Encoding]::new($false))

try {
    Write-Host "[5/8] Capturing Node Exporter Full..."
    $unameQuery = [Uri]::EscapeDataString("node_uname_info")
    $unameResponse = Invoke-RestMethod `
        -Uri "http://localhost:9090/api/v1/query?query=$unameQuery" `
        -TimeoutSec 15
    $nodeName = $unameResponse.data.result[0].metric.nodename
    if ([string]::IsNullOrWhiteSpace($nodeName)) {
        throw "Could not determine the Node Exporter nodename."
    }
    $encodedNodeName = [Uri]::EscapeDataString($nodeName)
    $nodeDashboardUrl = "http://localhost:3000/d/rYdddlPWk/node-exporter-full?orgId=1&from=now-15m&to=now&timezone=browser&var-job=node&var-nodename=$encodedNodeName&var-node=node-exporter%3A9100&refresh=15s"
    Invoke-PlaywrightScreenshot `
        -Url $nodeDashboardUrl `
        -OutputPath (Join-Path $outputPath "B8_grafana_node_exporter_full.png") `
        -StoragePath $statePath `
        -WaitMilliseconds 12000 `
        -Viewport "1800,1100"

    Write-Host "[6/8] Capturing System Health of 52400141..."
    $systemDashboardUrl = "http://localhost:3000/d/system-health-52400141/system-health-of-52400141?orgId=1&from=now-15m&to=now&timezone=browser&refresh=15s"
    Invoke-PlaywrightScreenshot `
        -Url $systemDashboardUrl `
        -OutputPath (Join-Path $outputPath "E8_system_health_52400141.png") `
        -StoragePath $statePath `
        -WaitMilliseconds 10000 `
        -Viewport "1800,1000"
} finally {
    if (Test-Path -LiteralPath $statePath) {
        Remove-Item -LiteralPath $statePath -Force
    }
}

Write-Host "[7/8] Capturing Gateway route and student evidence..."
$rootHeaders = (curl.exe -sS -I --max-time 10 "http://localhost/") -join "`n"
$helloJson = curl.exe -sS --max-time 10 "http://localhost/api/hello"
$authHeaders = (curl.exe -sS -I --max-time 10 "http://localhost/auth/") -join "`n"
$b9Html = Join-Path $outputPath "B9_gateway_routes.html"
New-TerminalEvidenceHtml `
    -Title "B9 - API Gateway Routes" `
    -Path $b9Html `
    -Sections @(
        @{ Command = "curl -I http://localhost/"; Output = $rootHeaders },
        @{ Command = "curl http://localhost/api/hello"; Output = $helloJson },
        @{ Command = "curl -I http://localhost/auth/"; Output = $authHeaders }
    )

$students = Invoke-RestMethod -Uri "http://localhost/student/" -TimeoutSec 10
$studentJson = $students | ConvertTo-Json -Depth 8
$e9Html = Join-Path $outputPath "E9_gateway_student.html"
New-TerminalEvidenceHtml `
    -Title "E9 - Gateway Student JSON" `
    -Path $e9Html `
    -Sections @(
        @{ Command = "curl http://localhost/student/"; Output = $studentJson }
    )

Write-Host "[8/8] Capturing deterministic Round Robin evidence..."
$sequence = @()
for ($index = 1; $index -le 6; $index++) {
    $body = (curl.exe -sS --max-time 10 "http://localhost/") -join "`n"
    $match = [regex]::Match($body, "Server [12]")
    if (-not $match.Success) {
        throw "Round Robin request $index has no server marker."
    }
    $sequence += "Request $index -> $($match.Value)"
}
$e10Html = Join-Path $outputPath "E10_round_robin.html"
New-TerminalEvidenceHtml `
    -Title "E10 - Nginx Round Robin" `
    -Path $e10Html `
    -Sections @(
        @{
            Command = "1..6 | ForEach-Object { curl http://localhost/ | Select-String 'Server [12]' }"
            Output = $sequence -join "`n"
        }
    )

foreach ($item in @(
    @{ Html = $b9Html; Image = "B9_gateway_routes.png" },
    @{ Html = $e9Html; Image = "E9_gateway_student.png" },
    @{ Html = $e10Html; Image = "E10_round_robin.png" }
)) {
    $filePath = (Resolve-Path -LiteralPath $item.Html).Path.Replace("\", "/")
    $fileUri = "file:///$filePath"
    Invoke-PlaywrightScreenshot `
        -Url $fileUri `
        -OutputPath (Join-Path $outputPath $item.Image) `
        -WaitMilliseconds 500 `
        -FullPage
}

Write-Host "Evidence capture PASSED." -ForegroundColor Green
Get-ChildItem -LiteralPath $outputPath -Filter "*.png" |
    Sort-Object Name |
    Select-Object Name, Length
