# ==========================================
# iCSI MINER AUTO-SETUP INSTALLER
# ==========================================

# 1. Admin Check
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: Please right-click this script and select 'Run with PowerShell' -> 'Run as Administrator'" -ForegroundColor Red
    Start-Sleep -s 5
    Exit
}

Write-Host "=== iCSI MINER INSTALLATION STARTED ===" -ForegroundColor Cyan

# 2. Configuration
$InstallPath = "C:\Miner"
$BaseRepoUrl = "https://github.com/androidteacher/iCSI_Coin_2026.git"

# === YOUR REPO IS LINKED HERE ===
$MyRepoBase = "https://raw.githubusercontent.com/brodie10/icsicoinautomine/main/My_Miner_Installer/assets" 

# 3. Install Docker Desktop if missing
Write-Host "[1/6] Checking Docker requirements..."
if (Get-Command "docker" -ErrorAction SilentlyContinue) {
    Write-Host "Docker is already installed." -ForegroundColor Green
} else {
    Write-Host "Docker not found. Installing via Winget..." -ForegroundColor Yellow
    winget install -e --id Docker.DockerDesktop --accept-source-agreements --accept-package-agreements
    Write-Host "Docker installed. A system restart may be required after setup." -ForegroundColor Yellow
}

# 4. Create Directory Structure
Write-Host "[2/6] Creating Miner Directory at $InstallPath..."
if (!(Test-Path $InstallPath)) { New-Item -ItemType Directory -Force -Path $InstallPath | Out-Null }

# 5. Clone the Base Project (AndroidTeacher Repo)
Set-Location $InstallPath
if (Test-Path "$InstallPath\iCSI_Coin_2026") {
    Write-Host "Base project already exists. Skipping clone."
} else {
    Write-Host "[3/6] Cloning Base Repository (androidteacher)..."
    try {
        git clone $BaseRepoUrl
    } catch {
        Write-Host "Git not found. Installing Git..." -ForegroundColor Yellow
        winget install -e --id Git.Git
        # Refresh env variables so we can use git immediately
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        git clone $BaseRepoUrl
    }
}

# 6. Download YOUR Custom Fixes (From brodie10 Repo)
$TargetDir = "$InstallPath\iCSI_Coin_2026\iCSI_COIN_PYTHON_PORT"
Write-Host "[4/6] Downloading Custom Configs from GitHub..."

# Download docker-compose.yml
Invoke-WebRequest -Uri "$MyRepoBase/docker-compose.yml" -OutFile "$TargetDir\docker-compose.yml"
# Download StartMiner.bat
Invoke-WebRequest -Uri "$MyRepoBase/StartMiner.bat" -OutFile "$TargetDir\StartMiner.bat"
# Download InvisibleMiner.vbs
Invoke-WebRequest -Uri "$MyRepoBase/InvisibleMiner.vbs" -OutFile "$TargetDir\InvisibleMiner.vbs"

# 7. Create Stealth Auto-Start Task
Write-Host "[5/6] Creating Auto-Start Task..."
$Action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$TargetDir\InvisibleMiner.vbs`"" -WorkingDirectory $TargetDir
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontForce
$Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\INTERACTIVE" -LogonType Interactive

# Remove old task if exists to prevent errors
Unregister-ScheduledTask -TaskName "BlockchainMinerAuto" -Confirm:$false -ErrorAction SilentlyContinue
# Register new task
Register-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -TaskName "BlockchainMinerAuto" -Description "Auto-starts iCSI Miner in Stealth Mode" -Force | Out-Null

# 8. Start It Now
Write-Host "[6/6] Launching Miner..."
Start-Process "$TargetDir\StartMiner.bat"

Write-Host "=== INSTALLATION COMPLETE ===" -ForegroundColor Green
Write-Host "The miner is running and will auto-start on login."
Pause
