# Bootstrap: downloads install.ps1 and runs it properly with -File
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue
$ProgressPreference = 'SilentlyContinue'  # suppress PS5.1 blue progress bar during download
$tmp = "$env:TEMP\gh-copilot-setup-install.ps1"
Write-Host "`n[GH Copilot Setup] Downloading installer..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/marcusash/gh-copilot-setup/main/install.ps1" -OutFile $tmp -UseBasicParsing
if (-not (Test-Path $tmp)) { Write-Host "Download failed. Check your internet connection." -ForegroundColor Red; return }
Write-Host "[GH Copilot Setup] Starting installer..." -ForegroundColor Cyan
powershell -NoProfile -ExecutionPolicy Bypass -File $tmp
