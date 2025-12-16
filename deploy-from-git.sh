#!/bin/bash

################################################################################
# 🚀 MT VOICE ASSISTANT - GIT-BASED DEPLOYMENT SCRIPT
################################################################################
# Author: Michael Tietze, Principal AI Architect
# Contact: mtietze@salesforce.com
# Version: 2.0
# 
# This script automatically pulls the latest code from Git and deploys it
# to your Salesforce org. No manual download required!
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

# Git repository URL
GIT_REPO="https://github.com/Tietziano90/MT-Visit-Report.git"
TEMP_DIR="/tmp/voice-assistant-deploy-$$"

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
    echo -e "${GREEN}${CHECK_MARK}${NC} ${WHITE}$1${NC}"
}

print_error() {
    echo -e "${RED}${CROSS_MARK}${NC} ${WHITE}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}${WARNING}${NC} ${WHITE}$1${NC}"
}

print_info() {
    echo -e "${CYAN}${INFO}${NC} ${WHITE}$1${NC}"
}

cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        print_step "Cleaning up temporary files..."
        rm -rf "$TEMP_DIR"
        print_success "Cleanup complete"
    fi
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

################################################################################
# MAIN SCRIPT
################################################################################

clear

print_header "${ROCKET} MT VOICE ASSISTANT - GIT DEPLOYMENT WIZARD ${ROCKET}"

echo "This script will:"
echo "  1. ${SUCCESS} Pull the latest code from Git (no authentication required)"
echo "  2. ${SUCCESS} Connect to your Salesforce org"
echo "  3. ${SUCCESS} Deploy all components in the correct order"
echo "  4. ${SUCCESS} Assign permission sets to admins"
echo ""

################################################################################
# STEP 1: CHECK PREREQUISITES
################################################################################

print_header "${GEAR} CHECKING PREREQUISITES"

# Check for Salesforce CLI
if ! command -v sf &> /dev/null; then
    print_error "Salesforce CLI not found!"
    echo ""
    echo "Please install Salesforce CLI first:"
    echo "  https://developer.salesforce.com/tools/salesforcecli"
    exit 1
fi

print_success "Salesforce CLI detected"

# Check for Git
if ! command -v git &> /dev/null; then
    print_error "Git not found!"
    echo ""
    echo "Please install Git first:"
    echo "  https://git-scm.com/downloads"
    exit 1
fi

print_success "Git detected"

################################################################################
# STEP 2: PULL LATEST CODE FROM GIT
################################################################################

print_header "${PACKAGE} PULLING LATEST CODE FROM GIT"

print_step "Repository: ${GIT_REPO}"
print_step "Cloning to temporary directory..."

# Clone the repository (public read access, no auth needed)
if git clone "$GIT_REPO" "$TEMP_DIR" 2>&1 | grep -v "Cloning into"; then
    print_success "Successfully pulled latest code from Git"
else
    print_error "Failed to clone repository"
    print_info "Note: If the repository is private, you may need to authenticate."
    print_info "Run: git config --global credential.helper store"
    print_info "Then try again."
    exit 1
fi

# Change to the cloned directory
cd "$TEMP_DIR" || exit 1

# Get the latest commit info
LATEST_COMMIT=$(git log -1 --pretty=format:"%h - %s (%cr)")
print_info "Latest commit: ${LATEST_COMMIT}"

################################################################################
# STEP 3: CONNECT TO SALESFORCE ORG
################################################################################

print_header "${GEAR} CONNECTING TO SALESFORCE ORG"

print_info "Enter your Salesforce org alias (or press Enter to create a new connection):"
read -r ORG_ALIAS

