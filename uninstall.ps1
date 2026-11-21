# Script gỡ bỏ Custom Watermark và khôi phục chữ "Activate Windows" gốc
# Chạy bằng 1 lệnh PowerShell:
#   irm https://raw.githubusercontent.com/donamvn/custom-watermark-thcs-hongvan2/main/uninstall.ps1 | iex

$installDir = Join-Path $env:LOCALAPPDATA "CustomWatermark"
$scriptFile = Join-Path $installDir "CustomWatermark.ps1"
$startupCmd = Join-Path ([Environment]::GetFolderPath('Startup')) "CustomWatermark.cmd"

if (Test-Path $scriptFile) {
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptFile -UninstallStartup
    Remove-Item $installDir -Recurse -Force -ErrorAction SilentlyContinue
} else {
    if (Test-Path $startupCmd) { Remove-Item $startupCmd -Force -ErrorAction SilentlyContinue }
    Unregister-ScheduledTask -TaskName "CustomWatermarkTask" -Confirm:$false -ErrorAction SilentlyContinue
}

Write-Host "[OK] Đã gỡ bỏ hoàn toàn và khôi phục Watermark gốc của Windows." -ForegroundColor Green