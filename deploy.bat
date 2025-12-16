@echo off
REM ################################################################################
REM # 🚀 MT VOICE ASSISTANT - AUTOMATED DEPLOYMENT SCRIPT (WINDOWS)
REM ################################################################################
REM # Author: Michael Tietze, Principal AI Architect
REM # Contact: mtietze@salesforce.com
REM # Version: 1.0
REM # 
REM # This script automates the complete deployment of MT Voice Assistant
REM # to any Salesforce org with proper dependency management.
REM ################################################################################

setlocal enabledelayedexpansion
chcp 65001 >nul

REM Set color codes
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "PURPLE=[95m"
set "CYAN=[96m"
set "WHITE=[97m"
set "NC=[0m"

REM Unicode symbols
set "CHECK=✓"
set "CROSS=✗"
set "ARROW=→"
set "ROCKET=🚀"
set "GEAR=⚙️"
set "PACKAGE=📦"
set "WARNING=⚠️"
set "SUCCESS=✅"
set "ERROR=❌"
set "INFO=ℹ️"

cls

echo.
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo %WHITE%%ROCKET% MT VOICE ASSISTANT - DEPLOYMENT WIZARD %ROCKET%%NC%
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo.
echo %PURPLE%This script will deploy the complete MT Voice Assistant solution%NC%
echo %PURPLE%to your Salesforce org with all dependencies in the correct order.%NC%
echo.

REM Check Salesforce CLI
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo %WHITE%%GEAR% CHECKING PREREQUISITES%NC%
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo.

where sf >nul 2>nul
if %errorlevel% neq 0 (
    echo %RED%%ERROR% Salesforce CLI ^(sf^) is not installed!%NC%
    echo.
    echo %YELLOW%Please install Salesforce CLI:%NC%
    echo %WHITE%  Download from: %CYAN%https://developer.salesforce.com/tools/salesforcecli%NC%
    echo.
    pause
    exit /b 1
)
echo %GREEN%%CHECK% Salesforce CLI detected%NC%

REM Get org alias
echo.
echo %INFO% %CYAN%Enter your Salesforce org alias (or press Enter to create a new connection):%NC%
set /p ORG_ALIAS="Org Alias: "

if "%ORG_ALIAS%"=="" (
    echo %WARNING% %YELLOW%No alias provided. Let's connect to your org...%NC%
    echo.
    echo %CYAN%Choose connection type:%NC%
    echo %WHITE%  1^) Production/Developer Org%NC%
    echo %WHITE%  2^) Sandbox%NC%
    echo %WHITE%  3^) Scratch Org%NC%
    set /p ORG_TYPE="Enter choice (1-3): "
    
    set /p ORG_ALIAS="Enter alias for this org: "
    
    if "!ORG_TYPE!"=="1" (
        echo %ARROW% %WHITE%Connecting to Production/Developer org...%NC%
        echo.
        echo %INFO% %CYAN%A browser window will open for you to log in to Salesforce...%NC%
        echo %INFO% %CYAN%Please complete the login in your browser%NC%
        echo %INFO% %CYAN%This window will wait for you to finish logging in%NC%
        echo.
        sf org login web --alias "!ORG_ALIAS!" --instance-url https://login.salesforce.com
    ) else if "!ORG_TYPE!"=="2" (
        echo %ARROW% %WHITE%Connecting to Sandbox...%NC%
        echo.
        echo %INFO% %CYAN%A browser window will open for you to log in to Salesforce...%NC%
        echo %INFO% %CYAN%Please complete the login in your browser%NC%
        echo %INFO% %CYAN%This window will wait for you to finish logging in%NC%
        echo.
        sf org login web --alias "!ORG_ALIAS!" --instance-url https://test.salesforce.com
    ) else if "!ORG_TYPE!"=="3" (
        echo %ARROW% %WHITE%Creating Scratch Org...%NC%
        sf org create scratch --alias "!ORG_ALIAS!" --definition-file config/project-scratch-def.json --duration-days 30 --set-default
    ) else (
        echo %RED%%ERROR% Invalid choice%NC%
        pause
        exit /b 1
    )
    
    if !errorlevel! equ 0 (
        echo.
        echo %GREEN%%CHECK% Successfully connected to org: !ORG_ALIAS!%NC%
        echo %INFO% %CYAN%Returning to deployment wizard...%NC%
        echo.
        timeout /t 2 /nobreak >nul
    ) else (
        echo %RED%%ERROR% Failed to connect to org%NC%
        pause
        exit /b 1
    )
)

REM Verify org connection
echo %ARROW% %WHITE%Verifying org connection...%NC%
sf org display --target-org "%ORG_ALIAS%" >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%%ERROR% Cannot connect to org: %ORG_ALIAS%%NC%
    echo.
    echo %INFO% %CYAN%Available orgs:%NC%
    sf org list
    pause
    exit /b 1
)
echo %GREEN%%CHECK% Org connection verified: %ORG_ALIAS%%NC%