if [ -z "$ORG_ALIAS" ]; then
    print_warning "No alias provided. Let's connect to your org..."
    echo ""
    echo "Choose connection type:"
    echo "  1) Production/Developer Org"
    echo "  2) Sandbox"
    echo "  3) Scratch Org"
    read -p "Enter choice (1-3): " ORG_TYPE
    
    read -p "Enter alias for this org: " ORG_ALIAS
    
    case $ORG_TYPE in
        1)
            print_step "Connecting to Production/Developer org..."
            LOGIN_URL="https://login.salesforce.com"
            ;;
        2)
            print_step "Connecting to Sandbox..."
            LOGIN_URL="https://test.salesforce.com"
            ;;
        3)
            print_step "Creating Scratch Org..."
            sf org create scratch --definition-file config/project-scratch-def.json --alias "$ORG_ALIAS" --set-default
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
    
    if [ "$ORG_TYPE" != "3" ]; then
        print_info "${INFO} 🌐 A browser window will open for you to log in to Salesforce..."
        print_info "${INFO} ⏳ Please complete the login in your browser"
        print_info "${INFO} 💡 This terminal will wait for you to finish logging in"
        echo ""
        
        sf org login web --alias "$ORG_ALIAS" --instance-url "$LOGIN_URL" --set-default
        
        if [ $? -eq 0 ]; then
            print_success "Successfully connected to org: $ORG_ALIAS"
            print_info "Returning to deployment wizard..."
        else
            print_error "Failed to connect to org"
            exit 1
        fi
    fi
else
    print_step "Verifying org connection..."
    if sf org display --target-org "$ORG_ALIAS" &> /dev/null; then
        print_success "Org connection verified: $ORG_ALIAS"
    else
        print_error "Could not connect to org: $ORG_ALIAS"
        print_info "Please check the alias and try again"
        exit 1
    fi
fi

echo ""
print_warning "This will deploy MT Voice Assistant to: $ORG_ALIAS"
echo ""
print_info "Type 'yes' to continue or 'no' to cancel"
read -r CONFIRM

# Convert to lowercase and accept 'yes' or 'y'
CONFIRM_LOWER=$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')
if [[ "$CONFIRM_LOWER" != "yes" && "$CONFIRM_LOWER" != "y" ]]; then
    print_warning "Deployment cancelled"
    exit 0
fi

################################################################################
# STEP 4: DEPLOY COMPONENTS
################################################################################

print_header "${PACKAGE} STARTING DEPLOYMENT SEQUENCE"

# Track deployment status
FAILED_COMPONENTS=()
START_TIME=$(date +%s)

# Function to deploy a component
deploy_component() {
    local COMPONENT_NAME=$1
    local COMPONENT_PATH=$2
    local STEP_NUM=$3
    local TOTAL_STEPS=$4
    
    echo ""
    print_header "STEP $STEP_NUM/$TOTAL_STEPS: $COMPONENT_NAME"
    echo ""
    
    print_step "Deploying: $COMPONENT_NAME"
    
    if sf project deploy start --target-org "$ORG_ALIAS" --source-dir "$COMPONENT_PATH" &> /dev/null; then
        print_success "$COMPONENT_NAME deployed successfully"
        return 0
    else
        print_error "$COMPONENT_NAME deployment failed"
        FAILED_COMPONENTS+=("$COMPONENT_NAME")
        return 1
    fi
}

# Deploy in dependency order
STEP=1
TOTAL=14

deploy_component "Custom Metadata Types & Objects" "force-app/main/default/objects" $STEP $TOTAL
((STEP++))

deploy_component "Custom Permissions" "force-app/main/default/customPermissions" $STEP $TOTAL
((STEP++))

deploy_component "Apex Classes" "force-app/main/default/classes" $STEP $TOTAL
((STEP++))

print_header "STEP $STEP/$TOTAL: Lightning Web Components"
echo ""
print_step "Deploying mtDateInput..."
deploy_component "mtDateInput" "force-app/main/default/lwc/mtDateInput" $STEP $TOTAL
print_step "Deploying mtRecordSuggestion..."
deploy_component "mtRecordSuggestion" "force-app/main/default/lwc/mtRecordSuggestion" $STEP $TOTAL
print_step "Deploying mtEinsteinTranscribe..."
deploy_component "mtEinsteinTranscribe" "force-app/main/default/lwc/mtEinsteinTranscribe" $STEP $TOTAL
print_step "Deploying mtVoiceAssistantAdmin..."
deploy_component "mtVoiceAssistantAdmin" "force-app/main/default/lwc/mtVoiceAssistantAdmin" $STEP $TOTAL
((STEP++))

deploy_component "Page Layouts" "force-app/main/default/layouts" $STEP $TOTAL
((STEP++))

