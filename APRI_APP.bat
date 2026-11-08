@echo off
REM ============================================================
REM  Cronologia Guzzi Twr - Launcher completo
REM  (questo e' il file da usare tutti i giorni: doppio clic)
REM ============================================================
pushd "%~dp0"

echo ==================================================
echo    Avvio Cronologia Guzzi Twr
echo ==================================================
echo.

echo [1/3] Chiusura eventuale server Cronologia gia' aperto...
REM Chiude SOLO il server di questa app (PID salvato in DATI\server.pid),
REM senza toccare altri server PowerShell (es. OSL TRIESTE).
if exist "DATI\server.pid" (
  for /f "usebackq delims=" %%p in ("DATI\server.pid") do (
    tasklist /FI "PID eq %%p" /FI "IMAGENAME eq powershell.exe" 2>nul | find /I "powershell.exe" >nul && taskkill /F /PID %%p >nul 2>&1
  )
  del "DATI\server.pid" >nul 2>&1
)
REM attesa ~2s per il rilascio della porta
ping -n 3 127.0.0.1 >nul

echo [2/3] Avvio server locale (finestra PowerShell minimizzata)...
start "Cronologia Guzzi Twr - Server" /MIN powershell -ExecutionPolicy Bypass -NoExit -Command "cd '%~dp0'; .\server.ps1"

REM piccola attesa per dare tempo al server di partire
ping -n 2 127.0.0.1 >nul

echo [3/3] Apertura app nel browser (Microsoft Edge)...
start msedge.exe http://localhost:5040

echo.
echo App avviata!
echo Se il browser non si apre da solo, vai su:  http://localhost:5040
echo Per chiudere tutto: chiudi la finestra PowerShell minimizzata.
echo.

popd
exit
