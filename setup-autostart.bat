@echo off
setlocal enabledelayedexpansion
title Configuration du Demarrage Automatique - MNTIC
cd /d "%~dp0"

echo ========================================================
echo   CONFIGURATION DU SERVICE DE CONTINUITE ET REPRISE
echo ========================================================
echo.

:: 1. Verification des privileges
net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [INFO] Pour enregistrer la tache planifiee systeme, executez ce script en tant qu'Administrateur si demande.
)

:: 2. Creation du script de demarrage silencieux (start-daemon.bat)
set "START_SCRIPT=%~dp0start-daemon.bat"
(
    echo @echo off
    echo cd /d "%~dp0"
    echo :: Attente que Docker Desktop soit actif
    echo :WAIT_DOCKER
    echo docker info >nul 2>&1
    echo if %%ERRORLEVEL%% neq 0 (
    echo     timeout /t 5 /nobreak ^>nul
    echo     goto WAIT_DOCKER
    echo ^)
    echo :: Demarrage des conteneurs et des tunnels
    echo docker compose up -d --remove-orphans
) > "%START_SCRIPT%"

echo [OK] Script de surveillance et demarrage cree : %START_SCRIPT%

:: 3. Creation de la tache planifiee Windows
schtasks /create /tn "GestionFormations_AutoStart" /tr "\"%START_SCRIPT%\"" /sc onlogon /rl highest /f >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo [SUCCES] Tache planifiee 'GestionFormations_AutoStart' installee avec succes !
    echo L'application et tous les tunnels redemarreront automatiquement a chaque ouverture de session / reboot.
) else (
    echo [INFO] Ajout d'un raccourci dans le dossier Demarrage utilisateur...
    copy /y "%START_SCRIPT%" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\GestionFormations_AutoStart.bat" >nul 2>&1
    echo [SUCCES] Raccourci place dans le dossier de demarrage automatique.
)

echo.
echo ========================================================
echo   CONTINUITE ET REPRISE CONFIGUREES AVEC SUCCES !
echo ========================================================
echo.
pause
