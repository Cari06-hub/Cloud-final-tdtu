[CmdletBinding()]
param(
    [string]$EnvFile = ".env",
    [string]$KeycloakBaseUrl = "http://localhost:8081",
    [string]$BackendBaseUrl = "http://localhost:8085",
    [string]$MinioContainer = "object-storage-server"
)

$ErrorActionPreference = "Stop"

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

function ConvertFrom-Base64UrlJson {
    param([Parameter(Mandatory)][string]$Segment)

    $base64 = $Segment.Replace("-", "+").Replace("_", "/")
    switch ($base64.Length % 4) {
        2 { $base64 += "==" }
        3 { $base64 += "=" }
    }
    $json = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($base64))
    return $json | ConvertFrom-Json
}

function Invoke-KeycloakJson {
    param(
        [Parameter(Mandatory)][string]$Method,
        [Parameter(Mandatory)][string]$Uri,
        [Parameter(Mandatory)][hashtable]$Headers,
        [object]$Body
    )

    $parameters = @{
        Method = $Method
        Uri = $Uri
        Headers = $Headers
        TimeoutSec = 20
    }
    if ($null -ne $Body) {
        $parameters.ContentType = "application/json"
        $parameters.Body = $Body | ConvertTo-Json -Depth 10 -Compress
    }
    return Invoke-RestMethod @parameters
}

$config = Read-DotEnv -Path $EnvFile
$adminUser = Get-RequiredValue -Values $config -Name "KEYCLOAK_ADMIN"
$adminPassword = Get-RequiredValue -Values $config -Name "KEYCLOAK_ADMIN_PASSWORD"
$realm = Get-RequiredValue -Values $config -Name "KEYCLOAK_REALM"
$sv01Password = Get-RequiredValue -Values $config -Name "SV01_PASSWORD"
$sv02Password = Get-RequiredValue -Values $config -Name "SV02_PASSWORD"

