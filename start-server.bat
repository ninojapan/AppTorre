@echo off
REM ============================================================
REM  Avvio MANUALE del solo server (utile per debug / rete UNC)
REM ============================================================
cd /d "%~dp0"
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0server.ps1"
pause
