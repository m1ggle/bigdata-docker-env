# =============================================================================
#  Big Data Dev Environment - Windows launcher (PowerShell)
#  Prereq: Docker Desktop for Windows (WSL2 backend) installed and running.
#  Usage:
#     powershell -ExecutionPolicy Bypass -File .\start.ps1
#  Note: This script is intentionally ASCII-only to avoid codepage issues.
# =============================================================================
$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

Write-Host "== Step 1/4: Check Docker ==" -ForegroundColor Cyan
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] docker command not found." -ForegroundColor Red
    Write-Host "Install and start Docker Desktop: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
    exit 1
}
docker version | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Docker is not running. Start Docker Desktop first." -ForegroundColor Red
    exit 1
}
Write-Host "Docker is ready." -ForegroundColor Green

Write-Host "== Step 2/4: Prepare .env ==" -ForegroundColor Cyan
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Created .env from .env.example (edit it to change passwords)." -ForegroundColor Green
} else {
    Write-Host ".env already exists, skipping." -ForegroundColor Green
}

Write-Host "== Step 3/4: Build and start all services ==" -ForegroundColor Cyan
docker compose up -d --build
if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] docker compose failed." -ForegroundColor Red; exit 1 }

Write-Host "== Step 4/4: Wait for services and initialize ==" -ForegroundColor Cyan
Write-Host "Waiting 60 seconds for NameNode and Kafka to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

Write-Host "Initializing HDFS directories..." -ForegroundColor Cyan
docker exec namenode bash /init/10-hdfs-init.sh
Write-Host "Initializing Kafka topic..." -ForegroundColor Cyan
docker exec kafka bash /init/20-kafka-init.sh

Write-Host ""
Write-Host "Done! Open these in your browser:" -ForegroundColor Green
Write-Host "  HDFS NameNode        http://localhost:9870"
Write-Host "  YARN ResourceManager http://localhost:8088"
Write-Host "  Spark Master         http://localhost:8080"
Write-Host "  Spark History        http://localhost:18080"
Write-Host "  Flink Dashboard      http://localhost:8082"
Write-Host "  HiveServer2          http://localhost:10002"
Write-Host "  DolphinScheduler     http://localhost:12345/dolphinscheduler/ui  (admin / dolphinscheduler123)"
Write-Host ""
Write-Host "Stop:  docker compose down" -ForegroundColor Yellow
Write-Host "Clean: docker compose down -v" -ForegroundColor Yellow
