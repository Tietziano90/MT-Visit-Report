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

################################################################################
# CHECK PREREQUISITES
################################################################################

# Check Salesforce CLI
if ! command -v sf &> /dev/null; then
    print_error "Salesforce CLI not found!"
    echo ""
    echo -e "${YELLOW}The Salesforce CLI is required to deploy this app.${NC}"
    echo ""
    echo "Would you like to install it now?"
    echo ""
    echo -e "${CYAN}Installation options:${NC}"
    echo ""
    echo -e "${WHITE}macOS:${NC}"
    echo "  brew install sf"
    echo ""
    echo -e "${WHITE}Windows:${NC}"
    echo "  Download installer from:"
    echo "  https://developer.salesforce.com/tools/salesforcecli"
    echo ""
    echo -e "${WHITE}Linux:${NC}"
    echo "  npm install -g @salesforce/cli"
    echo "  OR download from:"
    echo "  https://developer.salesforce.com/tools/salesforcecli"
    echo ""
    echo -e "${CYAN}Quick install (macOS/Linux with npm):${NC}"
    echo "  npm install -g @salesforce/cli"
    echo ""
    
    # Detect OS and offer auto-install
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            echo -e "${GREEN}✓ Homebrew detected!${NC}"
            echo ""
            if [ -t 0 ]; then
                read -p "Install Salesforce CLI via Homebrew now? (yes/no): " INSTALL_CLI
            else
                read -p "Install Salesforce CLI via Homebrew now? (yes/no): " INSTALL_CLI </dev/tty
            fi
            
            INSTALL_CLI=$(echo "$INSTALL_CLI" | tr '[:upper:]' '[:lower:]' | xargs)
            
            if [ "$INSTALL_CLI" = "yes" ] || [ "$INSTALL_CLI" = "y" ]; then
                echo ""
                print_step "Installing Salesforce CLI..."
                brew install sf
                
                if command -v sf &> /dev/null; then
                    print_success "Salesforce CLI installed successfully!"
                    echo ""
                else
                    print_error "Installation failed. Please install manually."
                    exit 1
                fi
            else
                echo ""
                echo "Please install Salesforce CLI and run this script again."
                exit 1
            fi
        else
            echo -e "${YELLOW}Homebrew not found. Install Homebrew first:${NC}"
            echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            echo ""
            echo "Then run: brew install sf"
            exit 1
        fi
    elif command -v npm &> /dev/null; then
        # Has npm (Linux/Windows)
        echo -e "${GREEN}✓ npm detected!${NC}"
        echo ""
        if [ -t 0 ]; then
            read -p "Install Salesforce CLI via npm now? (may require sudo) (yes/no): " INSTALL_CLI
        else
            read -p "Install Salesforce CLI via npm now? (may require sudo) (yes/no): " INSTALL_CLI </dev/tty
        fi
        
        INSTALL_CLI=$(echo "$INSTALL_CLI" | tr '[:upper:]' '[:lower:]' | xargs)
        
        if [ "$INSTALL_CLI" = "yes" ] || [ "$INSTALL_CLI" = "y" ]; then
            echo ""
            print_step "Installing Salesforce CLI..."
            
            # Try without sudo first
            if npm install -g @salesforce/cli 2>/dev/null; then
                print_success "Salesforce CLI installed successfully!"
                echo ""
            else
                # Try with sudo if first attempt failed
                print_step "Trying with sudo..."
                sudo npm install -g @salesforce/cli
                
                if command -v sf &> /dev/null; then
                    print_success "Salesforce CLI installed successfully!"
                    echo ""
                else
                    print_error "Installation failed. Please install manually."
                    exit 1
                fi
            fi
        else
            echo ""
            echo "Please install Salesforce CLI and run this script again."
            exit 1
        fi
    else
        echo ""
        echo "Please install Salesforce CLI manually and run this script again."
        exit 1
    fi
fi
print_success "Salesforce CLI detected"

