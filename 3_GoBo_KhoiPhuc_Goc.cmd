@echo off
chcp 65001 >nul
if exist "%LOCALAPPDATA%\CustomWatermark\CustomWatermark.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\CustomWatermark\CustomWatermark.ps1" -UninstallStartup
    rmdir /S /Q "%LOCALAPPDATA%\CustomWatermark" 2>nul
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0CustomWatermark.ps1" -UninstallStartup
)
echo.
echo [OK] Da go bo tu khoi dong va khoi phuc Watermark goc cua Windows.
pause