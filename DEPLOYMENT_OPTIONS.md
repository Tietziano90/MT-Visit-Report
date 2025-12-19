# 🚀 MT Voice Assistant - Deployment Options

**Choose the best deployment method for your needs**

---

## 📦 Option 1: Clone Repository & Deploy (Recommended)

**Best for:** Everyone - works with both public and private repositories

### Steps:

```bash
# 1. Clone the repository (authenticate once)
git clone https://github.com/Tietziano90/MT-Visit-Report.git

# 2. Navigate to directory
cd MT-Visit-Report

# 3. Run deployment script
./deploy.sh
```

**For Windows:**
```cmd
# After cloning, just double-click:
deploy.bat
```

---

## ⚡ Option 2: Direct Download (If Repository is Public)

**Best for:** Quick one-time deployment (requires repository to be set as "Internal" or "Public")

### Mac/Linux:
```bash
curl -O https://github.com/Tietziano90/MT-Visit-Report/-/raw/main/deploy-from-git.sh
chmod +x deploy-from-git.sh
./deploy-from-git.sh
```

### Windows:
Download and run: [deploy-from-git.bat](https://github.com/Tietziano90/MT-Visit-Report/-/raw/main/deploy-from-git.bat)

---

## 🎯 Recommended Approach

### For Internal Salesforce Use:

1. **Set repository to "Internal"** (visible to all Salesforce employees)
   - Settings → General → Visibility → Internal
   
2. **Share this command:**
   ```bash
   git clone https://github.com/Tietziano90/MT-Visit-Report.git
   cd MT-Visit-Report
   ./deploy.sh
   ```

3. **Users authenticate once** with their Salesforce Git credentials

---

## 📋 What Each Script Does

### `deploy.sh` / `deploy.bat` (Local Deployment)
- ✅ Deploys from **local files**
- ✅ Works offline (after clone)
- ✅ No repeated Git authentication
- ✅ **Recommended for most users**

### `deploy-from-git.sh` / `deploy-from-git.bat` (Git-Based)
- ✅ Always gets **latest version**
- ✅ Auto-clones repository
- ✅ Requires public/internal repository OR Git credentials
- ✅ Best for always-updated deployments

---

## 🔐 Repository Visibility Options

### Private
- ❌ Requires explicit user access
- ❌ Users need credentials for every download
- ✅ Most secure
- **Use for:** Sensitive/unreleased code

### Internal (Recommended for Internal Tools)
- ✅ All Salesforce employees can access
- ✅ One-time authentication
- ✅ Easy sharing
- **Use for:** Internal Salesforce tools

### Public
- ✅ Anyone can access (even outside Salesforce)
- ⚠️ Not recommended for internal tools
- **Use for:** Open-source projects only

---

## 🎓 User Instructions (Copy & Paste)

### For Users Deploying MT Voice Assistant:

**Prerequisites:**
- Salesforce CLI installed: https://developer.salesforce.com/tools/salesforcecli
- Git installed: https://git-scm.com/downloads
- System Administrator access to your Salesforce org

**Deployment Steps:**

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Tietziano90/MT-Visit-Report.git
   ```
   
   *You'll be prompted for your Salesforce Git username and password (one time)*

2. **Navigate to the directory:**
   ```bash
   cd MT-Visit-Report
   ```

3. **Run the deployment script:**
   
   **Mac/Linux:**
   ```bash
   ./deploy.sh
   ```
   Or double-click: `Deploy MT Voice Assistant.command`
   
   **Windows:**
   Double-click: `deploy.bat`

4. **Follow the prompts:**
   - Choose your org type (Production/Sandbox)
   - Log in via browser
   - Wait for deployment to complete (~3-5 minutes)

5. **Post-Deployment:**
   - Configure Named Credentials in Setup
   - Access "Voice Assistant Setup" from App Launcher
   - Test on an Account record

---

## 🆘 Troubleshooting

### "Authentication required" when cloning
- Make sure you're on Salesforce VPN/network
- Use your Salesforce Git credentials (not Salesforce org credentials)
- Create a personal access token if needed: https://git.soma.salesforce.com/-/profile/personal_access_tokens

### "Repository not found"
- Check that you have access to the repository
- Verify the URL is correct
- Contact mtietze@salesforce.com for access

### Deployment fails
- Ensure Einstein AI is enabled in your org
- Verify My Domain is configured
- Check that you have System Administrator access
- Re-run the script (it will skip already-deployed components)

---

## 📞 Support

- **Email:** mtietze@salesforce.com
- **Repository:** https://github.com/Tietziano90/MT-Visit-Report
- **Documentation:** See README.md in the repository

---

## ✅ Recommended Setup

**For easiest deployment experience:**

1. Set repository visibility to **"Internal"**
2. Share this command with users:
   ```bash
   git clone https://github.com/Tietziano90/MT-Visit-Report.git && cd MT-Visit-Report && ./deploy.sh
   ```
3. Users authenticate once with Git, then deploy locally

This provides the best balance of security and ease of use!

---

**Version:** 1.0  
**Last Updated:** December 16, 2025







