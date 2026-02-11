# ==========================================
# iCSI MINER AUTO-SETUP INSTALLER
# ==========================================
# Checks for Admin Privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: Please right-click this script and select 'Run with PowerShell' -> 'Run as Administrator'" -ForegroundColor Red
    Start-Sleep -s 5
    Exit
}

Write-Host "=== iCSI MINER INSTALLATION STARTED ===" -ForegroundColor Cyan

# 1. Install Docker Desktop if missing
Write-Host "[1/5] Checking Docker requirements..."
if (Get-Command "docker" -ErrorAction SilentlyContinue) {
    Write-Host "Docker is already installed." -ForegroundColor Green
} else {
    Write-Host "Docker not found. Installing via Winget..." -ForegroundColor Yellow
    winget install -e --id Docker.DockerDesktop --accept-source-agreements --accept-package-agreements
    Write-Host "Docker installed. A system restart may be required after setup." -ForegroundColor Yellow
}

# 2. Prepare the Directory
$InstallPath = "C:\Miner"
$RepoUrl = "https://github.com/androidteacher/iCSI_Coin_2026.git"
$ScriptPath = $PSScriptRoot  # The folder where this script is running from

Write-Host "[2/5] Setting up C:\Miner..."
if (!(Test-Path $InstallPath)) { New-Item -ItemType Directory -Force -Path $InstallPath | Out-Null }

# 3. Clone the Base Project
Set-Location $InstallPath
if (Test-Path "$InstallPath\iCSI_Coin_2026") {
    Write-Host "Project folder exists. Skipping download."
} else {
    Write-Host "Cloning original miner repository..."
    try {
        git clone $RepoUrl
    } catch {
        Write-Host "Git not found. Installing Git..." -ForegroundColor Yellow
        winget install -e --id Git.Git
        git clone $RepoUrl
    }
}

# 4. Inject Custom Fixes (Copy from 'assets' folder to C:\Miner)
$TargetDir = "$InstallPath\iCSI_Coin_2026\iCSI_COIN_PYTHON_PORT"
Write-Host "[3/5] Applying Windows Fixes & Custom Config..."

Copy-Item -Force "$ScriptPath\assets\docker-compose.yml" -Destination "$TargetDir\docker-compose.yml"
Copy-Item -Force "$ScriptPath\assets\StartMiner.bat" -Destination "$TargetDir\StartMiner.bat"
Copy-Item -Force "$ScriptPath\assets\InvisibleMiner.vbs" -Destination "$TargetDir\InvisibleMiner.vbs"

# 5. Create Stealth Auto-Start Task
Write-Host "[4/5] Creating Auto-Start Task..."
$Action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$TargetDir\InvisibleMiner.vbs`"" -WorkingDirectory $TargetDir
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontForce
$Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\INTERACTIVE" -LogonType Interactive

Unregister-ScheduledTask -TaskName "BlockchainMinerAuto" -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -TaskName "BlockchainMinerAuto" -Description "Auto-starts iCSI Miner in Stealth Mode" -Force | Out-Null

Write-Host "=== INSTALLATION COMPLETE ===" -ForegroundColor Green
Write-Host "The miner is set to auto-start on login."
Write-Host "To start immediately, run: C:\Miner\iCSI_Coin_2026\iCSI_COIN_PYTHON_PORT\StartMiner.bat"
Pause