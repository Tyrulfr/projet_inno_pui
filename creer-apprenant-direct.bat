@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ============================================
echo   OSER POUR INNOVER - Creer un apprenant DIRECT
echo ============================================
echo.
echo Utilisation : par l'ADMINISTRATEUR (vous). Fichier .env requis.
echo Cree un profil dans Directus et affiche : lien, identifiant et mot de passe
echo a copier dans le mail de bienvenue a l'apprenant.
echo.
echo L'apprenant se connecte au SITE inno_pui (Espace apprenants), jamais a Directus.
echo L'apprenant n'utilise pas ce .bat ni Directus.
echo.

if "%~1"=="" (
    set /p EMAIL="Email de l'apprenant : "
) else (
    set EMAIL=%~1
)

if "%EMAIL%"=="" (
    echo Indiquez l'email : creer-apprenant-direct.bat "apprenant@exemple.com"
    echo Ou relancez et saisissez l'email quand il est demande.
    echo.
    pause
    exit /b 1
)

powershell -ExecutionPolicy Bypass -File "scripts\creer-apprenant-direct.ps1" -Email "%EMAIL%"

echo.
if %ERRORLEVEL% NEQ 0 (
    echo Erreur : verifiez .env ^(DIRECTUS_URL, DIRECTUS_TOKEN^) et la connexion a Directus.
) else (
    echo Copiez le bloc "A COPIER DANS LE MAIL DE BIENVENUE" ci-dessus dans votre mail.
    echo Si le mot de passe n'apparait pas : exécutez une fois "npm install" a la racine du projet.
)
echo.
pause