deploy_component "Custom Metadata Records" "force-app/main/default/customMetadata" $STEP $TOTAL
((STEP++))

deploy_component "External Credentials" "force-app/main/default/externalCredentials" $STEP $TOTAL
((STEP++))

print_header "STEP $STEP/$TOTAL: Named Credentials"
echo ""
print_warning "Named Credentials require manual configuration after deployment"
deploy_component "Named Credentials" "force-app/main/default/namedCredentials" $STEP $TOTAL
if [ $? -ne 0 ]; then
    print_warning "Named Credentials may need manual setup - this is normal"
fi
((STEP++))

deploy_component "CSP Trusted Sites" "force-app/main/default/cspTrustedSites" $STEP $TOTAL
((STEP++))

print_header "STEP $STEP/$TOTAL: Connected App"
echo ""
print_warning "Connected App may require manual configuration"
deploy_component "Connected App" "force-app/main/default/connectedApps" $STEP $TOTAL
((STEP++))

print_header "STEP $STEP/$TOTAL: GenAI Prompt Templates"
echo ""
print_warning "Prompt Templates require Einstein AI to be enabled"
deploy_component "GenAI Prompt Templates" "force-app/main/default/genAiPromptTemplates" $STEP $TOTAL
((STEP++))

deploy_component "Flows" "force-app/main/default/flows" $STEP $TOTAL
((STEP++))

deploy_component "Permission Sets" "force-app/main/default/permissionsets" $STEP $TOTAL
((STEP++))

deploy_component "Custom Tab" "force-app/main/default/tabs" $STEP $TOTAL

################################################################################
# STEP 5: ASSIGN PERMISSION SETS
################################################################################

print_header "${GEAR} ASSIGNING PERMISSION SETS"

print_step "Fetching admin users..."
ADMIN_USERS=$(sf data query --query "SELECT Id, Username FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true" --target-org "$ORG_ALIAS" --json | grep -o '"Username":"[^"]*"' | cut -d'"' -f4)

if [ -z "$ADMIN_USERS" ]; then
    print_warning "No admin users found"
else
    print_info "Assigning permission sets to all System Administrators..."
    
    while IFS= read -r username; do
        print_step "Assigning to: $username"
        sf org assign permset --name mt_VoiceAssistant_Admin --target-org "$ORG_ALIAS" --on-behalf-of "$username" &> /dev/null
        sf org assign permset --name mt_VoiceAssistant_User --target-org "$ORG_ALIAS" --on-behalf-of "$username" &> /dev/null
    done <<< "$ADMIN_USERS"
    
    print_success "Permission sets assigned to all System Administrators"
fi

################################################################################
# DEPLOYMENT SUMMARY
################################################################################

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

print_header "${SUCCESS} DEPLOYMENT COMPLETE"

echo "Deployment Time: $DURATION seconds"
echo "Target Org: $ORG_ALIAS"
echo "Source: Git (latest commit)"
echo ""

if [ ${#FAILED_COMPONENTS[@]} -gt 0 ]; then
    print_warning "Some components failed to deploy:"
    for component in "${FAILED_COMPONENTS[@]}"; do
        echo "  ${CROSS_MARK} $component"
    done
    echo ""
fi

print_header "${INFO} POST-DEPLOYMENT SETUP"

echo "Please complete these manual steps:"
echo ""
echo "1. Configure Named Credentials:"
echo "   • Setup → Named Credentials → mt_EinsteinTranscribe"
echo "   • Update URL with your org's My Domain"
echo ""
echo "2. Enable Einstein AI (if not already enabled):"
echo "   • Setup → Einstein → Einstein AI"
echo ""
echo "3. Access the Setup Page:"
echo "   • App Launcher → Voice Assistant Setup"
echo "   • Follow the guided setup wizard"
echo ""
echo "4. Test the Installation:"
echo "   • Navigate to an Account record"
echo "   • Run the MT_Visit_Report_MultiModal flow"
echo ""

print_header "${ROCKET} DEPLOYMENT WIZARD COMPLETE"

echo "Thank you for using MT Voice Assistant!"
echo "For support, contact: mtietze@salesforce.com"
echo ""

