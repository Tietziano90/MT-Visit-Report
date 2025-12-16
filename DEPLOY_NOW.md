# 🚀 Deploy MT Voice Assistant - Start Here!

**Get up and running in 3 minutes!**

---

## ⚡ Quick Deploy (No Authentication Required)

Since the repository is public, you can clone it without any login:

### **Mac/Linux:**

```bash
# Clone the repository (no authentication needed!)
git clone https://git.soma.salesforce.com/mtietze/MT-Visit-Report.git

# Navigate to directory
cd MT-Visit-Report

# Run deployment
./deploy.sh
```

**Or as one command:**
```bash
git clone https://git.soma.salesforce.com/mtietze/MT-Visit-Report.git && cd MT-Visit-Report && ./deploy.sh
```

### **Windows:**

```cmd
# Clone the repository (no authentication needed!)
git clone https://git.soma.salesforce.com/mtietze/MT-Visit-Report.git

# Navigate to directory
cd MT-Visit-Report

# Double-click to deploy
deploy.bat
```

---

## 📥 Alternative: Download ZIP (If Git Not Installed)

If you don't have Git installed:

1. **Go to:** https://git.soma.salesforce.com/mtietze/MT-Visit-Report
2. **Click:** The blue "Code" button
3. **Select:** "Download ZIP"
4. **Extract** the ZIP file
5. **Run:**
   - Mac/Linux: `./deploy.sh`
   - Windows: Double-click `deploy.bat`

---

## ✅ Prerequisites

Before deploying, make sure you have:

- ✅ **Salesforce CLI** installed
  - Download: https://developer.salesforce.com/tools/salesforcecli
  - Check: `sf --version`

- ✅ **Git** installed (for clone method)
  - Download: https://git-scm.com/downloads
  - Check: `git --version`

- ✅ **System Administrator** access to your Salesforce org

- ✅ **Einstein AI** enabled in your org

---

## 🎬 What Happens During Deployment

1. ✅ Script checks prerequisites
2. ✅ Browser opens for Salesforce login
3. ✅ All components deploy automatically (~3-5 minutes):
   - Apex classes
   - Lightning Web Components
   - Flows
   - GenAI Prompt Templates
   - Permission Sets
   - And more...
4. ✅ Permission sets assigned to all System Administrators
5. ✅ Post-deployment instructions displayed

---

## 🎉 After Deployment

Once complete:

1. **Configure Named Credentials:**
   - Setup → Named Credentials → `mt_EinsteinTranscribe`
   - Update URL with your org's My Domain

2. **Access Setup Page:**
   - App Launcher → "Voice Assistant Setup"
   - Follow the guided setup wizard

3. **Test It:**
   - Navigate to any Account record
   - Run the `MT_Visit_Report_MultiModal` flow
   - Try voice input with image attachment!

---

## 🆘 Troubleshooting

### "Salesforce CLI not found"
Install from: https://developer.salesforce.com/tools/salesforcecli

### "Git not found"
Install from: https://git-scm.com/downloads  
Or use the ZIP download method above

### Component deployment failed
- Verify Einstein AI is enabled
- Check My Domain is configured
- Re-run the script (it will skip successful components)

### Need more help?
- **Email:** mtietze@salesforce.com
- **Full Documentation:** See `README.md` in the repository

---

## 📊 What Gets Deployed

- **8 Apex Classes** (with 88% test coverage)
- **4 Lightning Web Components**
- **2 Flows**
- **2 GenAI Prompt Templates**
- **2 Permission Sets**
- **Named Credentials**
- **Custom Metadata Types**
- **And more...**

**Total:** 40+ components, all production-ready!

---

## 🎯 One-Command Deploy

**Copy and paste this:**

```bash
git clone https://git.soma.salesforce.com/mtietze/MT-Visit-Report.git && cd MT-Visit-Report && ./deploy.sh
```

**That's it!** The script handles everything else automatically! 🚀

---

**Repository:** https://git.soma.salesforce.com/mtietze/MT-Visit-Report  
**Version:** 1.0  
**Last Updated:** December 16, 2025

