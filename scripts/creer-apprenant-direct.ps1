# Cree un apprenant "direct" dans Directus et affiche les identifiants a envoyer.
# Mode 1 : si API_BASE_URL et ADMIN_SECRET sont dans .env -> cree via l'API avec identifiant + mdp generes.
# Mode 2 : sinon -> cree dans Directus et affiche un lien magique (?token=...).
# Prerequis : .env avec DIRECTUS_URL et DIRECTUS_TOKEN (ou API_BASE_URL + ADMIN_SECRET pour le mode identifiant/mdp).
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
$apiBaseUrl = ($envVars["API_BASE_URL"] -replace '/$', '').Trim()
$adminSecret = ($envVars["ADMIN_SECRET"] -replace "^\s+|\s+$", "").Trim('"').Trim("'")
$siteBaseUrl = $BaseUrl
if (-not $siteBaseUrl -and $envVars["SITE_BASE_URL"]) { $siteBaseUrl = ($envVars["SITE_BASE_URL"] -replace '/$', '').Trim() }
if (-not $siteBaseUrl) { $siteBaseUrl = "https://tyrulfr.github.io/projet_inno_pui" }

# --- Mode identifiant + mot de passe : appel API create-apprenant ---
if ($apiBaseUrl -and $adminSecret) {
    $chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    $ident = "appr_"
    for ($i = 0; $i -lt 8; $i++) { $ident += $chars[(Get-Random -Maximum $chars.Length)] }
    $pwd = ""
    $charsPwd = "abcdefghijklmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    for ($i = 0; $i -lt 12; $i++) { $pwd += $charsPwd[(Get-Random -Maximum $charsPwd.Length)] }
    $body = @{ email = $Email; identifiant = $ident; password = $pwd } | ConvertTo-Json -Compress
    $headers = @{
        "Content-Type"  = "application/json"
        "Authorization" = "Bearer $adminSecret"
    }
    try {
        Write-Host "Creation de l'apprenant via l'API (identifiant + mot de passe)..."
        $resp = Invoke-RestMethod -Uri "$apiBaseUrl/api/create-apprenant" -Method Post -Headers $headers -Body $body
        $loginUrl = ($siteBaseUrl.TrimEnd('/') + '/pages/apprenant/login.html')
        if ($loginUrl -notmatch '^https?://') { $loginUrl = "https://$loginUrl" }
        $linkApi = ($siteBaseUrl.TrimEnd('/') + '/pages/apprenant/portal.html?token=' + $resp.external_user_id)
        if ($linkApi -notmatch '^https?://') { $linkApi = "https://$linkApi" }
        Write-Host ""
        Write-Host "==========  A COPIER DANS LE MAIL DE BIENVENUE  =========="
        Write-Host ""
        Write-Host "  Lien d'acces (a ouvrir dans le navigateur) :"
        Write-Host "  $linkApi"
        Write-Host ""
        Write-Host "  Identifiant (pour la page Connexion du site) : $ident"
        Write-Host "  Mot de passe (pour la page Connexion du site)     : $pwd"
        Write-Host ""
        Write-Host "  Page de connexion (identifiant + mot de passe) : $loginUrl"
        Write-Host ""
        Write-Host "==========  CONSERVEZ CES INFORMATIONS  =========="
        Write-Host ""
        Write-Host "Conservez ces identifiants ; le mot de passe ne peut pas etre recupere."
        exit 0
    } catch {
        $err = $_.ErrorDetails.Message
        if ($err) { Write-Host "Erreur API create-apprenant: $err" }
        Write-Host "Fallback : creation dans Directus sans identifiant/mdp (lien magique)."
    }
}

