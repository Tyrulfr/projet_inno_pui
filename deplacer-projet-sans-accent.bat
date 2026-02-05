@echo off
chcp 65001 >nul
set "DEST=C:\Users\cduboi4\projet_inno_pui"
set "SRC=%~dp0"
if "%SRC:~-1%"=="\" set "SRC=%SRC:~0,-1%"

echo.
echo Ce script copie le projet vers %DEST% (chemin sans accent).
echo IMPORTANT : Fermez Cursor avant de lancer ce script.
echo.
pause

if not exist "%DEST%" mkdir "%DEST%"
echo Copie en cours...
robocopy "%SRC%" "%DEST%" /E /NFL /NDL /NJH /NJS /NC /NS /NP
if %ERRORLEVEL% LSS 8 (
    echo.
    echo Terminé. Ouvrez Cursor puis : Fichier ^> Ouvrir un dossier ^> C:\Users\cduboi4\projet_inno_pui
    echo L'ancien dossier (avec Ingénierie) peut être supprimé plus tard si vous voulez.
) else (
    echo Erreur pendant la copie. Code : %ERRORLEVEL%
)
echo.
pause
