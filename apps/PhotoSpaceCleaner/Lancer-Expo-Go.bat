@echo off
chcp 65001 >nul
title Photo Space Cleaner — Expo Go
cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\lancer-expo.ps1"

pause