# --- Mode Directus : creation dans Directus avec identifiant + mdp generes (hash local) ---
if (-not $directusUrl) {
    Write-Host "Dans .env, renseignez DIRECTUS_URL (et DIRECTUS_TOKEN)."
    if ($apiBaseUrl -and $adminSecret) { Write-Host "L'API a repondu une erreur ; verifiez API_BASE_URL, ADMIN_SECRET et que l'API est deployee." }
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

if (-not $token -and $emailEnv -and $password) {
    try {
        $loginBody = @{ email = $emailEnv; password = $password } | ConvertTo-Json -Compress
        $loginResp = Invoke-RestMethod -Uri "$directusUrl/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
        $token = $loginResp.data.access_token
        $headers["Authorization"] = "Bearer $token"
    } catch { Write-Host "Erreur login Directus."; exit 1 }
}

# Generer identifiant et mot de passe pour tous les apprenants (stockes en base + mail de bienvenue)
$chars = "abcdefghijklmnopqrstuvwxyz0123456789"
$ident = "appr_"
for ($i = 0; $i -lt 8; $i++) { $ident += $chars[(Get-Random -Maximum $chars.Length)] }
$generatedPwd = ""
$charsPwd = "abcdefghijklmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"
for ($i = 0; $i -lt 12; $i++) { $generatedPwd += $charsPwd[(Get-Random -Maximum $charsPwd.Length)] }

$externalUserId = [guid]::NewGuid().ToString()
$body = @{
    origin           = "direct"
    external_user_id = $externalUserId
    email            = $Email
    identifiant      = $ident
}

# Hasher le mot de passe (Node + bcryptjs) pour le stocker dans Directus
$passwordHash = $null
$hashScript = Join-Path $scriptDir "hash-password.js"
if (Get-Command node -ErrorAction SilentlyContinue) {
    try {
        Push-Location $projectRoot
        $passwordHash = (node $hashScript $generatedPwd 2>$null)
        if ($passwordHash) { $passwordHash = $passwordHash.Trim() }
    } catch {}
    finally { Pop-Location }
}
if ($passwordHash) {
    $body["password_hash"] = $passwordHash
}

Write-Host "Creation de l'apprenant dans Directus..."
$created = Invoke-DirectusApi -Method Post -Path "/items/apprenants" -Body $body

$apprenantId = $created.data.id
if (-not $apprenantId) { $apprenantId = $created.id }
if (-not $apprenantId) { $apprenantId = "?" }

$pathPortal = "pages/apprenant/portal.html"
$link = ($siteBaseUrl.TrimEnd('/') + '/' + $pathPortal + "?token=" + $externalUserId)
if ($link -notmatch '^https?://') { $link = "https://$link" }
$loginUrl = ($siteBaseUrl.TrimEnd('/') + '/pages/apprenant/login.html')
if ($loginUrl -notmatch '^https?://') { $loginUrl = "https://$loginUrl" }

Write-Host ""
Write-Host "==========  A COPIER DANS LE MAIL DE BIENVENUE  =========="
Write-Host ""
Write-Host "  Lien d'acces (a ouvrir dans le navigateur) :"
Write-Host "  $link"
Write-Host ""
Write-Host "  Identifiant (pour la page Connexion du site) : $ident"
if ($passwordHash) {
    Write-Host "  Mot de passe (pour la page Connexion du site)     : $generatedPwd"
} else {
    Write-Host "  Mot de passe : (non genere - exécutez 'npm install' a la racine du projet puis relancez le script)"
}
Write-Host ""
Write-Host "  Page de connexion (identifiant + mot de passe) : $loginUrl"
Write-Host ""
Write-Host "==========  CONSERVEZ CES INFORMATIONS  =========="
Write-Host ""
Write-Host "L'apprenant peut :"
Write-Host "  - Ouvrir le lien directement pour acceder a son espace ;"
Write-Host "  - Ou aller sur la page Connexion et saisir son identifiant et son mot de passe."
Write-Host "Pour que la connexion (identifiant/mdp) et la progression en base fonctionnent, deployez l'API (dossier api/) et definissez PROGRESS_API_BASE sur le site (voir docs/PROGRESSION_ET_DIRECTUS.md)."
Write-Host ""
Write-Host "Rappel : le mot de passe ne peut pas etre recupere ; conservez-le si vous devez le communiquer a l'apprenant."