# Check Git
if ! command -v git &> /dev/null; then
    print_error "Git not found!"
    echo ""
    echo -e "${YELLOW}Git is required to download the deployment code.${NC}"
    echo ""
    echo -e "${CYAN}Installation options:${NC}"
    echo ""
    echo -e "${WHITE}macOS:${NC}"
    echo "  brew install git"
    echo "  OR install Xcode Command Line Tools:"
    echo "  xcode-select --install"
    echo ""
    echo -e "${WHITE}Windows:${NC}"
    echo "  Download installer from:"
    echo "  https://git-scm.com/downloads"
    echo ""
    echo -e "${WHITE}Linux:${NC}"
    echo "  sudo apt-get install git  (Ubuntu/Debian)"
    echo "  sudo yum install git       (CentOS/RHEL)"
    echo ""
    
    # Detect OS and offer auto-install
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            echo -e "${GREEN}✓ Homebrew detected!${NC}"
            echo ""
            if [ -t 0 ]; then
                read -p "Install Git via Homebrew now? (yes/no): " INSTALL_GIT
            else
                read -p "Install Git via Homebrew now? (yes/no): " INSTALL_GIT </dev/tty
            fi
            
            INSTALL_GIT=$(echo "$INSTALL_GIT" | tr '[:upper:]' '[:lower:]' | xargs)
            
            if [ "$INSTALL_GIT" = "yes" ] || [ "$INSTALL_GIT" = "y" ]; then
                echo ""
                print_step "Installing Git..."
                brew install git
                
                if command -v git &> /dev/null; then
                    print_success "Git installed successfully!"
                    echo ""
                else
                    print_error "Installation failed. Please install manually."
                    exit 1
                fi
            else
                echo ""
                echo "Please install Git and run this script again."
                exit 1
            fi
        else
            echo ""
            echo "Please install Git manually and run this script again."
            exit 1
        fi
    elif command -v apt-get &> /dev/null; then
        # Ubuntu/Debian
        echo -e "${GREEN}✓ apt-get detected!${NC}"
        echo ""
        if [ -t 0 ]; then
            read -p "Install Git via apt-get now? (requires sudo) (yes/no): " INSTALL_GIT
        else
            read -p "Install Git via apt-get now? (requires sudo) (yes/no): " INSTALL_GIT </dev/tty
        fi
        
        INSTALL_GIT=$(echo "$INSTALL_GIT" | tr '[:upper:]' '[:lower:]' | xargs)
        
        if [ "$INSTALL_GIT" = "yes" ] || [ "$INSTALL_GIT" = "y" ]; then
            echo ""
            print_step "Installing Git..."
            sudo apt-get update && sudo apt-get install -y git
            
            if command -v git &> /dev/null; then
                print_success "Git installed successfully!"
                echo ""
            else
                print_error "Installation failed. Please install manually."
                exit 1
            fi
        else
            echo ""
            echo "Please install Git and run this script again."
            exit 1
        fi
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        echo -e "${GREEN}✓ yum detected!${NC}"
        echo ""
        if [ -t 0 ]; then
            read -p "Install Git via yum now? (requires sudo) (yes/no): " INSTALL_GIT
        else
            read -p "Install Git via yum now? (requires sudo) (yes/no): " INSTALL_GIT </dev/tty
        fi
        
        INSTALL_GIT=$(echo "$INSTALL_GIT" | tr '[:upper:]' '[:lower:]' | xargs)
        
        if [ "$INSTALL_GIT" = "yes" ] || [ "$INSTALL_GIT" = "y" ]; then
            echo ""
            print_step "Installing Git..."
            sudo yum install -y git
            
            if command -v git &> /dev/null; then
                print_success "Git installed successfully!"
                echo ""
            else
                print_error "Installation failed. Please install manually."
                exit 1
            fi
        else
            echo ""
            echo "Please install Git and run this script again."
            exit 1
        fi
    else
        echo ""
        echo "Please install Git manually and run this script again."
        exit 1
    fi
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

