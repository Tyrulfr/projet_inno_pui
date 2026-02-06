# Ajoute les champs identifiant et password_hash a la collection apprenants (sans supprimer les donnees).
# A executer une seule fois si votre base Directus existait avant l'ajout connexion identifiant/mdp.
# Prerequis : .env avec DIRECTUS_URL et DIRECTUS_TOKEN.
# Usage : .\scripts\add-apprenant-login-fields.ps1

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$envPath = Join-Path $projectRoot ".env"
if (-not (Test-Path $envPath)) { Write-Host "Fichier .env introuvable."; exit 1 }

$envVars = @{}
Get-Content $envPath -Encoding UTF8 | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#")) {
        $idx = $line.IndexOf("=")
        if ($idx -gt 0) { $envVars[$line.Substring(0, $idx).Trim()] = $line.Substring($idx + 1).Trim().Trim('"').Trim("'") }
    }
}
$baseUrl = ($envVars["DIRECTUS_URL"] -replace '/$', '').Trim()
$token = ($envVars["DIRECTUS_TOKEN"] -replace "^\s+|\s+$", "").Trim('"').Trim("'")
if (-not $baseUrl -or -not $token) { Write-Host "Renseignez DIRECTUS_URL et DIRECTUS_TOKEN dans .env"; exit 1 }

$headers = @{ "Content-Type" = "application/json"; "Authorization" = "Bearer $token" }

$existingFields = @()
try {
    $resp = Invoke-RestMethod -Uri "$baseUrl/fields?filter[collection][_eq]=apprenants" -Method Get -Headers $headers
    $existingFields = @($resp.data | ForEach-Object { $_.field })
} catch { }

function Add-Field {
    param([string]$FieldName, [object]$Body)
    if ($existingFields -contains $FieldName) {
        Write-Host "  Champ $FieldName existe deja."
    } else {
        try {
            Invoke-RestMethod -Uri "$baseUrl/fields/apprenants" -Method Post -Headers $headers -Body ($Body | ConvertTo-Json -Depth 5 -Compress) | Out-Null
            Write-Host "  Champ $FieldName ajoute."
        } catch {
            Write-Host "  Erreur ajout $FieldName : $($_.Exception.Message)"
        }
    }
}

Write-Host "Ajout des champs identifiant et password_hash a apprenants..."
$bodyIdentifiant = @{
    field = "identifiant"
    type = "string"
    meta = @{ interface = "input"; note = "Login pour connexion site (apprenants direct)" }
    schema = @{ is_nullable = $true }
}
$bodyPasswordHash = @{
    field = "password_hash"
    type = "string"
    meta = @{ interface = "input-hidden"; note = "Hash du mot de passe" }
    schema = @{ is_nullable = $true }
}
Add-Field -FieldName "identifiant" -Body $bodyIdentifiant
Add-Field -FieldName "password_hash" -Body $bodyPasswordHash
Write-Host "Termine."
