[CmdletBinding()]
param(
    [int]$TimeoutSeconds = 180,
    [string]$GatewayBaseUrl = "http://localhost",
    [int]$RoundRobinRequests = 6
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Net.Http

if ($RoundRobinRequests -lt 4) {
    throw "RoundRobinRequests must be at least 4."
}

function Invoke-WithoutRedirect {
    param([Parameter(Mandatory)][string]$Uri)

    $handler = [System.Net.Http.HttpClientHandler]::new()
    $handler.AllowAutoRedirect = $false
    $client = [System.Net.Http.HttpClient]::new($handler)
    $client.Timeout = [TimeSpan]::FromSeconds(5)
    try {
        return $client.GetAsync($Uri).GetAwaiter().GetResult()
    } finally {
        $client.Dispose()
        $handler.Dispose()
    }
}

function Wait-Stage5Ready {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        try {
            $rootResponse = Invoke-WebRequest `
                -Uri "$GatewayBaseUrl/" `
                -UseBasicParsing `
                -TimeoutSec 5
            $helloResponse = Invoke-RestMethod `
                -Uri "$GatewayBaseUrl/api/hello" `
                -TimeoutSec 5
            $authResponse = Invoke-WithoutRedirect -Uri "$GatewayBaseUrl/auth/"
            try {
                if (
                    $rootResponse.StatusCode -eq 200 -and
                    $helloResponse.message -eq "Hello from App Server!" -and
                    [int]$authResponse.StatusCode -eq 302
                ) {
                    return
                }
            } finally {
                $authResponse.Dispose()
            }
        } catch {
            Start-Sleep -Seconds 2
        }
    } while ((Get-Date) -lt $deadline)

    throw "Timed out waiting for the gateway, Flask and Keycloak upstreams."
}

Write-Host "[1/6] Waiting for the gateway and required upstreams..."
Wait-Stage5Ready

Write-Host "[2/6] Testing the root route..."
$root = Invoke-WebRequest `
    -Uri "$GatewayBaseUrl/" `
    -UseBasicParsing `
    -TimeoutSec 10
if ($root.StatusCode -ne 200 -or $root.Content -notmatch 'Server [12]') {
    throw "Gateway root did not return a Web pool member."
}

Write-Host "[3/6] Testing /api/hello prefix removal..."
$hello = Invoke-RestMethod -Uri "$GatewayBaseUrl/api/hello" -TimeoutSec 10
if ($hello.message -ne "Hello from App Server!") {
    throw "Unexpected /api/hello response."
}

Write-Host "[4/6] Testing the Keycloak redirect..."
$authResponse = Invoke-WithoutRedirect -Uri "$GatewayBaseUrl/auth/"
try {
    $authStatus = [int]$authResponse.StatusCode
    $authLocation = $authResponse.Headers.Location
    if ($authStatus -ne 302) {
        throw "Expected /auth/ HTTP 302, received $authStatus."
    }
    if ($null -eq $authLocation) {
        throw "The /auth/ redirect has no Location header."
    }
} finally {
    $authResponse.Dispose()
}

Write-Host "[5/6] Testing the five-student response..."
$studentResponse = Invoke-RestMethod `
    -Uri "$GatewayBaseUrl/student/" `
    -TimeoutSec 10
# Windows PowerShell 5.1 can preserve a JSON array as one nested pipeline
# object. Enumerate it explicitly so Count is consistent with PowerShell 7.
$students = @($studentResponse | ForEach-Object { $_ })
if ($students.Count -ne 5) {
    throw "Expected 5 students, received $($students.Count)."
}
foreach ($student in $students) {
    foreach ($field in @("id", "name", "major", "gpa")) {
        if ($null -eq $student.$field) {
            throw "A student record is missing field '$field'."
        }
    }
}

Write-Host "[6/6] Proving round-robin distribution..."
$sequence = @()
for ($index = 1; $index -le $RoundRobinRequests; $index++) {
    $response = Invoke-WebRequest `
        -Uri "$GatewayBaseUrl/" `
        -UseBasicParsing `
        -TimeoutSec 10
    if ($response.Content -notmatch 'Server ([12])') {
        throw "Request $index has no server identity."
    }
    $sequence += "Server $($Matches[1])"
}

$uniqueServers = @($sequence | Sort-Object -Unique)
if ($uniqueServers.Count -ne 2) {
    throw "Round robin did not reach both Web servers: $($sequence -join ', ')."
}
for ($index = 1; $index -lt $sequence.Count; $index++) {
    if ($sequence[$index] -eq $sequence[$index - 1]) {
        throw "Sequence is not alternating: $($sequence -join ' -> ')."
    }
}

Write-Host "Gateway acceptance test PASSED." -ForegroundColor Green
Write-Host "Root: HTTP 200"
Write-Host "/api/hello: $($hello.message)"
Write-Host "/auth/: HTTP $authStatus -> $authLocation"
Write-Host "/student/: $($students.Count) records"
Write-Host "Round robin: $($sequence -join ' -> ')"
