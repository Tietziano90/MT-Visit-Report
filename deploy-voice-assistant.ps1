################################################################################
# 🚀 MT VOICE ASSISTANT - ONE-CLICK DEPLOYMENT (Windows PowerShell)
################################################################################
# 
# This script automatically:
# 1. Downloads the latest code from GitHub
# 2. Deploys to your Salesforce org
# 3. Assigns permissions
# 4. Cleans up
#
# Just run: .\deploy-voice-assistant.ps1
# Version: 1.1
#
################################################################################

# Set execution policy for this session (in case it's restricted)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Variables
$TEMP_DIR = "$env:TEMP\mt-voice-assistant-$(Get-Random)"
$GITHUB_REPO = "https://github.com/Tietziano90/MT-Visit-Report.git"

################################################################################
# FUNCTIONS
################################################################################

function Print-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Print-Success {
    param([string]$Message)
    Write-Host "✓ " -ForegroundColor Green -NoNewline
    Write-Host $Message -ForegroundColor White
}

function Print-Error {
    param([string]$Message)
    Write-Host "✗ " -ForegroundColor Red -NoNewline
    Write-Host $Message -ForegroundColor White
}

function Print-Step {
    param([string]$Message)
    Write-Host "→ " -ForegroundColor Blue -NoNewline
    Write-Host $Message -ForegroundColor White
}

function Print-Warning {
    param([string]$Message)
    Write-Host "⚠️  " -ForegroundColor Yellow -NoNewline
    Write-Host $Message -ForegroundColor Yellow
}

