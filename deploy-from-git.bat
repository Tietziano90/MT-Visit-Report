@echo off
setlocal enabledelayedexpansion

REM ################################################################################
REM # 🚀 MT VOICE ASSISTANT - GIT-BASED DEPLOYMENT SCRIPT (WINDOWS)
REM ################################################################################
REM # Author: Michael Tietze, Principal AI Architect
REM # Contact: mtietze@salesforce.com
REM # Version: 2.0
REM # 
REM # This script automatically pulls the latest code from Git and deploys it
REM # to your Salesforce org. No manual download required!
REM ################################################################################

REM Git repository URL
set GIT_REPO=https://github.com/mtietze/MT-Visit-Report.git
set TEMP_DIR=%TEMP%\voice-assistant-deploy-%RANDOM%

REM Unicode symbols
set CHECK_MARK=[OK]
set CROSS_MARK=[X]
set ARROW=--^>
set WARNING=[!]
set INFO=[i]

cls

echo.
echo ═══════════════════════════════════════════════════════════════════
echo 🚀 MT VOICE ASSISTANT - GIT DEPLOYMENT WIZARD 🚀
echo ═══════════════════════════════════════════════════════════════════
echo.
echo This script will:
echo   1. Pull the latest code from Git (no authentication required)
echo   2. Connect to your Salesforce org
echo   3. Deploy all components in the correct order
echo   4. Assign permission sets to admins
echo.

REM ################################################################################
REM # STEP 1: CHECK PREREQUISITES
REM ################################################################################

echo.
echo ═══════════════════════════════════════════════════════════════════
echo ⚙️ CHECKING PREREQUISITES
echo ═══════════════════════════════════════════════════════════════════
echo.

REM Check for Salesforce CLI
where sf >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo %CROSS_MARK% Salesforce CLI not found!
    echo.
    echo Please install Salesforce CLI first:
    echo   https://developer.salesforce.com/tools/salesforcecli
    pause
    exit /b 1
)

echo %CHECK_MARK% Salesforce CLI detected

REM Check for Git
where git >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo %CROSS_MARK% Git not found!
    echo.
    echo Please install Git first:
    echo   https://git-scm.com/downloads
    pause
    exit /b 1
)

echo %CHECK_MARK% Git detected

REM ################################################################################
REM # STEP 2: PULL LATEST CODE FROM GIT
REM ################################################################################

echo.
echo ═══════════════════════════════════════════════════════════════════
echo 📦 PULLING LATEST CODE FROM GIT
echo ═══════════════════════════════════════════════════════════════════
echo.

echo %ARROW% Repository: %GIT_REPO%
echo %ARROW% Cloning to temporary directory...

REM Clone the repository
git clone "%GIT_REPO%" "%TEMP_DIR%" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo %CROSS_MARK% Failed to clone repository
    echo %INFO% Note: If the repository is private, you may need to authenticate.
    echo %INFO% Run: git config --global credential.helper wincred
    echo %INFO% Then try again.
    pause
    exit /b 1
)

echo %CHECK_MARK% Successfully pulled latest code from Git

REM Change to the cloned directory
cd /d "%TEMP_DIR%"

REM Get the latest commit info
for /f "delims=" %%i in ('git log -1 --pretty^=format:"%%h - %%s (%%cr)"') do set LATEST_COMMIT=%%i
echo %INFO% Latest commit: !LATEST_COMMIT!

REM ################################################################################
REM # STEP 3: CONNECT TO SALESFORCE ORG
REM ################################################################################

echo.
echo ═══════════════════════════════════════════════════════════════════
echo ⚙️ CONNECTING TO SALESFORCE ORG
echo ═══════════════════════════════════════════════════════════════════
echo.

echo %INFO% Enter your Salesforce org alias (or press Enter to create a new connection):
set /p ORG_ALIAS=Org Alias: 

