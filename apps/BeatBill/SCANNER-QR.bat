@echo off
title BeatBill - QR Code
cd /d "%~dp0"
set "PATH=C:\Program Files\nodejs;%PATH%"

if not exist node_modules (
  echo Installation des dependances...
  call npm install
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\show-qr.ps1"
