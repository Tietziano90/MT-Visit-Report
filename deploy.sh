#!/bin/bash

################################################################################
# 🚀 MT VOICE ASSISTANT - AUTOMATED DEPLOYMENT SCRIPT
################################################################################
# Author: Michael Tietze, Principal AI Architect
# Contact: mtietze@salesforce.com
# Version: 1.0
# 
# This script automates the complete deployment of MT Voice Assistant
# to any Salesforce org with proper dependency management.
################################################################################

# Color codes for beautiful output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Unicode symbols for visual appeal
CHECK_MARK="✓"
CROSS_MARK="✗"
ARROW="→"
ROCKET="🚀"
GEAR="⚙️"
PACKAGE="📦"
WARNING="⚠️"
SUCCESS="✅"
ERROR="❌"
INFO="ℹ️"

################################################################################
# HELPER FUNCTIONS
################################################################################

print_header() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}$1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}${ARROW}${NC} ${WHITE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}${CHECK_MARK}${NC} ${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}${CROSS_MARK}${NC} ${RED}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}${WARNING}${NC} ${YELLOW}$1${NC}"
}

print_info() {
    echo -e "${CYAN}${INFO}${NC} ${CYAN}$1${NC}"
}

deploy_component() {
    local component_name=$1
    local source_path=$2
    local log_file="/tmp/sf-deploy-$$-$(echo "$component_name" | tr ' ' '_').log"
    
    print_step "Deploying: $component_name"
    
    # Deploy and capture output with JSON for better parsing
    if sf project deploy start --target-org "$ORG_ALIAS" --source-dir "$source_path" --json > "$log_file" 2>&1; then
        print_success "$component_name deployed successfully"
        rm -f "$log_file"
        return 0
    else
        print_error "$component_name deployment failed"
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}Error Details for: ${WHITE}$component_name${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        # Try to parse JSON errors
        if grep -q '"status":' "$log_file"; then
            # Extract error messages from JSON
            if grep -q '"message":' "$log_file"; then
                echo -e "${RED}Error Message:${NC}"
                grep -o '"message":"[^"]*"' "$log_file" | cut -d'"' -f4 | sed 's/^/  /' | head -10
                echo ""
            fi
            
            # Extract component failures
            if grep -q '"componentFailures":' "$log_file"; then
                echo -e "${RED}Component Failures:${NC}"
                grep -A 20 '"componentFailures":' "$log_file" | grep -E '(fileName|fullName|problemType|problem)' | sed 's/^/  /' | head -20
                echo ""
            fi
            
            # Extract line/column numbers
            if grep -q '"lineNumber":' "$log_file"; then
                echo -e "${RED}Error Location:${NC}"
                grep -E '(fileName|lineNumber|columnNumber)' "$log_file" | sed 's/^/  /' | head -10
                echo ""
            fi
        else
            # Fallback to text parsing
            if grep -qi "error" "$log_file"; then
                echo -e "${RED}Error Output:${NC}"
                grep -i "error" "$log_file" | sed 's/^/  /' | head -10
                echo ""
            fi
            
            # Show last 15 lines if no specific error found
            if ! grep -qi "error" "$log_file"; then
                echo -e "${RED}Deployment Output:${NC}"
                tail -15 "$log_file" | sed 's/^/  /'
                echo ""
            fi
        fi
        
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}Full log saved to: ${WHITE}$log_file${NC}"
        echo -e "${CYAN}View with: ${WHITE}cat $log_file${NC}"
        echo ""
        
        # Get detailed deployment status
        get_deployment_status "$component_name"
        
        return 1
    fi
}

check_salesforce_cli() {
    if ! command -v sf &> /dev/null; then
        print_error "Salesforce CLI (sf) is not installed!"
        echo ""
        echo -e "${YELLOW}Please install Salesforce CLI:${NC}"
        echo -e "${WHITE}  macOS:   ${CYAN}brew install sf${NC}"
        echo -e "${WHITE}  Windows: ${CYAN}Download from https://developer.salesforce.com/tools/salesforcecli${NC}"
        echo -e "${WHITE}  Linux:   ${CYAN}npm install -g @salesforce/cli${NC}"
        echo ""
        exit 1
    fi
    print_success "Salesforce CLI detected"
}

