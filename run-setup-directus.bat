@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ============================================
echo   OSER POUR INNOVER - Setup Directus
echo ============================================
echo.
echo Ce script SUPPRIME les anciennes collections apprenants et progress
echo (si elles existent), puis recree le modele MULTI-ORIGINE via l'API.
echo Donnees existantes dans ces collections seront perdues.
echo Fichier .env requis (DIRECTUS_URL, DIRECTUS_TOKEN).
echo.
echo Nouveau modele : apprenants (origin, external_user_id, email, date_creation)
echo                  progress (apprenant_id, grain_id, module_id, ...)
echo.
echo Lancement du script PowerShell...
echo.

powershell -ExecutionPolicy Bypass -File "scripts\setup-directus.ps1"

echo.
if %ERRORLEVEL% NEQ 0 (
    echo Erreur : verifiez .env ^(DIRECTUS_URL, DIRECTUS_TOKEN^) et la connexion.
) else (
    echo Termine. Verifiez dans Directus : Parametres ^> Data Model.
)
echo.
pause
