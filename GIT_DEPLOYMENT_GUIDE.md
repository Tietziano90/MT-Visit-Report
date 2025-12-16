# 🚀 Git-Based Deployment Guide

**MT Voice Assistant - Automatic Deployment from Git Repository**

---

## 📖 Overview

The Git-based deployment scripts automatically pull the latest code from the repository and deploy it to your Salesforce org. **No manual download or extraction required!**

### Benefits
- ✅ **Always Latest:** Automatically pulls the newest version
- ✅ **No Manual Download:** Script handles everything
- ✅ **Public Access:** No Git authentication needed for read access
- ✅ **One Command:** Just run the script and follow prompts
- ✅ **Cross-Platform:** Works on Mac, Linux, and Windows

---

## 🎯 Quick Start

### For Mac/Linux Users

**Option 1: Double-Click (Easiest)**
1. Double-click `Deploy from Git.command`
2. Follow the on-screen prompts

**Option 2: Terminal**
```bash
./deploy-from-git.sh
```

### For Windows Users

**Option 1: Double-Click (Easiest)**
1. Double-click `deploy-from-git.bat`
2. Follow the on-screen prompts

**Option 2: Command Prompt**
```cmd
deploy-from-git.bat
```

---

## 📋 Prerequisites

Before running the Git deployment script, ensure you have:

### Required Software
1. **Salesforce CLI** (latest version)
   - Download: https://developer.salesforce.com/tools/salesforcecli
   - Verify: `sf --version`

2. **Git** (any recent version)
   - Download: https://git-scm.com/downloads
   - Verify: `git --version`

### Salesforce Org Requirements
- ✅ My Domain enabled
- ✅ Einstein AI enabled (for GenAI features)
- ✅ System Administrator access
- ✅ API access enabled

---

## 🔄 How It Works

### Step-by-Step Process

1. **Prerequisite Check**
   - Verifies Salesforce CLI is installed
   - Verifies Git is installed

2. **Pull Latest Code**
   - Clones repository to temporary directory
   - Shows latest commit information
   - No authentication required (public read access)

3. **Connect to Org**
   - Browser-based authentication
   - Supports Production, Sandbox, and Scratch orgs
   - Saves org alias for future use

4. **Deploy Components**
   - Deploys in correct dependency order
   - Shows progress for each component
   - Handles failures gracefully

5. **Assign Permissions**
   - Automatically assigns permission sets to all System Administrators
   - No manual assignment needed

6. **Cleanup**
   - Removes temporary files
   - Shows deployment summary
   - Provides post-deployment instructions

---

## 🌐 Git Repository

### Repository Information
- **URL:** https://git.soma.salesforce.com/mtietze/MT-Visit-Report
- **Access:** Public read (no authentication required)
- **Branch:** main
- **Latest Version:** Always deployed

### Repository Contents
```
voice-assistant-visit-report/
├── force-app/                    # Salesforce metadata
│   └── main/default/
│       ├── classes/              # Apex classes
│       ├── lwc/                  # Lightning Web Components
│       ├── flows/                # Flows
│       ├── genAiPromptTemplates/ # Prompt templates
│       └── ...                   # Other metadata
├── deploy-from-git.sh            # Mac/Linux deployment script
├── deploy-from-git.bat           # Windows deployment script
├── Deploy from Git.command       # Mac double-click launcher
├── README.md                     # Project overview
├── DEPLOYMENT_GUIDE.md           # Manual deployment guide
├── GIT_DEPLOYMENT_GUIDE.md       # This file
└── ...                           # Documentation files
```

---

## 🎬 Deployment Walkthrough

### Mac/Linux Example

```bash
$ ./deploy-from-git.sh

═══════════════════════════════════════════════════════════════════
🚀 MT VOICE ASSISTANT - GIT DEPLOYMENT WIZARD 🚀
═══════════════════════════════════════════════════════════════════

This script will:
  1. ✅ Pull the latest code from Git (no authentication required)
  2. ✅ Connect to your Salesforce org
  3. ✅ Deploy all components in the correct order
  4. ✅ Assign permission sets to admins

═══════════════════════════════════════════════════════════════════
⚙️ CHECKING PREREQUISITES
═══════════════════════════════════════════════════════════════════

✓ Salesforce CLI detected
✓ Git detected

═══════════════════════════════════════════════════════════════════
📦 PULLING LATEST CODE FROM GIT
═══════════════════════════════════════════════════════════════════

→ Repository: https://git.soma.salesforce.com/mtietze/MT-Visit-Report.git
→ Cloning to temporary directory...
✓ Successfully pulled latest code from Git
ℹ️ Latest commit: f8d0b3c - Initial commit: MT Voice Assistant v1.0 (2 minutes ago)

═══════════════════════════════════════════════════════════════════
⚙️ CONNECTING TO SALESFORCE ORG
═══════════════════════════════════════════════════════════════════

ℹ️ Enter your Salesforce org alias (or press Enter to create a new connection):
Org Alias: MyOrg

→ Verifying org connection...
✓ Org connection verified: MyOrg

⚠️ This will deploy MT Voice Assistant to: MyOrg

ℹ️ Type 'yes' to continue or 'no' to cancel
Continue? (yes/no): yes

═══════════════════════════════════════════════════════════════════
📦 STARTING DEPLOYMENT SEQUENCE
═══════════════════════════════════════════════════════════════════

[... deployment progress ...]

═══════════════════════════════════════════════════════════════════
✅ DEPLOYMENT COMPLETE
═══════════════════════════════════════════════════════════════════

Deployment Time: 180 seconds
Target Org: MyOrg
Source: Git (latest commit)

[... post-deployment instructions ...]
```

---