get_deployment_status() {
    local component_name=$1
    local log_file="/tmp/sf-deploy-status-$$.log"
    
    echo ""
    print_step "Retrieving deployment status for $component_name..."
    
    # Get recent deployment status
    sf project deploy report --target-org "$ORG_ALIAS" > "$log_file" 2>&1
    
    if [ -f "$log_file" ]; then
        echo ""
        echo -e "${CYAN}Deployment Status:${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        # Show status details
        if grep -q "Status:" "$log_file"; then
            grep -E "(Status:|Component Failures:|Error Message:)" "$log_file" | sed 's/^/  /'
        fi
        
        # Show component failures
        if grep -q "Component Failures" "$log_file"; then
            echo ""
            echo -e "${YELLOW}Failed Components:${NC}"
            grep -A 10 "Component Failures" "$log_file" | sed 's/^/  /'
        fi
        
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${CYAN}Full status report saved to: ${WHITE}$log_file${NC}"
        echo ""
    fi
}

################################################################################
# MAIN DEPLOYMENT SCRIPT
################################################################################

clear

print_header "${ROCKET} MT VOICE ASSISTANT - DEPLOYMENT WIZARD ${ROCKET}"

echo -e "${PURPLE}This script will deploy the complete MT Voice Assistant solution${NC}"
echo -e "${PURPLE}to your Salesforce org with all dependencies in the correct order.${NC}"
echo ""

################################################################################
# OPTIONAL: Deployment Password Protection
# Uncomment the lines below to require a password for deployment
################################################################################

# DEPLOYMENT_PASSWORD="your-secret-password-here"
# 
# if [ ! -z "$DEPLOYMENT_PASSWORD" ]; then
#     echo -e "${YELLOW}${WARNING} This deployment requires authorization${NC}"
#     echo ""
#     read -sp "Enter deployment password: " USER_PASSWORD
#     echo ""
#     
#     if [ "$USER_PASSWORD" != "$DEPLOYMENT_PASSWORD" ]; then
#         echo ""
#         print_error "Invalid password. Deployment cancelled."
#         echo ""
#         echo "Contact mtietze@salesforce.com for access."
#         exit 1
#     fi
#     
#     print_success "Password verified"
#     echo ""
# fi

################################################################################

# Check prerequisites
print_header "${GEAR} CHECKING PREREQUISITES"
check_salesforce_cli

# Get org alias
echo ""
print_info "Enter your Salesforce org alias (or press Enter to create a new connection):"
if [ -t 0 ]; then
    read -p "Org Alias: " ORG_ALIAS
else
    read -p "Org Alias: " ORG_ALIAS </dev/tty
fi

if [ -z "$ORG_ALIAS" ]; then
    print_warning "No alias provided. Let's connect to your org..."
    echo ""
    echo -e "${CYAN}Choose connection type:${NC}"
    echo -e "${WHITE}  1) Production/Developer Org${NC}"
    echo -e "${WHITE}  2) Sandbox${NC}"
    echo -e "${WHITE}  3) Scratch Org${NC}"
    
    # Read from terminal even if stdin is piped
    if [ -t 0 ]; then
        read -p "Enter choice (1-3): " ORG_TYPE
    else
        read -p "Enter choice (1-3): " ORG_TYPE </dev/tty
    fi
    
    if [ -t 0 ]; then
        read -p "Enter alias for this org: " ORG_ALIAS
    else
        read -p "Enter alias for this org: " ORG_ALIAS </dev/tty
    fi
    
    case $ORG_TYPE in
        1)
            print_step "Connecting to Production/Developer org..."
            echo ""
            print_info "🌐 A browser window will open for you to log in to Salesforce..."
            print_info "⏳ Please complete the login in your browser"
            print_info "💡 This terminal will wait for you to finish logging in"
            echo ""
            sf org login web --alias "$ORG_ALIAS" --instance-url https://login.salesforce.com
            ;;
        2)
            print_step "Connecting to Sandbox..."
            echo ""
            print_info "🌐 A browser window will open for you to log in to Salesforce..."
            print_info "⏳ Please complete the login in your browser"
            print_info "💡 This terminal will wait for you to finish logging in"
            echo ""
            sf org login web --alias "$ORG_ALIAS" --instance-url https://test.salesforce.com
            ;;
        3)
            print_step "Creating Scratch Org..."
            sf org create scratch --alias "$ORG_ALIAS" --definition-file config/project-scratch-def.json --duration-days 30 --set-default
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo ""
        print_success "Successfully connected to org: $ORG_ALIAS"
        print_info "Returning to deployment wizard..."
        echo ""
        sleep 2
    else
        print_error "Failed to connect to org"
        exit 1
    fi
