@echo off
echo ========================================================
echo   Deploiement Docker - App Gestion de Formations
echo ========================================================
echo.

echo [1/3] Build Flutter Web...
call flutter build web --release

echo.
echo [2/3] Build de l'image Docker...
docker build -f Dockerfile.fast -t gestion_formations_app:latest .

echo.
echo [3/3] Lancement du conteneur Docker...
docker run -d --name gestion_formations_container -p 8080:80 --restart always gestion_formations_app:latest

echo.
echo ========================================================
echo   Succes! Application accessible sur: http://localhost:8080
echo ========================================================
