@echo off
setlocal enabledelayedexpansion
title Deploiement Gestion Formations - MNTIC
cd /d "%~dp0"

echo ========================================================
echo   DEPLOIEMENT DOCKER GESTION FORMATIONS AVEC TUNNELS
echo ========================================================
echo.

:: 1. Verification de Docker
where docker >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERREUR] Docker n'est pas reconnu dans le PATH.
    echo Veuillez demarrer Docker Desktop ou l'ajouter au PATH.
    echo.
    pause
    exit /b 1
)

:: 2. Verification du build Flutter Web
if not exist "build\web\index.html" (
    echo [INFO] Build web non trouve. Tentative de compilation Flutter...
    where flutter >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        call flutter build web --release
        if %ERRORLEVEL% neq 0 (
            echo [ERREUR] La compilation Flutter a echoue.
            pause
            exit /b 1
        )
    ) else (
        echo [ERREUR] build\web absent et flutter non trouve dans le PATH.
        pause
        exit /b 1
    )
) else (
    echo [OK] Fichiers Flutter Web presents dans build\web.
)

:: 3. Construction des images Docker
echo.
echo [1/3] Construction des images Docker (frontend + api)...
docker compose build
if %ERRORLEVEL% neq 0 (
    echo [INFO] Tentative avec 'docker-compose build'...
    docker-compose build
    if %ERRORLEVEL% neq 0 (
        echo [ERREUR] La construction Docker a echoue.
        pause
        exit /b 1
    )
)

:: 4. Demarrage de tous les conteneurs (App + API + Ngrok + Cloudflared)
echo.
echo [2/3] Demarrage des conteneurs et des tunnels...
docker compose up -d --remove-orphans
if %ERRORLEVEL% neq 0 (
    echo [INFO] Tentative avec 'docker-compose up -d'...
    docker-compose up -d --remove-orphans
    if %ERRORLEVEL% neq 0 (
        echo [ERREUR] Le demarrage des conteneurs a echoue.
        pause
        exit /b 1
    )
)

:: 5. Statut des conteneurs
echo.
echo [3/3] Statut des services actifs :
docker compose ps

echo.
echo ========================================================
echo   DEPLOIEMENT REUSSI AVEC SUCCES !
echo   - Web Local     : http://localhost:8080
echo   - Dashboard Ngrok: http://localhost:4040
echo ========================================================
echo.
pause
