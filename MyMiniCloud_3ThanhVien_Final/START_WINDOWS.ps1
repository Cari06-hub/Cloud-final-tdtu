# Chay bang: powershell -NoProfile -ExecutionPolicy Bypass -File .\START_WINDOWS.ps1
[CmdletBinding()]
param([switch]$SkipProvision)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

function Run-Docker {
    & docker @args
    if ($LASTEXITCODE -ne 0) { throw "Lenh Docker that bai: docker $($args -join ' ')" }
}
function New-Password {
    $bytes = New-Object byte[] 24
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
    # Docker compose / .env / Git Bash safe (no dollar signs, spaces, quotes).
    return ([Convert]::ToBase64String($bytes).Replace('+', 'A').Replace('/', 'B').TrimEnd('='))
}
function Ensure-DotEnv {
    if (Test-Path -LiteralPath '.env') {
        if ((Get-Content -LiteralPath '.env' -Raw -Encoding UTF8) -match '(?m)^[A-Z][A-Z0-9_]*=REPLACE_') {
            throw '.env van con REPLACE_*. Hay sua .env hoac xoa .env de tao moi (mat khau cu se mat).'
        }
        Write-Host '[OK] Su dung .env hien co; khong ghi de.' -ForegroundColor Green
        return
    }
    $content = Get-Content -LiteralPath '.env.example' -Raw -Encoding UTF8
    $content = [Regex]::Replace($content, '(?m)^([A-Z][A-Z0-9_]*)=REPLACE_[^\r\n]+', {
        param($m)
        return $m.Groups[1].Value + '=' + (New-Password)
    })
    if ($content -match '(?m)^[A-Z][A-Z0-9_]*=REPLACE_') { throw 'Khong the xu ly placeholder trong .env.example.' }
    $content = $content.Replace("`r`n", "`n")
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot '.env'),$content,(New-Object Text.UTF8Encoding($false)))
    Write-Host '[OK] Da tao .env rieng, mat khau ngau nhien, khong dua len GitHub.' -ForegroundColor Green
}

Write-Host "=== MyMiniCloud - khoi dong ban chung 3 thanh vien ===" -ForegroundColor Cyan
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw 'Khong tim thay docker CLI. Hay cai va mo Docker Desktop.' }
& docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Docker Engine chua chay. Hay mo Docker Desktop va bat Linux containers.' }
Ensure-DotEnv
Write-Host '[1/4] Kiem tra docker compose...' -ForegroundColor Cyan
& docker compose --env-file .env config --quiet
if ($LASTEXITCODE -ne 0) { throw 'Docker Compose YAML/.env chua hop le.' }
Write-Host '[2/4] Build va chay 11 services...' -ForegroundColor Cyan
& docker compose --env-file .env up -d --build
if ($LASTEXITCODE -ne 0) { throw 'Docker Compose up that bai. Xem docker compose logs.' }
Write-Host '[3/4] Trang thai container:' -ForegroundColor Cyan
& docker compose --env-file .env ps
if ($LASTEXITCODE -ne 0) { throw 'Khong the kiem tra container.' }
if (-not $SkipProvision) {
    Write-Host '[4/4] Doi Keycloak san sang de tao Realm, user, bucket...' -ForegroundColor Cyan
    $ready = $false
    for ($i=1; $i -le 75; $i++) {
        try {
            $response = Invoke-WebRequest -Uri 'http://localhost:8081/realms/master' -TimeoutSec 4 -UseBasicParsing
            if ($response.StatusCode -eq 200) { $ready = $true; break }
        } catch { Start-Sleep -Seconds 3 }
    }
    if (-not $ready) { throw 'Keycloak chua san sang. Chay docker compose logs authentication-identity-server --tail 80' }
    & "$PSScriptRoot\scripts\provision-demo.ps1" -EnvFile .env
    if (-not $?) { throw 'Tao du lieu demo that bai. Xem thong bao loi o tren.' }
} else {
    Write-Host 'Da bo qua provision (SkipProvision).'
}
Write-Host '=== Hoan tat khoi dong ===' -ForegroundColor Green
Write-Host 'Website: http://localhost/ | Blog: http://localhost/blog/'
Write-Host 'API: http://localhost/api/hello | Keycloak: http://localhost:8081'
Write-Host 'MinIO: http://localhost:9001 | Prometheus: http://localhost:9090 | Grafana: http://localhost:3000'
Write-Host 'Kiem thu 20 muc: py -3 scripts\verify_local.py (can Python3)'