Write-Host "[1/7] Authenticating to the Keycloak master realm..."
$adminTokenResponse = Invoke-RestMethod `
    -Method Post `
    -Uri "$KeycloakBaseUrl/realms/master/protocol/openid-connect/token" `
    -ContentType "application/x-www-form-urlencoded" `
    -Body @{
        client_id = "admin-cli"
        username = $adminUser
        password = $adminPassword
        grant_type = "password"
    } `
    -TimeoutSec 20
$headers = @{ Authorization = "Bearer $($adminTokenResponse.access_token)" }

Write-Host "[2/7] Ensuring realm $realm exists..."
$realmUri = "$KeycloakBaseUrl/admin/realms/$([Uri]::EscapeDataString($realm))"
try {
    $null = Invoke-KeycloakJson -Method Get -Uri $realmUri -Headers $headers
} catch {
    if ($_.Exception.Response.StatusCode.value__ -ne 404) {
        throw
    }
    $null = Invoke-KeycloakJson `
        -Method Post `
        -Uri "$KeycloakBaseUrl/admin/realms" `
        -Headers $headers `
        -Body @{ realm = $realm; enabled = $true }
}

Write-Host "[3/7] Ensuring public client flask-app and Audience mapper exist..."
$clientsUri = "$realmUri/clients"
$clients = @(
    (Invoke-KeycloakJson `
        -Method Get `
        -Uri "${clientsUri}?clientId=flask-app" `
        -Headers $headers) | ForEach-Object { $_ }
)
if ($clients.Count -eq 0) {
    $null = Invoke-KeycloakJson `
        -Method Post `
        -Uri $clientsUri `
        -Headers $headers `
        -Body @{
            clientId = "flask-app"
            name = "MyMiniCloud Flask App"
            enabled = $true
            protocol = "openid-connect"
            publicClient = $true
            directAccessGrantsEnabled = $true
            standardFlowEnabled = $true
            redirectUris = @("*")
            webOrigins = @("*")
        }
    $clients = @(
        (Invoke-KeycloakJson `
            -Method Get `
            -Uri "${clientsUri}?clientId=flask-app" `
            -Headers $headers) | ForEach-Object { $_ }
    )
}
if ($clients.Count -ne 1) {
    throw "Expected one flask-app client, found $($clients.Count)."
}
$clientUuid = $clients[0].id
$mappersUri = "$clientsUri/$clientUuid/protocol-mappers/models"
$mappers = @(
    (Invoke-KeycloakJson -Method Get -Uri $mappersUri -Headers $headers) |
        ForEach-Object { $_ }
)
if (-not ($mappers | Where-Object { $_.name -eq "audience-flask-app" })) {
    $null = Invoke-KeycloakJson `
        -Method Post `
        -Uri $mappersUri `
        -Headers $headers `
        -Body @{
            name = "audience-flask-app"
            protocol = "openid-connect"
            protocolMapper = "oidc-audience-mapper"
            consentRequired = $false
            config = @{
                "included.client.audience" = "flask-app"
                "id.token.claim" = "false"
                "access.token.claim" = "true"
                "introspection.token.claim" = "true"
            }
        }
}

Write-Host "[4/7] Ensuring users sv01 and sv02 exist with non-temporary passwords..."
$userPasswords = [ordered]@{
    sv01 = $sv01Password
    sv02 = $sv02Password
}
foreach ($entry in $userPasswords.GetEnumerator()) {
    $username = $entry.Key
    $password = $entry.Value
    $usersUri = "$realmUri/users"
    $users = @(
        (Invoke-KeycloakJson `
            -Method Get `
            -Uri "${usersUri}?username=$username&exact=true" `
            -Headers $headers) | ForEach-Object { $_ }
    )
    if ($users.Count -eq 0) {
        $null = Invoke-KeycloakJson `
            -Method Post `
            -Uri $usersUri `
            -Headers $headers `
            -Body @{
                username = $username
                enabled = $true
                credentials = @(
                    @{
                        type = "password"
                        value = $password
                        temporary = $false
                    }
                )
            }
        $users = @(
            (Invoke-KeycloakJson `
                -Method Get `
                -Uri "${usersUri}?username=$username&exact=true" `
                -Headers $headers) | ForEach-Object { $_ }
        )
    }
    if ($users.Count -ne 1) {
        throw "Expected one user named $username."
    }
    $userId = $users[0].id
    $null = Invoke-KeycloakJson `
        -Method Put `
        -Uri "$usersUri/$userId" `
        -Headers $headers `
        -Body @{
            id = $userId
            username = $username
            firstName = $username.ToUpperInvariant()
            lastName = "MyMiniCloud"
            email = "$username@cloud.local"
            emailVerified = $true
            enabled = $true
            requiredActions = @()
        }
    $null = Invoke-KeycloakJson `
        -Method Put `
        -Uri "$usersUri/$userId/reset-password" `
        -Headers $headers `
        -Body @{
            type = "password"
            value = $password
            temporary = $false
        }
}

Write-Host "[5/7] Verifying user tokens, audience and Flask /secure..."
foreach ($entry in $userPasswords.GetEnumerator()) {
    $tokenResponse = Invoke-RestMethod `
        -Method Post `
        -Uri "$KeycloakBaseUrl/realms/$realm/protocol/openid-connect/token" `
        -ContentType "application/x-www-form-urlencoded" `
        -Body @{
            client_id = "flask-app"
            username = $entry.Key
            password = $entry.Value
            grant_type = "password"
        } `
        -TimeoutSec 20
    $payload = ConvertFrom-Base64UrlJson -Segment $tokenResponse.access_token.Split(".")[1]
    if ("flask-app" -notin @($payload.aud)) {
        throw "Token audience is missing flask-app for $($entry.Key)."
    }
    $secure = Invoke-RestMethod `
        -Uri "$BackendBaseUrl/secure" `
        -Headers @{ Authorization = "Bearer $($tokenResponse.access_token)" } `
        -TimeoutSec 20
    if ($secure.preferred_username -ne $entry.Key) {
        throw "Flask /secure rejected or misidentified $($entry.Key)."
    }
}

Write-Host "[6/7] Provisioning MinIO B5/E5 buckets and objects..."
$minioUser = Get-RequiredValue -Values $config -Name "MINIO_ROOT_USER"
$minioPassword = Get-RequiredValue -Values $config -Name "MINIO_ROOT_PASSWORD"

# bitnamilegacy/minio image includes mc client – use docker exec directly
docker exec $MinioContainer mc alias set local http://127.0.0.1:9000 $minioUser $minioPassword | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Could not configure MinIO mc alias." }

foreach ($bucket in @("demo", "profile-pics", "documents")) {
    docker exec $MinioContainer mc mb --ignore-existing "local/$bucket" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Could not create bucket: $bucket" }
}

$uploads = [ordered]@{
    "test-upload/index.html"   = "local/demo/index.html"
    "test-upload/avatar.jpg"   = "local/profile-pics/avatar.jpg"
    "test-upload/document.pdf" = "local/documents/document.pdf"
}
foreach ($entry in $uploads.GetEnumerator()) {
    $tmpFile = "/tmp/upload-$(Split-Path $entry.Key -Leaf)"
    docker cp $entry.Key "${MinioContainer}:${tmpFile}" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "docker cp failed: $($entry.Key)" }
    docker exec $MinioContainer mc cp $tmpFile $entry.Value | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "mc cp failed: $($entry.Key) -> $($entry.Value)" }
}
docker exec $MinioContainer mc anonymous set download local/profile-pics | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Could not set public policy on profile-pics." }

Write-Host "[7/7] Verifying MinIO objects and public avatar..."
foreach ($object in @(
    "local/demo/index.html",
    "local/profile-pics/avatar.jpg",
    "local/documents/document.pdf"
)) {
    docker exec $MinioContainer mc stat $object | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Missing MinIO object: $object"
    }
}
$avatar = Invoke-WebRequest `
    -Uri "http://localhost:9000/profile-pics/avatar.jpg" `
    -UseBasicParsing `
    -TimeoutSec 20
if ($avatar.StatusCode -ne 200 -or $avatar.RawContentLength -lt 1) {
    throw "Public avatar verification failed."
}

Write-Host "Demo provisioning PASSED." -ForegroundColor Green
Write-Host "Keycloak: $realm, sv01, sv02, flask-app, audience mapper"
Write-Host "MinIO: demo/index.html, profile-pics/avatar.jpg, documents/document.pdf"
