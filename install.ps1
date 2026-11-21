# Script cài đặt nhanh Custom Watermark trực tiếp từ GitHub
# Chạy bằng 1 lệnh PowerShell:
#   irm https://raw.githubusercontent.com/donamvn/custom-watermark-thcs-hongvan2/main/install.ps1 | iex

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# >>> THAY donamvn BẰNG TÊN TÀI KHOẢN GITHUB CỦA BẠN <<<
$RepoRawUrl = "https://raw.githubusercontent.com/donamvn/custom-watermark-thcs-hongvan2/main"

$installDir = Join-Path $env:LOCALAPPDATA "CustomWatermark"
$scriptFile = Join-Path $installDir "CustomWatermark.ps1"
$startupCmd = Join-Path ([Environment]::GetFolderPath('Startup')) "CustomWatermark.cmd"

if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

Write-Host "[1/3] Đang tải CustomWatermark.ps1 từ GitHub..." -ForegroundColor Cyan
$wc = New-Object System.Net.WebClient
$wc.DownloadFile("$RepoRawUrl/CustomWatermark.ps1", $scriptFile)

Write-Host "[2/3] Đang cài đặt tự khởi động cùng Windows..." -ForegroundColor Cyan
$cmdContent = "@echo off`r`nstart `"`" powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"%LOCALAPPDATA%\CustomWatermark\CustomWatermark.ps1`"`r`n"
[System.IO.File]::WriteAllText($startupCmd, $cmdContent, [System.Text.Encoding]::ASCII)

Write-Host "[3/3] Đang khởi chạy Watermark mới..." -ForegroundColor Cyan
Start-Process powershell.exe -WindowStyle Hidden -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$scriptFile`""

Write-Host "[OK] Hoàn tất! Watermark THCS Hồng Vân 2 đã được bật và tự khởi động cùng Windows." -ForegroundColor Green