function Cleanup {
    if (Test-Path $TEMP_DIR) {
        Remove-Item -Path $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Register cleanup on exit
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { Cleanup }

################################################################################
# MAIN SCRIPT
################################################################################

################################################################################
# CHECK PREREQUISITES
################################################################################

Print-Header "⚙️ CHECKING PREREQUISITES"

# Check Salesforce CLI
Print-Step "Checking for Salesforce CLI..."
$sfInstalled = Get-Command sf -ErrorAction SilentlyContinue

if (-not $sfInstalled) {
    Print-Error "Salesforce CLI not found!"
    Write-Host ""
    Write-Host "The Salesforce CLI is required to deploy this app." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Installation options:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Option 1: Download Windows Installer (Recommended)" -ForegroundColor White
    Write-Host "  https://developer.salesforce.com/tools/salesforcecli" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Option 2: Install via npm (if you have Node.js)" -ForegroundColor White
    Write-Host "  npm install -g @salesforce/cli" -ForegroundColor Gray
    Write-Host ""
    
    # Check if npm is available
    $npmInstalled = Get-Command npm -ErrorAction SilentlyContinue
    
    if ($npmInstalled) {
        Print-Success "npm detected!"
        Write-Host ""
        $installChoice = Read-Host "Would you like to install Salesforce CLI via npm now? (yes/no)"
        
        if ($installChoice -match "^(yes|y)$") {
            Write-Host ""
            Print-Step "Installing Salesforce CLI via npm..."
            
            try {
                npm install -g @salesforce/cli
                
                # Refresh PATH
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                
                # Check if installed
                $sfInstalled = Get-Command sf -ErrorAction SilentlyContinue
                
                if ($sfInstalled) {
                    Print-Success "Salesforce CLI installed successfully!"
                    Write-Host ""
                } else {
                    Print-Error "Installation completed but 'sf' command not found."
                    Write-Host ""
                    Write-Host "Please close and reopen PowerShell, then run this script again." -ForegroundColor Yellow
                    exit 1
                }
            } catch {
                Print-Error "Installation failed: $_"
                Write-Host ""
                Write-Host "Please install manually from: https://developer.salesforce.com/tools/salesforcecli" -ForegroundColor Yellow
                exit 1
            }
        } else {
            Write-Host ""
            Write-Host "Please install Salesforce CLI and run this script again." -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "Please install Salesforce CLI manually:" -ForegroundColor Yellow
        Write-Host "  1. Visit: https://developer.salesforce.com/tools/salesforcecli"
        Write-Host "  2. Download the Windows installer"
        Write-Host "  3. Run the installer"
        Write-Host "  4. Restart PowerShell"
        Write-Host "  5. Run this script again"
        Write-Host ""
        
        # Ask if they want to open the download page
        $openBrowser = Read-Host "Would you like to open the download page now? (yes/no)"
        if ($openBrowser -match "^(yes|y)$") {
            Start-Process "https://developer.salesforce.com/tools/salesforcecli"
        }
        
        exit 1
    }
} else {
    Print-Success "Salesforce CLI found"
    $sfVersion = (sf --version 2>$null | Select-Object -First 1)
    Write-Host "  Version: $sfVersion" -ForegroundColor Gray
}

# Check Git
Print-Step "Checking for Git..."
$gitInstalled = Get-Command git -ErrorAction SilentlyContinue

if (-not $gitInstalled) {
    Print-Error "Git not found!"
    Write-Host ""
    Write-Host "Git is required to download the deployment code." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Installation options:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Option 1: Download Git for Windows (Recommended)" -ForegroundColor White
    Write-Host "  https://git-scm.com/download/win" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Option 2: Install via Chocolatey (if you have it)" -ForegroundColor White
    Write-Host "  choco install git" -ForegroundColor Gray
    Write-Host ""
    
    # Check if Chocolatey is available
    $chocoInstalled = Get-Command choco -ErrorAction SilentlyContinue
    
    if ($chocoInstalled) {
        Print-Success "Chocolatey detected!"
        Write-Host ""
        $installChoice = Read-Host "Would you like to install Git via Chocolatey now? (yes/no)"
        
        if ($installChoice -match "^(yes|y)$") {
            Write-Host ""
            Print-Step "Installing Git via Chocolatey..."
            
            try {
                choco install git -y
                
                # Refresh PATH
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                
                # Check if installed
                $gitInstalled = Get-Command git -ErrorAction SilentlyContinue
                
                if ($gitInstalled) {
                    Print-Success "Git installed successfully!"
                    Write-Host ""
                } else {
                    Print-Error "Installation completed but 'git' command not found."
                    Write-Host ""
                    Write-Host "Please close and reopen PowerShell, then run this script again." -ForegroundColor Yellow
                    exit 1
                }
            } catch {
                Print-Error "Installation failed: $_"
                Write-Host ""
                Write-Host "Please install manually from: https://git-scm.com/download/win" -ForegroundColor Yellow
                exit 1
            }
        } else {
            Write-Host ""
            Write-Host "Please install Git and run this script again." -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "Please install Git manually:" -ForegroundColor Yellow
        Write-Host "  1. Visit: https://git-scm.com/download/win"
        Write-Host "  2. Download the Windows installer"
        Write-Host "  3. Run the installer (use default settings)"
        Write-Host "  4. Restart PowerShell"
        Write-Host "  5. Run this script again"
        Write-Host ""
        
        # Ask if they want to open the download page
        $openBrowser = Read-Host "Would you like to open the download page now? (yes/no)"
        if ($openBrowser -match "^(yes|y)$") {
            Start-Process "https://git-scm.com/download/win"
        }
        
        exit 1
    }
} else {
    Print-Success "Git found"
    $gitVersion = (git --version 2>$null)
    Write-Host "  Version: $gitVersion" -ForegroundColor Gray
}

Write-Host ""

################################################################################
# DOWNLOAD LATEST CODE
################################################################################

Print-Header "📦 DOWNLOADING LATEST CODE FROM GITHUB"

Print-Step "Cloning repository..."
try {
    $gitOutput = git clone $GITHUB_REPO $TEMP_DIR 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Print-Success "Latest code downloaded"
    } else {
        throw "Git clone failed"
    }
} catch {
    Print-Error "Failed to download code"
    Write-Host ""
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please check your internet connection and try again." -ForegroundColor Yellow
    Cleanup
    exit 1
}

# Get latest commit info
Push-Location $TEMP_DIR
$latestCommit = git log -1 --pretty=format:"%h - %s (%cr)" 2>$null
Write-Host "Latest version: " -ForegroundColor Cyan -NoNewline
Write-Host $latestCommit -ForegroundColor White
Pop-Location

Write-Host ""

################################################################################
# RUN DEPLOYMENT
################################################################################

Print-Header "🚀 STARTING DEPLOYMENT"

# Check if deploy.sh exists (bash script)
$deployScriptBash = Join-Path $TEMP_DIR "deploy.sh"
$deployScriptPS = Join-Path $TEMP_DIR "deploy.ps1"

if (Test-Path $deployScriptPS) {
    # PowerShell deployment script exists
    Print-Step "Running PowerShell deployment script..."
    Write-Host ""
    
    Push-Location $TEMP_DIR
    try {
        & $deployScriptPS
        $deployStatus = $LASTEXITCODE
    } catch {
        Print-Error "Deployment script failed: $_"
        $deployStatus = 1
    }
    Pop-Location
    
} elseif (Test-Path $deployScriptBash) {
    # Bash script exists, check if we can run it
    $bashInstalled = Get-Command bash -ErrorAction SilentlyContinue
    
    if ($bashInstalled) {
        Print-Step "Running deployment script via bash..."
        Write-Host ""
        
        Push-Location $TEMP_DIR
        try {
            bash $deployScriptBash
            $deployStatus = $LASTEXITCODE
        } catch {
            Print-Error "Deployment script failed: $_"
            $deployStatus = 1
        }
        Pop-Location
    } else {
        Print-Warning "Bash not found. The deployment script requires bash (comes with Git for Windows)."
        Write-Host ""
        Write-Host "Please ensure Git for Windows is installed with bash support." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Alternative: Run the deployment manually:" -ForegroundColor Cyan
        Write-Host "  1. Navigate to: $TEMP_DIR"
        Write-Host "  2. Run: bash deploy.sh"
        Write-Host ""
        Cleanup
        exit 1
    }
} else {
    Print-Error "No deployment script found in repository"
    Write-Host ""
    Write-Host "Expected: deploy.sh or deploy.ps1" -ForegroundColor Yellow
    Cleanup
    exit 1
}

################################################################################
# CLEANUP & SUMMARY
################################################################################

Write-Host ""
Print-Header "🎉 DEPLOYMENT COMPLETE"

if ($deployStatus -eq 0) {
    Write-Host "✅ MT Voice Assistant deployed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Configure Named Credentials in Setup"
    Write-Host "  2. Access 'Voice Assistant Setup' from App Launcher"
    Write-Host "  3. Test on an Account record"
    Write-Host ""
    
    # Open the setup page automatically
    Print-Step "Opening Voice Assistant Setup page..."
    
    try {
        # Get the org's instance URL
        $orgInfo = sf org display --json 2>$null | ConvertFrom-Json
        $orgUrl = $orgInfo.result.instanceUrl
        
        if ($orgUrl) {
            # Open the Lightning page for MT Voice Assistant Admin
            $setupUrl = "$orgUrl/lightning/n/MT_Voice_Assistant_Settings"
            
            Start-Process $setupUrl
            
            Print-Success "Setup page opened in your browser"
            Write-Host ""
        }
    } catch {
        Print-Warning "Could not automatically open browser"
        Write-Host "Please open your Salesforce org and navigate to 'Voice Assistant Setup'" -ForegroundColor Yellow
        Write-Host ""
    }
} else {
    Write-Host "⚠️  Deployment completed with warnings" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please review the output above for any issues." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Repository: https://github.com/Tietziano90/MT-Visit-Report" -ForegroundColor Gray
Write-Host "Support: mtietze@salesforce.com" -ForegroundColor Gray
Write-Host ""

Print-Header "✨ THANK YOU FOR USING MT VOICE ASSISTANT ✨"

# Cleanup
Cleanup

# Pause so user can read the output
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
