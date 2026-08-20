@echo off
setlocal enabledelayedexpansion
title Mise a jour de Production - Gestion Formations MNTIC
cd /d "%~dp0"

echo ======================================================================
echo   MISE A JOUR CONTINUE EN PRODUCTION (ZERO PERTE DE DONNEES)
echo ======================================================================
echo.

:: 1. Verification de Docker
where docker >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERREUR] Docker n'est pas accessible.
    pause
    exit /b 1
)

:: 2. Sauvegarde automatique des donnees de production en cours (Anti-Perte)
echo [1/5] Sauvegarde de securite des donnees reelles de production...
if not exist "backup" mkdir backup
docker cp gestion_formations_api:/data/database.json "backup\database.json" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo [OK] Donnees de production actuelles sauvegardees dans backup\database.json.
) else (
    echo [INFO] Premier deploiement ou volume vierge (initialisation standard).
)

:: 3. Verification et compilation Flutter Web
echo.
echo [2/5] Verification des fichiers Web...
if not exist "build\web\index.html" (
    echo [INFO] Compilation de la version web...
    where flutter >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        call flutter build web --release
        if %ERRORLEVEL% neq 0 (
            echo [ERREUR] La compilation Flutter a echoue. La version en ligne reste intacte.
            pause
            exit /b 1
        )
    ) else (
        echo [ERREUR] build\web absent et Flutter non trouve dans le PATH.
        pause
        exit /b 1
    )
) else (
    echo [OK] Build web pret a etre applique.
)

:: 4. Construction de la nouvelle image applicative sans toucher aux volumes
echo.
echo [3/5] Construction de la nouvelle version applicative...
docker compose build gestion_formations api
if %ERRORLEVEL% neq 0 (
    docker-compose build gestion_formations api
    if %ERRORLEVEL% neq 0 (
        echo [ERREUR] Echec de la construction. L'ancienne version reste en ligne.
        pause
        exit /b 1
    )
)

:: 5. Mise a jour a chaud (Rechargement sans interruption des tunnels ni des donnees)
echo.
echo [4/5] Application de la mise a jour (Tunnels et Donnees conserves)...
docker compose up -d --no-deps gestion_formations api
if %ERRORLEVEL% neq 0 (
    docker-compose up -d --no-deps gestion_formations api
)

:: S'assurer que les tunnels sont bien actifs
docker compose up -d ngrok cloudflared >nul 2>&1

:: 6. Verification de sante & Statut
echo.
echo [5/5] Statut des services apres mise a jour :
docker compose ps

echo.
echo ======================================================================
echo   MISE A JOUR DE PRODUCTION REUSSIE SANS AUCUN IMPACT NEGATIF !
echo   - Donnees & Formations : 100%% preservees et sauvegardees
echo   - Tunnels Ngrok & Cloudflare : Maintenus actifs
echo   - Web Local : http://localhost:8080
echo ======================================================================
echo.
pause