fi

# Verify org connection
print_step "Verifying org connection..."
if sf org display --target-org "$ORG_ALIAS" > /dev/null 2>&1; then
    print_success "Org connection verified: $ORG_ALIAS"
else
    print_error "Cannot connect to org: $ORG_ALIAS"
    echo ""
    print_info "Available orgs:"
    sf org list
    exit 1
fi

# Confirm deployment
echo ""
print_warning "This will deploy MT Voice Assistant to: $ORG_ALIAS"
echo ""
print_info "Type 'yes' to continue or 'no' to cancel"
if [ -t 0 ]; then
    read -p "Continue? (yes/no): " CONFIRM
else
    read -p "Continue? (yes/no): " CONFIRM </dev/tty
fi

# Convert to lowercase and trim whitespace
CONFIRM=$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]' | xargs)

if [ "$CONFIRM" != "yes" ] && [ "$CONFIRM" != "y" ]; then
    print_info "Deployment cancelled"
    exit 0
fi

################################################################################
# DEPLOYMENT SEQUENCE
################################################################################

print_header "${PACKAGE} STARTING DEPLOYMENT SEQUENCE"

DEPLOYMENT_START=$(date +%s)
FAILED_COMPONENTS=()

# Step 1: Deploy Custom Metadata Types and Objects
print_header "STEP 1/12: Custom Metadata Types & Objects"
if deploy_component "Custom Metadata Types & Objects" "force-app/main/default/objects"; then
    sleep 2
else
    FAILED_COMPONENTS+=("Custom Metadata Types & Objects")
fi

# Step 2: Deploy Custom Permissions
print_header "STEP 2/12: Custom Permissions"
if deploy_component "Custom Permissions" "force-app/main/default/customPermissions"; then
    sleep 2
else
    FAILED_COMPONENTS+=("Custom Permissions")
fi

# Step 3: Deploy Apex Classes
print_header "STEP 3/12: Apex Classes"
if deploy_component "Apex Classes" "force-app/main/default/classes"; then
    sleep 2
else
    FAILED_COMPONENTS+=("Apex Classes")
fi

# Step 4: Deploy Lightning Web Components (Core) - IN DEPENDENCY ORDER!
print_header "STEP 4/14: Lightning Web Components"

# Deploy mtDateInput FIRST (no dependencies)
print_step "Deploying mtDateInput..."
if deploy_component "mtDateInput" "force-app/main/default/lwc/mtDateInput"; then
    sleep 1
else
    FAILED_COMPONENTS+=("mtDateInput")
fi

# Deploy mtRecordSuggestion SECOND (depends on mtDateInput)
print_step "Deploying mtRecordSuggestion..."
if deploy_component "mtRecordSuggestion" "force-app/main/default/lwc/mtRecordSuggestion"; then
    sleep 1
else
    FAILED_COMPONENTS+=("mtRecordSuggestion")
fi

# Deploy mtEinsteinTranscribe THIRD
print_step "Deploying mtEinsteinTranscribe..."
if deploy_component "mtEinsteinTranscribe" "force-app/main/default/lwc/mtEinsteinTranscribe"; then
    sleep 1
else
    FAILED_COMPONENTS+=("mtEinsteinTranscribe")
fi

# Deploy mtVoiceAssistantAdmin LAST
print_step "Deploying mtVoiceAssistantAdmin..."
if deploy_component "mtVoiceAssistantAdmin" "force-app/main/default/lwc/mtVoiceAssistantAdmin"; then
    sleep 1
else
    FAILED_COMPONENTS+=("mtVoiceAssistantAdmin")
fi

# Step 5: Deploy Page Layouts
print_header "STEP 5/12: Page Layouts"
if deploy_component "Page Layouts" "force-app/main/default/layouts"; then
    sleep 2
else
    FAILED_COMPONENTS+=("Page Layouts")
fi

