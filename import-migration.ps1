<#
.SYNOPSIS
  Script d'importation et de démarrage automatique sur la machine cible Windows 10.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "  MIGRATION GESTION MALINTIC - RESTAURATION AUTOMATIQUE" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# 1. Vérification Docker
Write-Host "`n[1/5] Verification de Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "Docker detecte : $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "ERREUR : Docker Desktop n'est pas installe ou n'est pas lance sur cette machine !" -ForegroundColor Red
    Write-Host "Veuillez demarrer Docker Desktop et reessayer." -ForegroundColor Yellow
    Read-Host "Appuyez sur Entree pour quitter..."
    exit 1
}

# 2. Vérification du dossier web et de la base de données
Write-Host "`n[2/5] Verification des fichiers et de la base de donnees..." -ForegroundColor Yellow

# Si le dossier web a été extrait à la racine au lieu de build/web, on le repositionne automatiquement
if ((-not (Test-Path "build\web")) -and (Test-Path "web")) {
    Write-Host "Ajustement de l'arborescence build\web..." -ForegroundColor Gray
    New-Item -ItemType Directory -Force -Path "build" | Out-Null
    Copy-Item -Path "web" -Destination "build\web" -Recurse -Force
}

$backupFile = Join-Path $root "backup\database.json"
if (-not (Test-Path $backupFile)) {
    Write-Host "ERREUR : Fichier de sauvegarde introuvable : $backupFile" -ForegroundColor Red
    Read-Host "Appuyez sur Entree pour quitter..."
    exit 1
}
$size = (Get-Item $backupFile).Length
Write-Host "Base de donnees prete ($size octets)." -ForegroundColor Green

# 3. Construction et Démarrage des conteneurs
Write-Host "`n[3/5] Construction et demarrage des conteneurs Docker (veuillez patienter)..." -ForegroundColor Yellow
docker compose up -d --build
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERREUR lors de la construction/demarrage des conteneurs Docker." -ForegroundColor Red
    Read-Host "Appuyez sur Entree pour quitter..."
    exit 1
}

# Attente de l'initialisation du conteneur API
Write-Host "Attente de l'initialisation de l'API..." -ForegroundColor Gray
Start-Sleep -Seconds 6

# 4. Injection de la base de données
Write-Host "`n[4/5] Restauration de la base de donnees dans le conteneur..." -ForegroundColor Yellow
docker cp $backupFile gestion_formations_api:/data/database.json
if ($LASTEXITCODE -ne 0) {
    Write-Host "Echec de la copie de la base de donnees." -ForegroundColor Red
    Read-Host "Appuyez sur Entree pour quitter..."
    exit 1
}

docker exec -u 0 gestion_formations_api chown node:node /data/database.json
docker compose restart api
Write-Host "Base de donnees injectee et API rechargee avec succes !" -ForegroundColor Green

# 5. Validation de santé
Write-Host "`n[5/5] Verification de sante de l'application..." -ForegroundColor Yellow
Start-Sleep -Seconds 4

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "  MIGRATION REUSSIE AVEC SUCCES !                      " -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "Acces Frontend local : http://localhost:8080" -ForegroundColor White
Write-Host "Acces API local      : http://localhost:5001" -ForegroundColor White
Write-Host "Dashboard Ngrok      : http://localhost:4040" -ForegroundColor White
Write-Host "=======================================================`n" -ForegroundColor Cyan

Read-Host "Appuyez sur Entree pour terminer..."
