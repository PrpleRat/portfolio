@echo off
title SplitPad - Expo Go
cd /d "%~dp0"
set "PATH=C:\Program Files\nodejs;%PATH%"

echo.
echo  ========================================
echo   SplitPad - lancement Expo Go
echo  ========================================
echo.
echo   iPhone sur le MEME Wi-Fi que ce PC
echo   Ouvre Expo Go et scanne le QR code
echo   Laisse cette fenetre ouverte
echo.

where npm >nul 2>&1
if errorlevel 1 (
  echo  ERREUR: npm introuvable. Installe Node.js.
  pause
  exit /b 1
)

if not exist "node_modules\" (
  echo  Installation des dependances...
  call npm install --legacy-peer-deps
  echo.
)

echo  Liberation du port 8081 si occupe...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8081" ^| findstr "LISTENING"') do taskkill /F /PID %%a >nul 2>&1

call npm run go

echo.
echo  Serveur arrete.
pause
