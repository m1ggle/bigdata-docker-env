# =============================================================================
#  Big Data Dev Environment - Windows stop script (PowerShell)
#  Usage: powershell -ExecutionPolicy Bypass -File .\stop.ps1 [-Clean]
#     -Clean : also remove data volumes
# =============================================================================
param([switch]$Clean)

$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

if ($Clean) {
    Write-Host "Stopping and removing containers + volumes..." -ForegroundColor Yellow
    docker compose down -v
} else {
    Write-Host "Stopping and removing containers (keeping volumes)..." -ForegroundColor Yellow
    docker compose down
}
Write-Host "Done." -ForegroundColor Green
