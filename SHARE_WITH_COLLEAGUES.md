# 🚀 Deploy MT Voice Assistant - For Colleagues

**One script. One command. Done!**

---

## ⚡ Quick Deploy

### Mac/Linux:

```bash
curl -O https://raw.githubusercontent.com/Tietziano90/MT-Visit-Report/main/deploy-voice-assistant.sh
chmod +x deploy-voice-assistant.sh
./deploy-voice-assistant.sh
```

**Or as one line:**
```bash
curl -sL https://raw.githubusercontent.com/Tietziano90/MT-Visit-Report/main/deploy-voice-assistant.sh | bash
```

---

## ✅ What You Need

- ✅ Salesforce CLI: https://developer.salesforce.com/tools/salesforcecli
- ✅ Git: https://git-scm.com/downloads
- ✅ System Administrator access to your Salesforce org
- ✅ Einstein AI enabled

---

## 🎬 What Happens

1. Script downloads latest code from GitHub
2. Browser opens for Salesforce login
3. All components deploy automatically (~3-5 minutes)
4. Permissions assigned to admins
5. Done! 🎉

---

## 📋 After Deployment

1. **Configure Named Credentials:**
   - Setup → Named Credentials → `mt_EinsteinTranscribe`
   - Update URL with your org's My Domain

2. **Access Setup:**
   - App Launcher → "Voice Assistant Setup"

3. **Test It:**
   - Go to any Account record
   - Run `MT_Visit_Report_MultiModal` flow
   - Try voice input!

---

## 🆘 Need Help?

**Email:** mtietze@salesforce.com  
**Repository:** https://github.com/Tietziano90/MT-Visit-Report

---

**That's it! Just one command and you're deploying!** 🚀