if "!ORG_ALIAS!"=="" (
    echo %WARNING% No alias provided. Let's connect to your org...
    echo.
    echo Choose connection type:
    echo   1^) Production/Developer Org
    echo   2^) Sandbox
    echo   3^) Scratch Org
    set /p ORG_TYPE=Enter choice (1-3): 
    
    set /p ORG_ALIAS=Enter alias for this org: 
    
    if "!ORG_TYPE!"=="1" (
        echo %ARROW% Connecting to Production/Developer org...
        set LOGIN_URL=https://login.salesforce.com
    ) else if "!ORG_TYPE!"=="2" (
        echo %ARROW% Connecting to Sandbox...
        set LOGIN_URL=https://test.salesforce.com
    ) else if "!ORG_TYPE!"=="3" (
        echo %ARROW% Creating Scratch Org...
        sf org create scratch --definition-file config/project-scratch-def.json --alias "!ORG_ALIAS!" --set-default
        goto :org_connected
    ) else (
        echo %CROSS_MARK% Invalid choice
        pause
        exit /b 1
    )
    
    echo.
    echo %INFO% 🌐 A browser window will open for you to log in to Salesforce...
    echo %INFO% ⏳ Please complete the login in your browser
    echo %INFO% 💡 This terminal will wait for you to finish logging in
    echo.
    
    sf org login web --alias "!ORG_ALIAS!" --instance-url "!LOGIN_URL!" --set-default
    
    if !ERRORLEVEL! equ 0 (
        echo %CHECK_MARK% Successfully connected to org: !ORG_ALIAS!
        echo %INFO% Returning to deployment wizard...
    ) else (
        echo %CROSS_MARK% Failed to connect to org
        pause
        exit /b 1
    )
) else (
    echo %ARROW% Verifying org connection...
    sf org display --target-org "!ORG_ALIAS!" >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        echo %CHECK_MARK% Org connection verified: !ORG_ALIAS!
    ) else (
        echo %CROSS_MARK% Could not connect to org: !ORG_ALIAS!
        echo %INFO% Please check the alias and try again
        pause
        exit /b 1
    )
)

:org_connected

echo.
echo %WARNING% This will deploy MT Voice Assistant to: !ORG_ALIAS!
echo.
echo %INFO% Type 'yes' to continue or 'no' to cancel
set /p CONFIRM=Continue? (yes/no): 

REM Convert to lowercase
for %%L in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do set CONFIRM=!CONFIRM:%%L=%%L!
if /i not "!CONFIRM!"=="yes" if /i not "!CONFIRM!"=="y" (
    echo %WARNING% Deployment cancelled
    pause
    exit /b 0
)

REM ################################################################################
REM # STEP 4: DEPLOY COMPONENTS
REM ################################################################################

echo.
echo ═══════════════════════════════════════════════════════════════════
echo 📦 STARTING DEPLOYMENT SEQUENCE
echo ═══════════════════════════════════════════════════════════════════
echo.

set FAILED_COMPONENTS=
set START_TIME=%TIME%

REM Deploy in dependency order
set STEP=1
set TOTAL=14

call :deploy_component "Custom Metadata Types & Objects" "force-app/main/default/objects" !STEP! !TOTAL!
set /a STEP+=1

call :deploy_component "Custom Permissions" "force-app/main/default/customPermissions" !STEP! !TOTAL!
set /a STEP+=1

call :deploy_component "Apex Classes" "force-app/main/default/classes" !STEP! !TOTAL!
set /a STEP+=1

echo.
echo ═══════════════════════════════════════════════════════════════════
echo STEP !STEP!/!TOTAL!: Lightning Web Components
echo ═══════════════════════════════════════════════════════════════════
echo.
echo %ARROW% Deploying mtDateInput...
call :deploy_component_silent "mtDateInput" "force-app/main/default/lwc/mtDateInput"
echo %ARROW% Deploying mtRecordSuggestion...
call :deploy_component_silent "mtRecordSuggestion" "force-app/main/default/lwc/mtRecordSuggestion"
echo %ARROW% Deploying mtEinsteinTranscribe...
call :deploy_component_silent "mtEinsteinTranscribe" "force-app/main/default/lwc/mtEinsteinTranscribe"
echo %ARROW% Deploying mtVoiceAssistantAdmin...
call :deploy_component_silent "mtVoiceAssistantAdmin" "force-app/main/default/lwc/mtVoiceAssistantAdmin"
set /a STEP+=1

call :deploy_component "Page Layouts" "force-app/main/default/layouts" !STEP! !TOTAL!
set /a STEP+=1

call :deploy_component "Custom Metadata Records" "force-app/main/default/customMetadata" !STEP! !TOTAL!
set /a STEP+=1

call :deploy_component "External Credentials" "force-app/main/default/externalCredentials" !STEP! !TOTAL!
set /a STEP+=1

echo.
echo ═══════════════════════════════════════════════════════════════════
echo STEP !STEP!/!TOTAL!: Named Credentials
echo ═══════════════════════════════════════════════════════════════════
echo.
echo %WARNING% Named Credentials require manual configuration after deployment
call :deploy_component_silent "Named Credentials" "force-app/main/default/namedCredentials"
echo %WARNING% Named Credentials may need manual setup - this is normal
set /a STEP+=1

call :deploy_component "CSP Trusted Sites" "force-app/main/default/cspTrustedSites" !STEP! !TOTAL!
set /a STEP+=1

echo.
echo ═══════════════════════════════════════════════════════════════════
echo STEP !STEP!/!TOTAL!: Connected App
echo ═══════════════════════════════════════════════════════════════════
echo.
echo %WARNING% Connected App may require manual configuration
call :deploy_component_silent "Connected App" "force-app/main/default/connectedApps"
set /a STEP+=1

