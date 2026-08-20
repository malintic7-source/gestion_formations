@echo off
REM Lance la mise à jour contrôlée; aucun nettoyage Docker n'est exécuté.
powershell -ExecutionPolicy Bypass -File "%~dp0deploy.ps1"
exit /b %ERRORLEVEL%
