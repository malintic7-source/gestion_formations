@echo off
title Migration Gestion Formations
cd /d "%~dp0"
echo =======================================================
echo   LANCEMENT DE LA RESTAURATION AUTOMATIQUE
echo =======================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0import-migration.ps1"
pause
