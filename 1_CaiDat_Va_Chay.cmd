@echo off
chcp 65001 >nul
set "INSTALL_DIR=%LOCALAPPDATA%\CustomWatermark"
set "STARTUP_CMD=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\CustomWatermark.cmd"

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
copy /Y "%~dp0CustomWatermark.ps1" "%INSTALL_DIR%\CustomWatermark.ps1" >nul

(
echo @echo off
echo start "" powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File "%%LOCALAPPDATA%%\CustomWatermark\CustomWatermark.ps1"
) > "%STARTUP_CMD%"

start "" powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File "%INSTALL_DIR%\CustomWatermark.ps1"
echo [OK] Da cai dat tu khoi dong cung Windows va bat Watermark moi!
echo Ban co the xoa thu muc giai nen nay neu muon.
timeout /t 3 >nul