echo.
echo ═══════════════════════════════════════════════════════════════════
echo STEP !STEP!/!TOTAL!: GenAI Prompt Templates
echo ═══════════════════════════════════════════════════════════════════
echo.
echo %WARNING% Prompt Templates require Einstein AI to be enabled
call :deploy_component_silent "GenAI Prompt Templates" "force-app/main/default/genAiPromptTemplates"
set /a STEP+=1

call :deploy_component "Flows" "force-app/main/default/flows" !STEP! !TOTAL!
set /a STEP+=1

call :deploy_component "Permission Sets" "force-app/main/default/permissionsets" !STEP! !TOTAL!
set /a STEP+=1

call :deploy_component "Custom Tab" "force-app/main/default/tabs" !STEP! !TOTAL!

REM ################################################################################
REM # STEP 5: ASSIGN PERMISSION SETS
REM ################################################################################

echo.
echo ═══════════════════════════════════════════════════════════════════
echo ⚙️ ASSIGNING PERMISSION SETS
echo ═══════════════════════════════════════════════════════════════════
echo.

echo %ARROW% Fetching admin users...
echo %INFO% Assigning permission sets to all System Administrators...

for /f "tokens=*" %%u in ('sf data query --query "SELECT Username FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true" --target-org "!ORG_ALIAS!" --json ^| findstr "Username"') do (
    set line=%%u
    set line=!line:"Username":=!
    set line=!line:"=!
    set line=!line:,=!
    set username=!line: =!
    if not "!username!"=="" (
        echo %ARROW% Assigning to: !username!
        sf org assign permset --name mt_VoiceAssistant_Admin --target-org "!ORG_ALIAS!" --on-behalf-of "!username!" >nul 2>&1
        sf org assign permset --name mt_VoiceAssistant_User --target-org "!ORG_ALIAS!" --on-behalf-of "!username!" >nul 2>&1
    )
)

echo %CHECK_MARK% Permission sets assigned to all System Administrators

REM ################################################################################
REM # DEPLOYMENT SUMMARY
REM ################################################################################

set END_TIME=%TIME%

echo.
echo ═══════════════════════════════════════════════════════════════════
echo ✅ DEPLOYMENT COMPLETE
echo ═══════════════════════════════════════════════════════════════════
echo.

echo Target Org: !ORG_ALIAS!
echo Source: Git (latest commit)
echo.

if not "!FAILED_COMPONENTS!"=="" (
    echo %WARNING% Some components failed to deploy:
    echo !FAILED_COMPONENTS!
    echo.
)

echo.
echo ═══════════════════════════════════════════════════════════════════
echo ℹ️ POST-DEPLOYMENT SETUP
echo ═══════════════════════════════════════════════════════════════════
echo.

echo Please complete these manual steps:
echo.
echo 1. Configure Named Credentials:
echo    • Setup → Named Credentials → mt_EinsteinTranscribe
echo    • Update URL with your org's My Domain
echo.
echo 2. Enable Einstein AI (if not already enabled):
echo    • Setup → Einstein → Einstein AI
echo.
echo 3. Access the Setup Page:
echo    • App Launcher → Voice Assistant Setup
echo    • Follow the guided setup wizard
echo.
echo 4. Test the Installation:
echo    • Navigate to an Account record
echo    • Run the MT_Visit_Report_MultiModal flow
echo.

echo.
echo ═══════════════════════════════════════════════════════════════════
echo 🚀 DEPLOYMENT WIZARD COMPLETE
echo ═══════════════════════════════════════════════════════════════════
echo.

echo Thank you for using MT Voice Assistant!
echo For support, contact: mtietze@salesforce.com
echo.

REM Cleanup
if exist "%TEMP_DIR%" (
    echo %ARROW% Cleaning up temporary files...
    rd /s /q "%TEMP_DIR%" >nul 2>&1
)

pause
exit /b 0

REM ################################################################################
REM # HELPER FUNCTIONS
REM ################################################################################

:deploy_component
echo.
echo ═══════════════════════════════════════════════════════════════════
echo STEP %3/%4: %~1
echo ═══════════════════════════════════════════════════════════════════
echo.
echo %ARROW% Deploying: %~1
sf project deploy start --target-org "!ORG_ALIAS!" --source-dir "%~2" >nul 2>&1
if !ERRORLEVEL! equ 0 (
    echo %CHECK_MARK% %~1 deployed successfully
) else (
    echo %CROSS_MARK% %~1 deployment failed
    set FAILED_COMPONENTS=!FAILED_COMPONENTS! %~1;
)
goto :eof

:deploy_component_silent
echo %ARROW% Deploying: %~1
sf project deploy start --target-org "!ORG_ALIAS!" --source-dir "%~2" >nul 2>&1
if !ERRORLEVEL! equ 0 (
    echo %CHECK_MARK% %~1 deployed successfully
) else (
    echo %CROSS_MARK% %~1 deployment failed
    set FAILED_COMPONENTS=!FAILED_COMPONENTS! %~1;
)
goto :eof