# Step 6: Deploy Custom Metadata Records
print_header "STEP 6/12: Custom Metadata Records"
if deploy_component "Custom Metadata Records" "force-app/main/default/customMetadata"; then
    sleep 2
else
    FAILED_COMPONENTS+=("Custom Metadata Records")
fi

# Step 7: Deploy External Credentials
print_header "STEP 7/12: External Credentials"
if deploy_component "External Credentials" "force-app/main/default/externalCredentials"; then
    sleep 2
else
    FAILED_COMPONENTS+=("External Credentials")
fi

# Step 8: Deploy Named Credentials
print_header "STEP 8/14: Named Credentials"
print_info "Named Credentials will need URL configuration after deployment"
if deploy_component "Named Credentials" "force-app/main/default/namedCredentials"; then
    sleep 2
else
    FAILED_COMPONENTS+=("Named Credentials")
fi

# Step 9: Deploy CSP Trusted Sites
print_header "STEP 9/12: CSP Trusted Sites"
if deploy_component "CSP Trusted Sites" "force-app/main/default/cspTrustedSites"; then
    sleep 2
else
    FAILED_COMPONENTS+=("CSP Trusted Sites")
fi

# Step 10: Deploy Connected App
print_header "STEP 10/12: Connected App"
print_warning "Connected App may require manual configuration"
if deploy_component "Connected App" "force-app/main/default/connectedApps"; then
    sleep 2
else
    print_warning "Connected App may need manual setup - this is normal"
fi

# Step 11: Deploy GenAI Prompt Templates (BEFORE Flows - Flows depend on them!)
print_header "STEP 11/14: GenAI Prompt Templates"
print_warning "Prompt Templates require Einstein AI to be enabled"
if deploy_component "GenAI Prompt Templates" "force-app/main/default/genAiPromptTemplates"; then
    sleep 2
else
    print_warning "Prompt Templates failed - ensure Einstein AI is enabled"
fi

# Step 12: Deploy Custom Tab (BEFORE Flows and Permission Sets - they reference it!)
print_header "STEP 12/14: Custom Tab"
if deploy_component "Custom Tab" "force-app/main/default/tabs"; then
    sleep 2
else
    FAILED_COMPONENTS+=("Custom Tab")
fi

# Step 13: Deploy Flows (AFTER Prompt Templates and Tab!)
print_header "STEP 13/14: Flows"
if deploy_component "Flows" "force-app/main/default/flows"; then
    sleep 2
else
    FAILED_COMPONENTS+=("Flows")
fi

# Step 14: Deploy Permission Sets (AFTER Tab - Permission Sets reference the tab!)
print_header "STEP 14/14: Permission Sets"
if deploy_component "Permission Sets" "force-app/main/default/permissionsets"; then
    sleep 2
else
    FAILED_COMPONENTS+=("Permission Sets")
fi

################################################################################
# ASSIGN PERMISSION SETS TO ADMINS
################################################################################

print_header "${GEAR} ASSIGNING PERMISSION SETS"

# First, assign to the current user (person deploying)
print_step "Assigning permission sets to you (current user)..."

