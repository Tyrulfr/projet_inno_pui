# Script de structure de la base Directus (OSER POUR INNOVER)
# Cree les collections apprenants et progress via l'API Directus.
# Prérequis : fichier .env a la racine du projet (DIRECTUS_URL, DIRECTUS_TOKEN)
# Usage : double-clic sur run-setup-directus.bat ou : .\scripts\setup-directus.ps1

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

$baseUrl = ($envVars["DIRECTUS_URL"] -replace '/$', '').Trim()
$token = ($envVars["DIRECTUS_TOKEN"] -replace "^\s+|\s+$", "").Trim('"').Trim("'")
$email = ($envVars["DIRECTUS_EMAIL"] -replace "^\s+|\s+$", "").Trim('"').Trim("'")
$password = ($envVars["DIRECTUS_PASSWORD"] -replace "^\s+|\s+$", "").Trim('"').Trim("'")

if (-not $baseUrl) {
    Write-Host "Dans .env, renseignez DIRECTUS_URL."
    exit 1
}
if (-not $token -and (-not $email -or -not $password)) {
    Write-Host "Dans .env : soit DIRECTUS_TOKEN, soit DIRECTUS_EMAIL + DIRECTUS_PASSWORD (connexion par login)."
    exit 1
}

if ($token) { Write-Host "Token : $($token.Length) caracteres" }
else { Write-Host "Connexion par email/mot de passe (login)" }

$headers = @{
    "Content-Type" = "application/json"
}
if ($token) { $headers["Authorization"] = "Bearer $token" }

function Invoke-DirectusApi {
    param([string]$Method, [string]$Path, [object]$Body = $null)
    $uri = "$baseUrl$Path"
    $params = @{ Uri = $uri; Method = $Method; Headers = $headers }
    if ($Body) { $params.Body = ($Body | ConvertTo-Json -Depth 10 -Compress) }
    try {
        return Invoke-RestMethod @params
    } catch {
        $err = $_.ErrorDetails.Message
        if ($err) { Write-Host "Erreur API: $err" }
        throw
    }
}

Write-Host "Connexion a Directus : $baseUrl"
$authOk = $false
try {
    $me = Invoke-DirectusApi -Method Get -Path "/users/me"
    Write-Host "Authentifie : OK (Bearer)"
    $authOk = $true
} catch { }

if (-not $authOk -and $token) {
    try {
        $uriWithToken = "$baseUrl/users/me?access_token=$token"
        $me = Invoke-RestMethod -Uri $uriWithToken -Method Get -ContentType "application/json"
        Write-Host "Authentifie : OK (access_token en parametre)"
        $authOk = $true
        $headers["Authorization"] = "Bearer $token"
    } catch { }
}

if (-not $authOk -and $email -and $password) {
    try {
        Write-Host "Tentative connexion par login (email/mot de passe)..."
        $loginBody = @{ email = $email; password = $password } | ConvertTo-Json -Compress
        $loginResp = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
        $token = $loginResp.data.access_token
        $headers["Authorization"] = "Bearer $token"
        Write-Host "Authentifie : OK (login)"
        $authOk = $true
    } catch {
        $err = $_.ErrorDetails.Message
        if ($err) { Write-Host "Erreur login: $err" }
    }
}

if (-not $authOk) {
    Write-Host "Impossible de se connecter. Verifiez :"
    Write-Host "  - DIRECTUS_TOKEN : token genere dans Directus (utilisateur > Token > +)"
    Write-Host "  - OU ajoutez DIRECTUS_EMAIL et DIRECTUS_PASSWORD (email/mot de passe admin) dans .env"
    Write-Host "  - .env est bien dans le meme dossier que run-setup-directus.bat"
    exit 1
}

# --- Modele multi-origine (Moodle / FunMooc / direct) : supprimer l'ancien puis recréer ---

# 1) Supprimer progress d'abord (FK vers apprenants)
Write-Host "Suppression des anciennes collections (si elles existent)..."
try {
    Invoke-DirectusApi -Method Delete -Path "/collections/progress"
    Write-Host "  -> Collection progress supprimee."
} catch {
    if ($_.Exception.Message -match "404|NotFound|not found") { Write-Host "  -> Pas de collection progress a supprimer." }
    else { Write-Host "  -> progress : $($_.Exception.Message)" }
}

