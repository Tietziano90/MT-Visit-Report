#!/bin/bash

################################################################################
# 🚀 MT VOICE ASSISTANT - ONE-CLICK DEPLOYMENT
################################################################################
# 
# This script automatically:
# 1. Downloads the latest code from GitHub
# 2. Deploys to your Salesforce org
# 3. Assigns permissions
# 4. Cleans up
#
# Just run: ./deploy-voice-assistant.sh
#
################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Symbols
CHECK="✓"
CROSS="✗"
ROCKET="🚀"
GEAR="⚙️"

TEMP_DIR="/tmp/mt-voice-assistant-$$"
GITHUB_REPO="https://github.com/Tietziano90/MT-Visit-Report.git"

################################################################################
# FUNCTIONS
################################################################################

print_header() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}$1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}${CHECK}${NC} ${WHITE}$1${NC}"
}

print_error() {
    echo -e "${RED}${CROSS}${NC} ${WHITE}$1${NC}"
}

print_step() {
    echo -e "${BLUE}→${NC} ${WHITE}$1${NC}"
}

cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

################################################################################
# MAIN SCRIPT
################################################################################

clear

print_header "${ROCKET} MT VOICE ASSISTANT - ONE-CLICK DEPLOYMENT ${ROCKET}"

echo "This script will:"
echo "  1. Download the latest code from GitHub"
echo "  2. Deploy to your Salesforce org"
echo "  3. Assign permissions automatically"
echo ""

################################################################################
# CHECK PREREQUISITES
################################################################################

print_header "${GEAR} CHECKING PREREQUISITES"

# Check Salesforce CLI
if ! command -v sf &> /dev/null; then
    print_error "Salesforce CLI not found!"
    echo ""
    echo "Please install Salesforce CLI first:"
    echo "  https://developer.salesforce.com/tools/salesforcecli"
    exit 1
fi
print_success "Salesforce CLI detected"

# Check Git
if ! command -v git &> /dev/null; then
    print_error "Git not found!"
    echo ""
    echo "Please install Git first:"
    echo "  https://git-scm.com/downloads"
    exit 1
fi
print_success "Git detected"

################################################################################
# DOWNLOAD LATEST CODE
################################################################################

print_header "📦 DOWNLOADING LATEST CODE FROM GITHUB"

print_step "Cloning repository..."
if git clone "$GITHUB_REPO" "$TEMP_DIR" &> /dev/null; then
    print_success "Latest code downloaded"
else
    print_error "Failed to download code"
    echo ""
    echo "Please check your internet connection and try again."
    exit 1
fi

# Get latest commit info
cd "$TEMP_DIR"
LATEST_COMMIT=$(git log -1 --pretty=format:"%h - %s (%cr)")
echo -e "${CYAN}Latest version:${NC} ${LATEST_COMMIT}"

################################################################################
# RUN DEPLOYMENT
################################################################################

print_header "${ROCKET} STARTING DEPLOYMENT"

echo "The deployment script will now:"
echo "  • Connect to your Salesforce org (browser login)"
echo "  • Deploy all components (~3-5 minutes)"
echo "  • Assign permissions to admins"
echo ""

# Run the deployment script
chmod +x "$TEMP_DIR/deploy.sh"
"$TEMP_DIR/deploy.sh"

DEPLOY_STATUS=$?

################################################################################
# CLEANUP & SUMMARY
################################################################################

print_header "🎉 DEPLOYMENT COMPLETE"

if [ $DEPLOY_STATUS -eq 0 ]; then
    echo -e "${GREEN}✅ MT Voice Assistant deployed successfully!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Configure Named Credentials in Setup"
    echo "  2. Access 'Voice Assistant Setup' from App Launcher"
    echo "  3. Test on an Account record"
    echo ""
    
    # Open the setup page automatically
    echo -e "${CYAN}Opening Voice Assistant Setup page...${NC}"
    
    # Get the org's instance URL
    ORG_URL=$(sf org display --json 2>/dev/null | grep -o '"instanceUrl":"[^"]*"' | cut -d'"' -f4)
    
    if [ ! -z "$ORG_URL" ]; then
        # Open the Lightning page for MT Voice Assistant Admin
        SETUP_URL="${ORG_URL}/lightning/n/MT_Voice_Assistant_Settings"
        
        # Open in default browser
        if command -v open &> /dev/null; then
            # macOS
            open "$SETUP_URL" &> /dev/null
        elif command -v xdg-open &> /dev/null; then
            # Linux
            xdg-open "$SETUP_URL" &> /dev/null
        elif command -v start &> /dev/null; then
            # Windows (Git Bash)
            start "$SETUP_URL" &> /dev/null
        fi
        
        print_success "Setup page opened in your browser"
        echo ""
    fi
else
    echo -e "${YELLOW}⚠️  Deployment completed with warnings${NC}"
    echo ""
    echo "Please review the output above for any issues."
    echo ""
fi

echo "Repository: https://github.com/Tietziano90/MT-Visit-Report"
echo "Support: mtietze@salesforce.com"
echo ""

print_header "✨ THANK YOU FOR USING MT VOICE ASSISTANT ✨"

