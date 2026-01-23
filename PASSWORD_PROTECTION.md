# 🔐 Password Protection Guide

## How to Enable Password Protection

Your repository is **public** (anyone can clone it), but you can require a **password to deploy**.

---

## ✅ Enable Password Protection

### Step 1: Edit deploy.sh

Open `deploy.sh` and find these lines (around line 110):

```bash
# DEPLOYMENT_PASSWORD="your-secret-password-here"
# 
# if [ ! -z "$DEPLOYMENT_PASSWORD" ]; then
#     echo -e "${YELLOW}${WARNING} This deployment requires authorization${NC}"
```

### Step 2: Uncomment and Set Password

**Remove the `#` symbols** and **change the password**:

```bash
DEPLOYMENT_PASSWORD="MySecretPassword123"

if [ ! -z "$DEPLOYMENT_PASSWORD" ]; then
    echo -e "${YELLOW}${WARNING} This deployment requires authorization${NC}"
    echo ""
    read -sp "Enter deployment password: " USER_PASSWORD
    echo ""
    
    if [ "$USER_PASSWORD" != "$DEPLOYMENT_PASSWORD" ]; then
        echo ""
        print_error "Invalid password. Deployment cancelled."
        echo ""
        echo "Contact mtietze@salesforce.com for access."
        exit 1
    fi
    
    print_success "Password verified"
    echo ""
fi
```

### Step 3: Save and Push

```bash
git add deploy.sh
git commit -m "Enable password protection for deployment"
git push github main
```

---

## 🎯 How It Works

### Without Password:
- ✅ Anyone can **clone** the repository
- ✅ Anyone can **view** the code
- ❌ **Cannot deploy** without password

### With Password:
- User runs `./deploy.sh`
- Script prompts: `Enter deployment password:`
- User enters password
- If correct: Deployment continues ✅
- If wrong: Deployment stops ❌

---

## 🔐 Alternative: Keep Repository Private

If you want **full protection** (can't even clone without permission):

### Step 1: Make Repository Private

1. Go to: https://github.com/Tietziano90/MT-Visit-Report/settings
2. Scroll to "Danger Zone"
3. Click "Change visibility" → "Make private"

### Step 2: Add Collaborators

1. Go to: https://github.com/Tietziano90/MT-Visit-Report/settings/access
2. Click "Add people"
3. Enter their GitHub username
4. Select permission level (Read, Write, or Admin)
5. Click "Add"

### Step 3: Share Instructions

Tell users:

```bash
# They'll need to authenticate with their GitHub account
git clone https://github.com/Tietziano90/MT-Visit-Report.git
cd MT-Visit-Report
./deploy.sh
```

---

## 📊 Comparison

| Method | Clone | View Code | Deploy | Best For |
|--------|-------|-----------|--------|----------|
| **Public + No Password** | ✅ Anyone | ✅ Anyone | ✅ Anyone | Open source, demos |
| **Public + Password** | ✅ Anyone | ✅ Anyone | 🔐 Password | Share code, control deployment |
| **Private + Collaborators** | 🔐 GitHub Auth | 🔐 GitHub Auth | 🔐 GitHub Auth | Internal teams, sensitive code |

---

## 🎯 Recommended Setup

**For Internal Salesforce Use:**
- ✅ Keep repository **Public**
- ✅ Enable **Password Protection** in deploy.sh
- ✅ Share password only with authorized users

**Benefits:**
- Code is visible (transparency)
- Easy to share/demo
- Controlled deployment
- No GitHub account management needed

---

## 📝 Current Status

**Repository:** https://github.com/Tietziano90/MT-Visit-Report  
**Visibility:** Public  
**Password Protection:** Disabled (code commented out)

**To enable:** Follow Step 2 above!

---

## 🆘 Support

**Questions?** Contact: mtietze@salesforce.com

---

**Version:** 1.0  
**Last Updated:** December 16, 2025