# 2) Supprimer apprenants
try {
    Invoke-DirectusApi -Method Delete -Path "/collections/apprenants"
    Write-Host "  -> Collection apprenants supprimee."
} catch {
    if ($_.Exception.Message -match "404|NotFound|not found") { Write-Host "  -> Pas de collection apprenants a supprimer." }
    else { Write-Host "  -> apprenants : $($_.Exception.Message)" }
}

Write-Host ""

# 3) Creer apprenants (nouveau modele : origin + external_user_id)
Write-Host "Creation de la collection apprenants (modele multi-origine)..."
$bodyApprenants = @{
    collection = "apprenants"
    meta      = @{ icon = "person"; note = "Profils apprenants : Moodle, FunMooc (edX) ou site direct (origin + external_user_id)" }
    schema    = @{}
    fields   = @(
        @{ field = "id"; type = "integer"; meta = @{ hidden = $true; readonly = $true; interface = "input"; special = @("integer", "primary") }; schema = @{ is_primary_key = $true; has_auto_increment = $true } },
        @{ field = "origin"; type = "string"; meta = @{ interface = "select-dropdown"; required = $true; options = @{ choices = @(
            @{ text = "Moodle"; value = "moodle" },
            @{ text = "FunMooc (edX)"; value = "funmooc" },
            @{ text = "Site direct"; value = "direct" }
        ) }; note = "moodle | funmooc | direct" }; schema = @{ is_nullable = $false; default_value = "moodle" } },
        @{ field = "external_user_id"; type = "string"; meta = @{ interface = "input"; required = $true; note = "Id utilisateur cote plateforme (Moodle, edX, ou UUID direct)" }; schema = @{ is_nullable = $false } },
        @{ field = "email"; type = "string"; meta = @{ interface = "input" }; schema = @{ is_nullable = $true } },
        @{ field = "date_creation"; type = "timestamp"; meta = @{ interface = "datetime"; readonly = $true }; schema = @{ is_nullable = $true; default_value = "CURRENT_TIMESTAMP" } }
    )
}
Invoke-DirectusApi -Method Post -Path "/collections" -Body $bodyApprenants
Write-Host "  -> Collection apprenants creee (origin, external_user_id, email, date_creation)."

# 4) Creer progress (inchangé, FK vers apprenants)
Write-Host "Creation de la collection progress..."
$bodyProgress = @{
    collection = "progress"
    meta      = @{ icon = "check_circle"; note = "Grains completes par apprenant" }
    schema    = @{}
    fields   = @(
        @{ field = "id"; type = "integer"; meta = @{ hidden = $true; readonly = $true; interface = "input"; special = @("integer", "primary") }; schema = @{ is_primary_key = $true; has_auto_increment = $true } },
        @{ field = "apprenant_id"; type = "integer"; meta = @{ interface = "select-dropdown-m2o"; special = @("m2o"); required = $true; options = @{ template = "{{origin}} - {{external_user_id}}" } }; schema = @{ is_nullable = $false; foreign_key_table = "apprenants"; foreign_key_column = "id" } },
        @{ field = "grain_id"; type = "string"; meta = @{ interface = "input"; required = $true }; schema = @{ is_nullable = $false } },
        @{ field = "module_id"; type = "string"; meta = @{ interface = "input"; required = $true }; schema = @{ is_nullable = $false } },
        @{ field = "sequence_id"; type = "string"; meta = @{ interface = "input" }; schema = @{ is_nullable = $true } },
        @{ field = "completed_at"; type = "timestamp"; meta = @{ interface = "datetime" }; schema = @{ is_nullable = $true; default_value = "CURRENT_TIMESTAMP" } }
    )
}
Invoke-DirectusApi -Method Post -Path "/collections" -Body $bodyProgress
Write-Host "  -> Collection progress creee."

Write-Host ""
Write-Host "Termine. Modele multi-origine en place. Verifiez dans Directus : Settings > Data Model."
