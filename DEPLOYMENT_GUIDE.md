# 🚀 MT Voice Assistant - Deployment Guide

## Overview

This guide will help you deploy the complete MT Voice Assistant solution to any Salesforce org using automated deployment scripts.

---

## 📋 Prerequisites

### 1. Salesforce CLI Installation

**macOS:**
```bash
brew install sf
```

**Windows:**
- Download from: https://developer.salesforce.com/tools/salesforcecli
- Run the installer and follow the prompts

**Linux:**
```bash
npm install -g @salesforce/cli
```

**Verify Installation:**
```bash
sf --version
```

### 2. Salesforce Org Requirements

- ✅ Salesforce org with My Domain enabled
- ✅ System Administrator access
- ✅ Einstein AI enabled (for GenAI Prompt Templates)
- ✅ API access enabled

---

## 🎯 Quick Start

### For Mac/Linux Users

1. **Open Terminal**
2. **Navigate to the project directory:**
   ```bash
   cd "/path/to/Voice Assistant Visit Report"
   ```

3. **Make the script executable:**
   ```bash
   chmod +x deploy.sh
   ```

4. **Run the deployment script:**
   ```bash
   ./deploy.sh
   ```

### For Windows Users

1. **Open Command Prompt or PowerShell**
2. **Navigate to the project directory:**
   ```cmd
   cd "C:\path\to\Voice Assistant Visit Report"
   ```

3. **Run the deployment script:**
   ```cmd
   deploy.bat
   ```

---

## 📖 Step-by-Step Deployment Process

### Step 1: Run the Script

The script will guide you through the deployment process with colorful, easy-to-follow prompts.

### Step 2: Connect to Your Org

You'll be prompted to either:
- **Use an existing org connection** (enter the alias)
- **Create a new connection** by choosing:
  1. Production/Developer Org
  2. Sandbox
  3. Scratch Org

### Step 3: Confirm Deployment

Review the target org and confirm you want to proceed.

### Step 4: Automated Deployment

The script will deploy components in the following order:

1. ✅ Custom Metadata Types & Objects
2. ✅ Custom Permissions
3. ✅ Apex Classes
4. ✅ Lightning Web Components
   - mtRecordSuggestion
   - mtDateInput
   - mtEinsteinTranscribe
   - mtVoiceAssistantAdmin
5. ✅ Page Layouts
6. ✅ Custom Metadata Records
7. ✅ External Credentials
8. ✅ Named Credentials
9. ✅ CSP Trusted Sites
10. ✅ Connected App
11. ✅ GenAI Prompt Templates (deployed BEFORE flows)
12. ✅ Flows (depend on prompt templates)
13. ✅ Permission Sets
14. ✅ Custom Tab

### Step 5: Permission Set Assignment (Optional)

The script will offer to automatically assign permission sets to all System Administrators.

---

## 🔧 Post-Deployment Configuration

After the automated deployment completes, you'll need to complete these manual steps:

### 1. Configure Named Credentials

1. Go to **Setup** → **Named Credentials**
2. Click on **mt_EinsteinTranscribe**
3. Click **Edit**
4. Update the **URL** field with your org's My Domain URL:
   ```
   https://YOUR-ORG-DOMAIN.my.salesforce.com/services/einstein/ai/v1
   ```
5. Click **Save**

### 2. Enable Einstein AI (if not already enabled)

1. Go to **Setup** → **Einstein** → **Einstein AI**
2. Enable Einstein AI features
3. Accept the terms and conditions

### 3. Configure External Credentials (Optional - for OpenAI Whisper)

1. Go to **Setup** → **Named Credentials** → **External Credentials**
2. Click on **mt_OpenAI_Whisper**
3. Add your OpenAI API key
4. Click **Save**

### 4. Access the Setup Page

1. Open the **App Launcher**
2. Search for **"MT Voice Assistant Settings"**
3. Follow the guided setup wizard

### 5. Test the Installation

1. Navigate to an **Account** record
2. Click **Run Flow** (or use Quick Actions)
3. Select **MT_Visit_Report_MultiModal**
4. Test voice transcription and record creation

---

## 📦 What Gets Deployed

### ✅ Production-Ready Code Coverage
- **Average Coverage:** 88%
- **All classes:** >75% (meets Salesforce production requirements)
- **Highest:** mt_TranscribeController (100%)
- **Lowest:** mt_GetObjectConfigForPrompt (81%)