REM Confirm deployment
echo.
echo %WARNING% %YELLOW%This will deploy MT Voice Assistant to: %ORG_ALIAS%%NC%
echo.
echo %INFO% %CYAN%Type 'yes' to continue or 'no' to cancel%NC%
set /p CONFIRM="Continue? (yes/no): "

if /i not "%CONFIRM%"=="yes" (
    if /i not "%CONFIRM%"=="y" (
        echo %INFO% %CYAN%Deployment cancelled%NC%
        pause
        exit /b 0
    )
)

REM Start deployment
echo.
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo %WHITE%%PACKAGE% STARTING DEPLOYMENT SEQUENCE%NC%
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo.

set FAILED_COUNT=0

REM Step 1: Custom Metadata Types & Objects
echo.
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo STEP 1/14: Custom Metadata Types ^& Objects
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo.
echo %ARROW% %WHITE%Deploying: Custom Metadata Types ^& Objects%NC%
sf project deploy start --target-org "%ORG_ALIAS%" --source-dir "force-app/main/default/objects" >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%%CHECK% Custom Metadata Types ^& Objects deployed successfully%NC%
) else (
    echo %RED%%CROSS% Custom Metadata Types ^& Objects deployment failed%NC%
    set /a FAILED_COUNT+=1
)
timeout /t 2 /nobreak >nul

REM Step 2: Custom Permissions
echo.
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo STEP 2/14: Custom Permissions
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo.
echo %ARROW% %WHITE%Deploying: Custom Permissions%NC%
sf project deploy start --target-org "%ORG_ALIAS%" --source-dir "force-app/main/default/customPermissions" >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%%CHECK% Custom Permissions deployed successfully%NC%
) else (
    echo %RED%%CROSS% Custom Permissions deployment failed%NC%
    set /a FAILED_COUNT+=1
)
timeout /t 2 /nobreak >nul

REM Step 3: Apex Classes
echo.
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo STEP 3/14: Apex Classes
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo.
echo %ARROW% %WHITE%Deploying: Apex Classes%NC%
sf project deploy start --target-org "%ORG_ALIAS%" --source-dir "force-app/main/default/classes" >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%%CHECK% Apex Classes deployed successfully%NC%
) else (
    echo %RED%%CROSS% Apex Classes deployment failed%NC%
    set /a FAILED_COUNT+=1
)
timeout /t 2 /nobreak >nul

REM Step 4: Lightning Web Components (IN DEPENDENCY ORDER!)
echo.
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo STEP 4/14: Lightning Web Components
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo.
REM Deploy mtDateInput FIRST (no dependencies)
echo %ARROW% %WHITE%Deploying: mtDateInput%NC%
sf project deploy start --target-org "%ORG_ALIAS%" --source-dir "force-app/main/default/lwc/mtDateInput" >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%%CHECK% mtDateInput deployed successfully%NC%
) else (
    echo %RED%%CROSS% mtDateInput deployment failed%NC%
    set /a FAILED_COUNT+=1
)
timeout /t 1 /nobreak >nul

REM Deploy mtRecordSuggestion SECOND (depends on mtDateInput)
echo %ARROW% %WHITE%Deploying: mtRecordSuggestion%NC%
sf project deploy start --target-org "%ORG_ALIAS%" --source-dir "force-app/main/default/lwc/mtRecordSuggestion" >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%%CHECK% mtRecordSuggestion deployed successfully%NC%
) else (
    echo %RED%%CROSS% mtRecordSuggestion deployment failed%NC%
    set /a FAILED_COUNT+=1
)
timeout /t 1 /nobreak >nul

REM Deploy mtEinsteinTranscribe THIRD
echo %ARROW% %WHITE%Deploying: mtEinsteinTranscribe%NC%
sf project deploy start --target-org "%ORG_ALIAS%" --source-dir "force-app/main/default/lwc/mtEinsteinTranscribe" >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%%CHECK% mtEinsteinTranscribe deployed successfully%NC%
) else (
    echo %RED%%CROSS% mtEinsteinTranscribe deployment failed%NC%
    set /a FAILED_COUNT+=1
)
timeout /t 1 /nobreak >nul

REM Deploy mtVoiceAssistantAdmin LAST
echo %ARROW% %WHITE%Deploying: mtVoiceAssistantAdmin%NC%
sf project deploy start --target-org "%ORG_ALIAS%" --source-dir "force-app/main/default/lwc/mtVoiceAssistantAdmin" >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%%CHECK% mtVoiceAssistantAdmin deployed successfully%NC%
) else (
    echo %RED%%CROSS% mtVoiceAssistantAdmin deployment failed%NC%
    set /a FAILED_COUNT+=1
)
timeout /t 1 /nobreak >nul

