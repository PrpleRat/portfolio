# Lance Expo Go en mode LAN avec QR dynamique
$ErrorActionPreference = "Continue"
$ProjectRoot = Split-Path $PSScriptRoot -Parent
$Port = "8081"

Set-Location $ProjectRoot

Write-Host ""
Write-Host "  Photo Space Cleaner - Expo Go" -ForegroundColor Cyan
Write-Host ""

# Arreter les anciens serveurs
Get-Process -Name node -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

# IP locale + page QR
$ip = & "$PSScriptRoot\generer-qr.ps1" -Port $Port
$expUrl = "exp://${ip}:${Port}"

Write-Host ""
Write-Host "  URL Expo Go : $expUrl" -ForegroundColor Green
Write-Host "  iPhone sur le MEME Wi-Fi que ce PC ($ip)" -ForegroundColor Yellow
Write-Host ""

# Ouvrir la page QR
Start-Process (Join-Path $ProjectRoot "expo-qr.html")

# Forcer l'IP LAN pour Metro
$env:REACT_NATIVE_PACKAGER_HOSTNAME = $ip
$env:EXPO_PACKAGER_PROXY_URL = "http://${ip}:${Port}"

Write-Host "  Demarrage du serveur... (Ctrl+C pour arreter)" -ForegroundColor Cyan
Write-Host ""

& npx expo start --lan --port $Port
