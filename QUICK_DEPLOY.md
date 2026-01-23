# ⚡ Quick Deploy - MT Voice Assistant

**Get up and running in 2 minutes!**

---

## 🚀 Option 1: One-File Download (Easiest!)

### Mac/Linux

1. **Download the deployment script:**
   - Right-click and "Save As": [deploy-from-git.sh](https://github.com/Tietziano90/MT-Visit-Report/-/raw/main/deploy-from-git.sh)
   - Or use Terminal:
     ```bash
     curl -O https://github.com/Tietziano90/MT-Visit-Report/-/raw/main/deploy-from-git.sh
     ```

2. **Run it:**
   ```bash
   chmod +x deploy-from-git.sh
   ./deploy-from-git.sh
   ```

3. **Follow the prompts** - the script does everything automatically!

### Windows

1. **Download the deployment script:**
   - Right-click and "Save As": [deploy-from-git.bat](https://github.com/Tietziano90/MT-Visit-Report/-/raw/main/deploy-from-git.bat)

2. **Double-click** `deploy-from-git.bat`

3. **Follow the prompts** - the script does everything automatically!

---

## 🎯 Option 2: Clone Repository (For Developers)

```bash
# Clone the repository
git clone https://github.com/Tietziano90/MT-Visit-Report.git

# Navigate to directory
cd MT-Visit-Report

# Run deployment
./deploy-from-git.sh
```

---

## ✅ What the Script Does Automatically

1. ✅ **Checks prerequisites** (Salesforce CLI, Git)
2. ✅ **Pulls latest code** from Git repository
3. ✅ **Opens browser** for Salesforce login
4. ✅ **Deploys all components** in correct order:
   - Apex classes
   - Lightning Web Components
   - Flows
   - Prompt Templates
   - Permission Sets
   - And more...
5. ✅ **Assigns permission sets** to all System Administrators
6. ✅ **Cleans up** temporary files
7. ✅ **Shows next steps**

---

## 📋 Prerequisites

Before running the script, make sure you have:

- ✅ **Salesforce CLI** installed ([Download](https://developer.salesforce.com/tools/salesforcecli))
- ✅ **Git** installed ([Download](https://git-scm.com/downloads))
- ✅ **System Administrator** access to your Salesforce org
- ✅ **Einstein AI** enabled in your org

**Check if installed:**
```bash
sf --version
git --version
```

---

## 🎬 What to Expect

### Deployment Time
- **Total:** ~3-5 minutes
- **Browser login:** ~1 minute
- **Component deployment:** ~2-3 minutes
- **Permission assignment:** ~30 seconds

### During Deployment
You'll see:
```
🚀 MT VOICE ASSISTANT - GIT DEPLOYMENT WIZARD 🚀

⚙️ CHECKING PREREQUISITES
✓ Salesforce CLI detected
✓ Git detected

📦 PULLING LATEST CODE FROM GIT
✓ Successfully pulled latest code from Git

⚙️ CONNECTING TO SALESFORCE ORG
[Browser opens for login]
✓ Successfully connected to org

📦 STARTING DEPLOYMENT SEQUENCE
→ Deploying: Apex Classes
✓ Apex Classes deployed successfully
...
```

---

## 🎉 After Deployment

Once complete, you'll need to:

1. **Configure Named Credentials:**
   - Setup → Named Credentials → `mt_EinsteinTranscribe`
   - Update URL with your org's My Domain

2. **Access Setup Page:**
   - App Launcher → "Voice Assistant Setup"
   - Follow the guided setup wizard

3. **Test It:**
   - Go to any Account record
   - Run the `MT_Visit_Report_MultiModal` flow
   - Try voice input!

---

## 🆘 Troubleshooting

### "Salesforce CLI not found"
Install from: https://developer.salesforce.com/tools/salesforcecli

### "Git not found"
Install from: https://git-scm.com/downloads

### "Failed to clone repository"
Make sure you're on Salesforce VPN or network

### Component deployment failed
- Check that Einstein AI is enabled
- Verify My Domain is configured
- Re-run the script (it will skip successful components)

---

## 📞 Need Help?

- **Email:** mtietze@salesforce.com
- **Repository:** https://github.com/Tietziano90/MT-Visit-Report
- **Full Documentation:** See `README.md` in the repository

---

## 🌟 That's It!

Just download one file and run it. The script handles everything else automatically!

**Repository:** https://github.com/Tietziano90/MT-Visit-Report

---

**Version:** 1.0  
**Last Updated:** December 16, 2025