REM Step 5: Page Layouts
echo.
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo STEP 5/14: Page Layouts
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo.
echo %ARROW% %WHITE%Deploying: Page Layouts%NC%
sf project deploy start --target-org "%ORG_ALIAS%" --source-dir "force-app/main/default/layouts" >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%%CHECK% Page Layouts deployed successfully%NC%
) else (
    echo %RED%%CROSS% Page Layouts deployment failed%NC%
    set /a FAILED_COUNT+=1
)
timeout /t 2 /nobreak >nul

REM Step 6: Custom Metadata Records
echo.
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo STEP 6/14: Custom Metadata Records
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo.
echo %ARROW% %WHITE%Deploying: Custom Metadata Records%NC%
sf project deploy start --target-org "%ORG_ALIAS%" --source-dir "force-app/main/default/customMetadata" >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%%CHECK% Custom Metadata Records deployed successfully%NC%
) else (
    echo %RED%%CROSS% Custom Metadata Records deployment failed%NC%
    set /a FAILED_COUNT+=1
)
timeout /t 2 /nobreak >nul

REM Step 7: External Credentials
echo.
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo STEP 7/14: External Credentials
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo.
echo %ARROW% %WHITE%Deploying: External Credentials%NC%
sf project deploy start --target-org "%ORG_ALIAS%" --source-dir "force-app/main/default/externalCredentials" >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%%CHECK% External Credentials deployed successfully%NC%
) else (
    echo %RED%%CROSS% External Credentials deployment failed%NC%
    set /a FAILED_COUNT+=1
)
timeout /t 2 /nobreak >nul

REM Step 8: Named Credentials
echo.
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo STEP 8/14: Named Credentials
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo.
echo %INFO% %CYAN%Named Credentials will need URL configuration after deployment%NC%
echo %ARROW% %WHITE%Deploying: Named Credentials%NC%
sf project deploy start --target-org "%ORG_ALIAS%" --source-dir "force-app/main/default/namedCredentials" >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%%CHECK% Named Credentials deployed successfully%NC%
) else (
    echo %RED%%CROSS% Named Credentials deployment failed%NC%
    set /a FAILED_COUNT+=1
)
timeout /t 2 /nobreak >nul

REM Step 9: CSP Trusted Sites
echo.
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo STEP 9/14: CSP Trusted Sites
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo.
echo %ARROW% %WHITE%Deploying: CSP Trusted Sites%NC%
sf project deploy start --target-org "%ORG_ALIAS%" --source-dir "force-app/main/default/cspTrustedSites" >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%%CHECK% CSP Trusted Sites deployed successfully%NC%
) else (
    echo %RED%%CROSS% CSP Trusted Sites deployment failed%NC%
    set /a FAILED_COUNT+=1
)
timeout /t 2 /nobreak >nul

REM Step 10: Connected App
echo.
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo STEP 10/14: Connected App
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo.
echo %WARNING% %YELLOW%Connected App may require manual configuration%NC%
echo %ARROW% %WHITE%Deploying: Connected App%NC%
sf project deploy start --target-org "%ORG_ALIAS%" --source-dir "force-app/main/default/connectedApps" >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%%CHECK% Connected App deployed successfully%NC%
) else (
    echo %YELLOW%%WARNING% Connected App may need manual setup - this is normal%NC%
)
timeout /t 2 /nobreak >nul

REM Step 11: GenAI Prompt Templates (BEFORE Flows - Flows depend on them!)
echo.
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo STEP 11/14: GenAI Prompt Templates
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo.
echo %WARNING% %YELLOW%Prompt Templates require Einstein AI to be enabled%NC%
echo %ARROW% %WHITE%Deploying: GenAI Prompt Templates%NC%
sf project deploy start --target-org "%ORG_ALIAS%" --source-dir "force-app/main/default/genAiPromptTemplates" >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%%CHECK% GenAI Prompt Templates deployed successfully%NC%
) else (
    echo %YELLOW%%WARNING% Prompt Templates failed - ensure Einstein AI is enabled%NC%
)
timeout /t 2 /nobreak >nul

REM Step 12: Custom Tab (BEFORE Flows and Permission Sets - they reference it!)
echo.
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo STEP 12/14: Custom Tab
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo.
echo %ARROW% %WHITE%Deploying: Custom Tab%NC%
sf project deploy start --target-org "%ORG_ALIAS%" --source-dir "force-app/main/default/tabs" >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%%CHECK% Custom Tab deployed successfully%NC%
) else (
    echo %RED%%CROSS% Custom Tab deployment failed%NC%
    set /a FAILED_COUNT+=1
)
timeout /t 2 /nobreak >nul

