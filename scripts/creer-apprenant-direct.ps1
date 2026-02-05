# Cree un apprenant "direct" dans Directus et affiche le lien d'acces a envoyer.
# Utilise par l'ADMINISTRATEUR (pas par l'apprenant). Prerequis : .env avec DIRECTUS_URL et DIRECTUS_TOKEN.
# Usage : .\scripts\creer-apprenant-direct.ps1 -Email "apprenant@exemple.com"
#         .\scripts\creer-apprenant-direct.ps1 -Email "apprenant@exemple.com" -BaseUrl "https://mon-site.fr"

param(
    [Parameter(Mandatory = $true)]
    [string]$Email,
    [string]$BaseUrl = ""
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$envPath = Join-Path $projectRoot ".env"

if (-not (Test-Path $envPath)) {
    Write-Host "Fichier .env introuvable. Copiez .env.example en .env et renseignez DIRECTUS_URL et DIRECTUS_TOKEN."
    exit 1
}

$envVars = @{}
Get-Content $envPath -Encoding UTF8 | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#")) {
        $idx = $line.IndexOf("=")
        if ($idx -gt 0) {
            $key = $line.Substring(0, $idx).Trim()
            $val = $line.Substring($idx + 1).Trim().Trim('"').Trim("'")
            $envVars[$key] = $val
        }
    }
}

$directusUrl = ($envVars["DIRECTUS_URL"] -replace '/$', '').Trim()
$token = ($envVars["DIRECTUS_TOKEN"] -replace "^\s+|\s+$", "").Trim('"').Trim("'")
$emailEnv = ($envVars["DIRECTUS_EMAIL"] -replace "^\s+|\s+$", "").Trim('"').Trim("'")
$password = ($envVars["DIRECTUS_PASSWORD"] -replace "^\s+|\s+$", "").Trim('"').Trim("'")
# URL du SITE inno_pui (ou l'apprenant ouvre le lien) — NE PAS utiliser l'URL Directus ici
$siteBaseUrl = $BaseUrl
if (-not $siteBaseUrl -and $envVars["SITE_BASE_URL"]) { $siteBaseUrl = ($envVars["SITE_BASE_URL"] -replace '/$', '').Trim() }
if (-not $siteBaseUrl) { $siteBaseUrl = "https://tyrulfr.github.io/projet_inno_pui" }

if (-not $directusUrl) {
    Write-Host "Dans .env, renseignez DIRECTUS_URL."
    exit 1
}
if (-not $token -and (-not $emailEnv -or -not $password)) {
    Write-Host "Dans .env : soit DIRECTUS_TOKEN, soit DIRECTUS_EMAIL + DIRECTUS_PASSWORD."
    exit 1
}

$headers = @{ "Content-Type" = "application/json" }
if ($token) { $headers["Authorization"] = "Bearer $token" }

function Invoke-DirectusApi {
    param([string]$Method, [string]$Path, [object]$Body = $null)
    $uri = "$directusUrl$Path"
    $params = @{ Uri = $uri; Method = $Method; Headers = $headers }
    if ($Body) { $params.Body = ($Body | ConvertTo-Json -Depth 5 -Compress) }
    try {
        return Invoke-RestMethod @params
    } catch {
        $err = $_.ErrorDetails.Message
        if ($err) { Write-Host "Erreur API: $err" }
        throw
    }
}

# Auth par login si pas de token
if (-not $token -and $emailEnv -and $password) {
    try {
        $loginBody = @{ email = $emailEnv; password = $password } | ConvertTo-Json -Compress
        $loginResp = Invoke-RestMethod -Uri "$directusUrl/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
        $token = $loginResp.data.access_token
        $headers["Authorization"] = "Bearer $token"
    } catch { Write-Host "Erreur login Directus."; exit 1 }
}

# Identifiant unique pour l'apprenant direct
$externalUserId = [guid]::NewGuid().ToString()

$body = @{
    origin           = "direct"
    external_user_id = $externalUserId
    email            = $Email
}

Write-Host "Creation de l'apprenant dans Directus..."
$created = Invoke-DirectusApi -Method Post -Path "/items/apprenants" -Body $body

$apprenantId = $created.data.id
if (-not $apprenantId) { $apprenantId = $created.id }
if (-not $apprenantId) { $apprenantId = "?" }

Write-Host ""
Write-Host "Apprenant cree :"
Write-Host "  id (Directus)    : $apprenantId"
Write-Host "  external_user_id: $externalUserId"
Write-Host "  email           : $Email"
Write-Host "  origin          : direct"
Write-Host ""

$pathPortal = "pages/apprenant/portal.html"
$link = ($siteBaseUrl.TrimEnd('/') + '/' + $pathPortal + "?token=" + $externalUserId)
if ($link -notmatch '^https?://') { $link = "https://$link" }

Write-Host "L'apprenant se connecte au SITE inno_pui (projet_inno_pui), pas a Directus."
Write-Host "  URL du site utilisee pour le lien : $siteBaseUrl"
Write-Host ""
Write-Host "Lien d'acces a envoyer a l'apprenant (conservez ce lien, il sert d'identifiant) :"
Write-Host ""
Write-Host $link
Write-Host ""
Write-Host "Copiez ce lien et envoyez-le par email a $Email . L'apprenant ouvre ce lien sur le site ; il n'a pas de mot de passe."