### Apex Classes (8 classes + tests)
- `mt_ConfigMetadataService` - Configuration management
- `mt_ConfigProfilePicklist` - Dynamic picklist values
- `mt_FileCombinerService` - File handling
- `mt_GetObjectConfigForPrompt` - Object metadata retrieval
- `mt_ImageFileService` - Image processing
- `mt_ObjectMetadataService` - Dynamic object metadata
- `mt_RecordService` - Record CRUD operations
- `mt_TranscribeController` - Main controller for transcription

### Lightning Web Components (4 components)
- `mtEinsteinTranscribe` - Main voice input component
- `mtRecordSuggestion` - AI-powered record suggestion UI
- `mtDateInput` - Custom date input component
- `mtVoiceAssistantAdmin` - Admin setup page

### Flows (2 flows)
- `MT_Visit_Report_MultiModal` - Account-based flow with image support
- `MT_Visit_Report_Standalone_v2` - Standalone flow for any object

### GenAI Prompt Templates (2 templates)
- `MT Voice Account (Multi-Modal)` - Used by MT_Visit_Report_MultiModal flow
- `MT Voice Standalone (Multi-Modal v2)` - Used by MT_Visit_Report_Standalone_v2 flow

### Custom Metadata Types (3 types)
- `Einstein Transcribe Settings` - API configuration
- `MT Voice Assistant Config` - Application configuration
- `MT Voice Assistant Object Config` - Object-specific settings

### Permission Sets (2 sets)
- `MT Voice Assistant Admin` - Full admin access
- `MT Voice Assistant User` - End-user access

### Other Components
- Custom Permissions (2)
- External Credentials (2)
- Named Credentials (2)
- Connected App (1)
- CSP Trusted Site (1)
- Custom Tab (1)
- Page Layouts (2)

---

## 🐛 Troubleshooting

### Issue: "Salesforce CLI not found"

**Solution:**
- Install Salesforce CLI using the instructions in the Prerequisites section
- Restart your terminal/command prompt after installation

### Issue: "Cannot connect to org"

**Solution:**
- Run `sf org list` to see available orgs
- Run `sf org login web --alias MyOrg` to authenticate
- Ensure you have System Administrator access

### Issue: "GenAI Prompt Templates failed to deploy"

**Solution:**
- This is expected if Einstein AI is not enabled
- Enable Einstein AI in Setup → Einstein → Einstein AI
- Re-run the deployment or manually deploy prompt templates

### Issue: "Named Credentials deployment failed"

**Solution:**
- This is normal - Named Credentials often need manual configuration
- Follow the Post-Deployment Configuration steps above

### Issue: "Permission denied" (Mac/Linux)

**Solution:**
```bash
chmod +x deploy.sh
```

### Issue: Component deployment failed

**Solution:**
- Check the error message in the terminal
- Verify all prerequisites are met
- Try deploying the specific component manually:
  ```bash
  sf project deploy start --target-org YourOrgAlias --source-dir force-app/main/default/[component-type]
  ```

---

## 🔄 Re-deploying or Updating

To update an existing installation:

1. Pull the latest code changes
2. Run the deployment script again
3. The script will update existing components

---

## 📞 Support

For issues, questions, or support:

**Email:** mtietze@salesforce.com

**Documentation:** Check the setup page in your org (MT Voice Assistant Settings)

---

## 📝 Manual Deployment (Alternative)

If you prefer to deploy manually without the script:

```bash
# 1. Authenticate to your org
sf org login web --alias MyOrg

# 2. Deploy all components
sf project deploy start --target-org MyOrg --source-dir force-app/main/default

# 3. Assign permission sets
sf org assign permset --name mt_VoiceAssistant_Admin --target-org MyOrg
sf org assign permset --name mt_VoiceAssistant_User --target-org MyOrg
```

---

## 🎉 Success!

Once deployment is complete and post-deployment steps are finished, you're ready to use MT Voice Assistant!

**Next Steps:**
1. Train your users on the new functionality
2. Customize prompt templates for your specific use cases
3. Configure object-specific settings in the admin page
4. Test thoroughly in a sandbox before deploying to production

---

## 📄 License

Copyright © 2025 Salesforce, Inc. All rights reserved.

**INTERNAL USE ONLY** - This code may not be shared externally or distributed outside of Salesforce without prior written approval from Michael Tietze (mtietze@salesforce.com).