## 🔧 Troubleshooting

### Issue: "Could not resolve host: soma.git.soma.salesforce.com"

**Cause:** Not connected to Salesforce network or repository doesn't exist yet

**Solution:**
1. Ensure you're on Salesforce VPN or network
2. Verify repository exists: https://git.soma.salesforce.com/mtietze/MT-Visit-Report
3. If repository doesn't exist, create it first (see Repository Setup below)

### Issue: "Authentication required"

**Cause:** Repository is private or credentials not cached

**Solution (Mac/Linux):**
```bash
git config --global credential.helper store
```

**Solution (Windows):**
```cmd
git config --global credential.helper wincred
```

Then run the deployment script again.

### Issue: "Git not found"

**Cause:** Git is not installed or not in PATH

**Solution:**
1. Download Git: https://git-scm.com/downloads
2. Install Git
3. Restart terminal/command prompt
4. Verify: `git --version`

### Issue: "Salesforce CLI not found"

**Cause:** Salesforce CLI is not installed or not in PATH

**Solution:**
1. Download CLI: https://developer.salesforce.com/tools/salesforcecli
2. Install CLI
3. Restart terminal/command prompt
4. Verify: `sf --version`

### Issue: Component deployment failed

**Cause:** Various reasons (dependencies, org settings, etc.)

**Solution:**
1. Check the error message for specific component
2. Review DEPLOYMENT_GUIDE.md for manual steps
3. Ensure Einstein AI is enabled (for prompt templates)
4. Verify My Domain is configured (for named credentials)
5. Re-run the script (it will skip already deployed components)

---

## 🆚 Git Deployment vs. Manual Deployment

| Feature | Git Deployment | Manual Deployment |
|---------|----------------|-------------------|
| **Latest Code** | ✅ Always | ⚠️ Depends on download |
| **Setup Time** | 🚀 2 minutes | ⏱️ 10+ minutes |
| **Steps Required** | 1 (run script) | 5+ (download, extract, deploy, etc.) |
| **Updates** | ✅ Automatic | ❌ Manual download |
| **Temp Files** | ✅ Auto-cleanup | ⚠️ Manual cleanup |
| **Error Recovery** | ✅ Easy (re-run) | ⚠️ Manual retry |

**Recommendation:** Use Git deployment for easiest and fastest deployment!

---

## 📚 Repository Setup (For Administrators)

If the repository doesn't exist yet, follow these steps to create it:

### 1. Create Repository on soma.git

1. Go to: https://soma.git.soma.salesforce.com
2. Click **"New Repository"** or **"+"**
3. Fill in details:
   - **Repository name:** `voice-assistant-visit-report`
   - **Description:** `MT Voice Assistant - Production-ready Salesforce voice-to-record solution with Einstein AI`
   - **Visibility:** Private (internal use)
   - **Initialize:** Don't initialize with README (we have one)
4. Click **"Create Repository"**

### 2. Push Code to Repository

From your local project directory:

```bash
cd "/path/to/Voice Assistant Visit Report"
git init
git add .
git commit -m "Initial commit: MT Voice Assistant v1.0 - Production Ready"
git remote add origin https://soma.git.soma.salesforce.com/mtietze/voice-assistant-visit-report.git
git branch -M main
git push -u origin main
```

### 3. Configure Repository Settings

1. Go to repository settings
2. Enable **"Public read access"** (optional, for easier deployment)
3. Add collaborators if needed
4. Set up branch protection for `main` (recommended)

### 4. Test Deployment

Run the Git deployment script to verify it works:

```bash
./deploy-from-git.sh
```

---

## 🔐 Security Considerations

### Public Read Access
- ✅ **Pros:** No authentication needed for deployment
- ⚠️ **Cons:** Code is visible to anyone on Salesforce network
- 💡 **Recommendation:** Keep private if code contains sensitive logic

### Private Repository
- ✅ **Pros:** Code is protected
- ⚠️ **Cons:** Requires Git authentication for deployment
- 💡 **Setup:** Configure credential helper (see Troubleshooting)

### Credentials in Code
- ❌ **Never commit:** API keys, passwords, or secrets
- ✅ **Use:** Named Credentials and External Credentials
- ✅ **Configure:** Post-deployment via Salesforce Setup

---

## 📞 Support

### Getting Help
1. **Documentation:** Check README.md and DEPLOYMENT_GUIDE.md
2. **Troubleshooting:** Review this guide's troubleshooting section
3. **Contact:** mtietze@salesforce.com

### Reporting Issues
When reporting issues, include:
- Operating system (Mac/Windows/Linux)
- Salesforce CLI version (`sf --version`)
- Git version (`git --version`)
- Error message (full text)
- Steps to reproduce

---

## 🎉 Success!

Once deployment is complete:

1. ✅ **Configure Named Credentials**
   - Setup → Named Credentials → mt_EinsteinTranscribe
   - Update URL with your org's My Domain

2. ✅ **Enable Einstein AI**
   - Setup → Einstein → Einstein AI

3. ✅ **Access Setup Page**
   - App Launcher → Voice Assistant Setup
   - Follow guided setup wizard

4. ✅ **Test Installation**
   - Navigate to Account record
   - Run MT_Visit_Report_MultiModal flow
   - Test voice input and AI suggestions

---

**Congratulations! You've deployed MT Voice Assistant from Git! 🎉**

For more information, see:
- `README.md` - Project overview
- `DEPLOYMENT_GUIDE.md` - Manual deployment guide
- `DEPLOYMENT_SUMMARY.md` - Complete component list

---

**Version:** 2.0  
**Last Updated:** December 16, 2025  
**Author:** Michael Tietze (mtietze@salesforce.com)