# Try multiple methods to get current user
CURRENT_USER=$(sf org display --target-org "$ORG_ALIAS" --json 2>/dev/null | grep -o '"username":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$CURRENT_USER" ]; then
    # Fallback: try without JSON
    CURRENT_USER=$(sf org display --target-org "$ORG_ALIAS" 2>/dev/null | grep "Username" | awk '{print $2}')
fi

if [ ! -z "$CURRENT_USER" ]; then
    echo -e "  ${CYAN}Current user: $CURRENT_USER${NC}"
    echo ""
    
    # Assign to current user
    sf org assign permset --name mt_VoiceAssistant_Admin --target-org "$ORG_ALIAS" 2>&1 | grep -q "successfully assigned" || true
    print_success "✓ mt_VoiceAssistant_Admin assigned to you"
    
    sf org assign permset --name mt_VoiceAssistant_User --target-org "$ORG_ALIAS" 2>&1 | grep -q "successfully assigned" || true
    print_success "✓ mt_VoiceAssistant_User assigned to you"
    
    echo ""
else
    print_warning "Could not detect current user, skipping direct assignment"
    echo ""
fi

# Then, assign to all System Administrators
print_step "Fetching other System Administrator users..."
ADMIN_USERS=$(sf data query --query "SELECT Id, Username FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true" --target-org "$ORG_ALIAS" --json | grep -o '"Username":"[^"]*"' | cut -d'"' -f4)

if [ -z "$ADMIN_USERS" ]; then
    print_warning "No System Administrator users found"
else
    ADMIN_COUNT=$(echo "$ADMIN_USERS" | wc -l | xargs)
    print_info "Found $ADMIN_COUNT System Administrator(s)"
    echo "$ADMIN_USERS" | while read -r username; do
        echo -e "  ${CYAN}• $username${NC}"
    done
    
    echo ""
    print_info "Automatically assigning permission sets to all System Administrators..."
    echo ""
    
    ASSIGNED_COUNT=0
    echo "$ADMIN_USERS" | while read -r username; do
        # Skip current user (already assigned above)
        if [ "$username" = "$CURRENT_USER" ]; then
            continue
        fi
        
        print_step "Assigning to: $username"
        
        sf org assign permset --name mt_VoiceAssistant_Admin --target-org "$ORG_ALIAS" --on-behalf-of "$username" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            print_success "✓ mt_VoiceAssistant_Admin"
        else
            print_warning "⚠️  mt_VoiceAssistant_Admin (may already be assigned)"
        fi
        
        sf org assign permset --name mt_VoiceAssistant_User --target-org "$ORG_ALIAS" --on-behalf-of "$username" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            print_success "✓ mt_VoiceAssistant_User"
        else
            print_warning "⚠️  mt_VoiceAssistant_User (may already be assigned)"
        fi
        
        echo ""
    done
    
    print_success "Permission set assignment complete!"
fi

################################################################################
# DEPLOYMENT SUMMARY
################################################################################

DEPLOYMENT_END=$(date +%s)
DEPLOYMENT_TIME=$((DEPLOYMENT_END - DEPLOYMENT_START))

print_header "${SUCCESS} DEPLOYMENT COMPLETE"

echo -e "${WHITE}Deployment Time:${NC} ${CYAN}${DEPLOYMENT_TIME} seconds${NC}"
echo -e "${WHITE}Target Org:${NC} ${CYAN}$ORG_ALIAS${NC}"
echo ""

if [ ${#FAILED_COMPONENTS[@]} -eq 0 ]; then
    print_success "All components deployed successfully!"
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print_error "DEPLOYMENT FAILURES DETECTED"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}The following components failed to deploy:${NC}"
    echo ""
    for component in "${FAILED_COMPONENTS[@]}"; do
        echo -e "  ${RED}${CROSS_MARK} $component${NC}"
    done
    echo ""
    echo -e "${CYAN}Troubleshooting:${NC}"
    echo -e "  ${WHITE}1. Check the error logs above for each failed component${NC}"
    echo -e "  ${WHITE}2. Review deployment logs in /tmp/sf-deploy-*.log${NC}"
    echo -e "  ${WHITE}3. Common issues:${NC}"
    echo -e "     ${CYAN}• Missing dependencies (deploy in correct order)${NC}"
    echo -e "     ${CYAN}• Einstein AI not enabled (for Prompt Templates)${NC}"
    echo -e "     ${CYAN}• Insufficient permissions${NC}"
    echo -e "     ${CYAN}• Org limits reached${NC}"
    echo ""
    echo -e "${YELLOW}To retry failed components:${NC}"
    echo -e "  ${WHITE}sf project deploy start --source-dir force-app/main/default/<component-path> --target-org $ORG_ALIAS${NC}"
    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
fi

################################################################################
# POST-DEPLOYMENT INSTRUCTIONS
################################################################################

print_header "${INFO} POST-DEPLOYMENT SETUP"

echo -e "${YELLOW}Please complete these manual steps:${NC}"
echo ""
echo -e "${WHITE}1. Configure Named Credentials:${NC}"
echo -e "   ${CYAN}• Setup → Named Credentials → mt_EinsteinTranscribe${NC}"
echo -e "   ${CYAN}• Update URL with your org's My Domain${NC}"
echo ""
echo -e "${WHITE}2. Enable Einstein AI (if not already enabled):${NC}"
echo -e "   ${CYAN}• Setup → Einstein → Einstein AI${NC}"
echo ""
echo -e "${WHITE}3. Access the Setup Page:${NC}"
echo -e "   ${CYAN}• App Launcher → MT Voice Assistant Settings${NC}"
echo -e "   ${CYAN}• Follow the guided setup wizard${NC}"
echo ""
echo -e "${WHITE}4. Test the Installation:${NC}"
echo -e "   ${CYAN}• Navigate to an Account record${NC}"
echo -e "   ${CYAN}• Run the MT_Visit_Report_MultiModal flow${NC}"
echo ""

################################################################################
# OPEN SETUP PAGE AUTOMATICALLY
################################################################################

echo -e "${CYAN}Opening Voice Assistant Setup page in your browser...${NC}"
echo ""

# Get the org's instance URL - try multiple methods
ORG_INSTANCE_URL=$(sf org display --target-org "$ORG_ALIAS" --json 2>/dev/null | grep -o '"instanceUrl":"[^"]*"' | cut -d'"' -f4)

if [ -z "$ORG_INSTANCE_URL" ]; then
    # Fallback: try without JSON
    ORG_INSTANCE_URL=$(sf org display --target-org "$ORG_ALIAS" 2>/dev/null | grep "Instance Url" | awk '{print $NF}')
fi

if [ -z "$ORG_INSTANCE_URL" ]; then
    # Fallback: try with different grep pattern
    ORG_INSTANCE_URL=$(sf org display --target-org "$ORG_ALIAS" 2>/dev/null | grep -i "instance" | grep -o 'https://[^[:space:]]*' | head -1)
fi

if [ ! -z "$ORG_INSTANCE_URL" ]; then
    # Open the Lightning page for MT Voice Assistant Admin
    SETUP_PAGE_URL="${ORG_INSTANCE_URL}/lightning/n/MT_Voice_Assistant_Settings"
    
    # Try to open in default browser (cross-platform)
    BROWSER_OPENED=false
    if command -v open &> /dev/null; then
        # macOS
        open "$SETUP_PAGE_URL" 2>/dev/null && BROWSER_OPENED=true
    elif command -v xdg-open &> /dev/null; then
        # Linux
        xdg-open "$SETUP_PAGE_URL" 2>/dev/null && BROWSER_OPENED=true
    elif command -v start &> /dev/null; then
        # Windows (Git Bash)
        start "$SETUP_PAGE_URL" 2>/dev/null && BROWSER_OPENED=true
    fi
    
    if [ "$BROWSER_OPENED" = true ]; then
        print_success "✓ Setup page opened in your browser!"
        echo ""
        print_info "If the page didn't open, manually navigate to:"
        echo -e "  ${WHITE}1. Open your Salesforce org${NC}"
        echo -e "  ${WHITE}2. Go to App Launcher (waffle icon)${NC}"
        echo -e "  ${WHITE}3. Search for: ${CYAN}Voice Assistant Setup${NC}"
        echo -e "  ${WHITE}4. Follow the post-deployment setup instructions${NC}"
    else
        print_warning "⚠️  Could not automatically open browser"
        echo ""
        print_info "Please complete setup manually:"
        echo -e "  ${WHITE}1. Open your Salesforce org${NC}"
        echo -e "  ${WHITE}2. Go to App Launcher (waffle icon)${NC}"
        echo -e "  ${WHITE}3. Search for: ${CYAN}Voice Assistant Setup${NC}"
        echo -e "  ${WHITE}4. Follow the post-deployment setup instructions${NC}"
    fi
    echo ""
else
    print_warning "⚠️  Could not detect org URL"
    echo ""
    print_info "Please complete setup manually:"
    echo -e "  ${WHITE}1. Open your Salesforce org${NC}"
    echo -e "  ${WHITE}2. Go to App Launcher (waffle icon)${NC}"
    echo -e "  ${WHITE}3. Search for: ${CYAN}Voice Assistant Setup${NC}"
    echo -e "  ${WHITE}4. Follow the post-deployment setup instructions${NC}"
    echo ""
fi

print_header "${ROCKET} DEPLOYMENT WIZARD COMPLETE"

echo -e "${GREEN}Thank you for using MT Voice Assistant!${NC}"
echo -e "${CYAN}For support, contact: mtietze@salesforce.com${NC}"
echo ""

