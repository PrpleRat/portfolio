# BeatBill — scanne le QR code avec Expo Go
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$nodeDir = "C:\Program Files\nodejs"
if (Test-Path "$nodeDir\node.exe") {
    $env:Path = "$nodeDir;" + $env:Path
}

$npm = Get-Command npm -ErrorAction SilentlyContinue
if (-not $npm) {
    Write-Host "Node.js introuvable. Installe-le : https://nodejs.org" -ForegroundColor Red
    Read-Host "Entree pour quitter"
    exit 1
}

if (-not (Test-Path "node_modules")) {
    Write-Host "Installation des dependances..." -ForegroundColor Cyan
    npm install
}

Write-Host ""
Write-Host "=== BeatBill — Scanne le QR code avec Expo Go ===" -ForegroundColor Green
Write-Host ""

npx expo start --tunnel