REM Step 13: Flows (AFTER Prompt Templates and Tab!)
echo.
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo STEP 13/14: Flows
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo.
echo %ARROW% %WHITE%Deploying: Flows%NC%
sf project deploy start --target-org "%ORG_ALIAS%" --source-dir "force-app/main/default/flows" >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%%CHECK% Flows deployed successfully%NC%
) else (
    echo %RED%%CROSS% Flows deployment failed%NC%
    set /a FAILED_COUNT+=1
)
timeout /t 2 /nobreak >nul

REM Step 14: Permission Sets (AFTER Tab - Permission Sets reference the tab!)
echo.
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo STEP 14/14: Permission Sets
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo.
echo %ARROW% %WHITE%Deploying: Permission Sets%NC%
sf project deploy start --target-org "%ORG_ALIAS%" --source-dir "force-app/main/default/permissionsets" >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%%CHECK% Permission Sets deployed successfully%NC%
) else (
    echo %RED%%CROSS% Permission Sets deployment failed%NC%
    set /a FAILED_COUNT+=1
)
timeout /t 2 /nobreak >nul

REM Assign Permission Sets to System Administrators
echo.
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo %GEAR% ASSIGNING PERMISSION SETS
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo.

echo %ARROW% %WHITE%Fetching System Administrator users...%NC%
for /f "tokens=*" %%u in ('sf data query --query "SELECT Username FROM User WHERE Profile.Name='System Administrator' AND IsActive=true" --target-org "%ORG_ALIAS%" --json ^| findstr "Username"') do (
    set ADMIN_FOUND=true
)

if defined ADMIN_FOUND (
    echo %INFO% %CYAN%Automatically assigning permission sets to all System Administrators...%NC%
    echo.
    
    REM Note: Windows batch has limitations with JSON parsing, so we assign to the current user
    echo %ARROW% %WHITE%Assigning permission sets...%NC%
    
    sf org assign permset --name mt_VoiceAssistant_Admin --target-org "%ORG_ALIAS%" >nul 2>&1
    if %errorlevel% equ 0 (
        echo %GREEN%%CHECK% mt_VoiceAssistant_Admin assigned%NC%
    ) else (
        echo %YELLOW%%WARNING% mt_VoiceAssistant_Admin ^(may already be assigned^)%NC%
    )
    
    sf org assign permset --name mt_VoiceAssistant_User --target-org "%ORG_ALIAS%" >nul 2>&1
    if %errorlevel% equ 0 (
        echo %GREEN%%CHECK% mt_VoiceAssistant_User assigned%NC%
    ) else (
        echo %YELLOW%%WARNING% mt_VoiceAssistant_User ^(may already be assigned^)%NC%
    )
    
    echo.
    echo %GREEN%%SUCCESS% Permission set assignment complete!%NC%
) else (
    echo %WARNING% %YELLOW%No System Administrator users found%NC%
)

echo.

REM Deployment Summary
echo.
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo %WHITE%%SUCCESS% DEPLOYMENT COMPLETE%NC%
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo.
echo %WHITE%Target Org:%NC% %CYAN%%ORG_ALIAS%%NC%
echo.

if %FAILED_COUNT% equ 0 (
    echo %GREEN%%SUCCESS% All components deployed successfully!%NC%
) else (
    echo %YELLOW%%WARNING% %FAILED_COUNT% component^(s^) failed to deploy%NC%
)

REM Post-Deployment Instructions
echo.
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo %WHITE%%INFO% POST-DEPLOYMENT SETUP%NC%
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo.
echo %YELLOW%Please complete these manual steps:%NC%
echo.
echo %WHITE%1. Configure Named Credentials:%NC%
echo    %CYAN%• Setup → Named Credentials → mt_EinsteinTranscribe%NC%
echo    %CYAN%• Update URL with your org's My Domain%NC%
echo.
echo %WHITE%2. Enable Einstein AI ^(if not already enabled^):%NC%
echo    %CYAN%• Setup → Einstein → Einstein AI%NC%
echo.
echo %WHITE%3. Access the Setup Page:%NC%
echo    %CYAN%• App Launcher → MT Voice Assistant Settings%NC%
echo    %CYAN%• Follow the guided setup wizard%NC%
echo.
echo %WHITE%4. Test the Installation:%NC%
echo    %CYAN%• Navigate to an Account record%NC%
echo    %CYAN%• Run the MT_Visit_Report_MultiModal flow%NC%
echo.
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo %WHITE%%ROCKET% DEPLOYMENT WIZARD COMPLETE%NC%
echo %CYAN%═══════════════════════════════════════════════════════════════════%NC%
echo.
echo %GREEN%Thank you for using MT Voice Assistant!%NC%
echo %CYAN%For support, contact: mtietze@salesforce.com%NC%
echo.

pause

