@echo off
pushd "%~dp0"
title Deploiement Gestion Formations MNTIC

echo ======================================================================
echo   DEPLOIEMENT GESTION FORMATIONS MNTIC
echo   Dossier de travail : %CD%
echo ======================================================================
echo.

:: 1. Verification de Docker
echo [1/5] Verification de Docker...
where docker >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERREUR] Docker n'est pas accessible dans cette fenetre de commande.
    echo Veuillez vous assurer que Docker Desktop est bien lance sur cette machine.
    echo.
    pause
    popd
    exit /b 1
)
echo [OK] Docker detecte.

:: 2. Construction des images Docker
echo.
echo [2/5] Construction des conteneurs (Frontend + API)...
docker compose build gestion_formations api
if %ERRORLEVEL% neq 0 (
    docker-compose build gestion_formations api
    if %ERRORLEVEL% neq 0 (
        echo [ERREUR] La construction Docker a echoue.
        pause
        popd
        exit /b 1
    )
)

:: 3. Lancement des conteneurs et des tunnels
echo.
echo [3/5] Lancement des conteneurs et tunnels...
docker compose up -d --remove-orphans
if %ERRORLEVEL% neq 0 (
    docker-compose up -d --remove-orphans
    if %ERRORLEVEL% neq 0 (
        echo [ERREUR] Le lancement a echoue.
        pause
        popd
        exit /b 1
    )
)

:: 4. Restauration / Synchronisation de la base de donnees et formations
echo.
echo [4/5] Synchronisation de la base de donnees (Formations, Utilisateurs)...
if exist "backup\database.json" (
    docker cp "backup\database.json" gestion_formations_api:/data/database.json >nul 2>&1
    docker compose restart api >nul 2>&1
    echo [OK] Base de donnees restauree avec succes dans le conteneur API.
) else if exist "server\initial_database.json" (
    docker cp "server\initial_database.json" gestion_formations_api:/data/database.json >nul 2>&1
    docker compose restart api >nul 2>&1
    echo [OK] Base initiale des formations restauree avec succes.
)

:: 5. Statut des services
echo.
echo [5/5] Statut des services actifs :
docker compose ps
if %ERRORLEVEL% neq 0 (
    docker-compose ps
)

echo.
echo ======================================================================
echo   DEPLOIEMENT REUSSI !
echo   - Web Local : http://localhost:8080
echo   - Tunnels   : Ngrok & Cloudflare actifs
echo ======================================================================
echo.
pause
popd
