# WorkIQ Plugin Installer
# Called by install.ps1. Can also be run standalone.

param([switch]$WhatIf)

$ErrorActionPreference = "Continue"

function Write-Step($msg) { Write-Host "`n[WorkIQ] $msg" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "  [OK]  $msg" -ForegroundColor Green }
function Write-Fail($msg) { Write-Host "  [FAIL] $msg" -ForegroundColor Red }
function Write-Warn($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }

function Refresh-Path {
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("PATH", "User")
}

# -----------------------------------------------------------------------
# STEP 1: Install @microsoft/workiq npm package
# -----------------------------------------------------------------------
Write-Step "Checking WorkIQ install"

$wiq = Get-Command workiq -ErrorAction SilentlyContinue
if ($wiq) {
    $wiqVer = workiq version 2>&1 | Select-Object -First 1
    Write-OK "Already installed: $wiqVer"
} else {
    Write-Host "  Installing WorkIQ via npm (@microsoft/workiq)..." -ForegroundColor Gray
    if (-not $WhatIf) {
        npm install -g @microsoft/workiq 2>&1 | Select-Object -Last 3 | ForEach-Object { Write-Host "  $_" }
        if ($LASTEXITCODE -eq 0) {
            Refresh-Path
            Write-OK "WorkIQ installed"
        } else {
            Write-Fail "npm install failed for @microsoft/workiq"
            Write-Host "  Retry manually: npm install -g @microsoft/workiq" -ForegroundColor Gray
            exit 1
        }
    } else {
        Write-Host "  would install @microsoft/workiq" -ForegroundColor Yellow
    }
}

if ($WhatIf) {
    Write-Host "  [DRY RUN] Skipping EULA, auth, and MCP registration" -ForegroundColor Yellow
    exit 0
}

# -----------------------------------------------------------------------
# STEP 2: Accept EULA
# -----------------------------------------------------------------------
Write-Step "Accepting WorkIQ EULA"

$eulaResult = workiq accept-eula 2>&1
$eulaStr    = $eulaResult -join " "
if ($LASTEXITCODE -eq 0 -or $eulaStr -match "accepted|already") {
    Write-OK "EULA accepted"
} else {
    Write-Warn "EULA result: $eulaStr"
}

# -----------------------------------------------------------------------
# STEP 3: Register WorkIQ as MCP server in Copilot CLI config
# (Auth happens automatically on first use inside AI Maker)
# -----------------------------------------------------------------------
Write-Step "Registering WorkIQ as MCP server"

$copilotConfig = "$env:USERPROFILE\.copilot\config.json"
if (-not (Test-Path $copilotConfig)) {
    $configDir = Split-Path $copilotConfig
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    '{}' | Set-Content -Path $copilotConfig
}

$cfg = Get-Content $copilotConfig -Raw | ConvertFrom-Json
if (-not $cfg.PSObject.Properties["mcpServers"]) {
    $cfg | Add-Member -MemberType NoteProperty -Name "mcpServers" -Value ([PSCustomObject]@{})
}
$cfg.mcpServers | Add-Member -MemberType NoteProperty -Name "workiq" -Value ([PSCustomObject]@{
    command = "workiq"; args = @("mcp")
}) -Force
if (-not $cfg.PSObject.Properties["trusted_folders"]) {
    $cfg | Add-Member -MemberType NoteProperty -Name "trusted_folders" -Value @("C:\AIMaker")
} elseif (@($cfg.trusted_folders) -notcontains "C:\AIMaker") {
    $cfg.trusted_folders = @($cfg.trusted_folders) + "C:\AIMaker"
}
$cfg | ConvertTo-Json -Depth 10 | Set-Content -Path $copilotConfig -Encoding UTF8
Write-OK "WorkIQ registered as MCP server in Copilot CLI config"

Write-Host ""
Write-Host "  WorkIQ is ready." -ForegroundColor Green
Write-Host "  To complete M365 auth: open AI Maker and run 'What are my meetings today?'" -ForegroundColor Yellow
Write-Host "  A browser sign-in window will open on first use." -ForegroundColor Gray
exit 0
