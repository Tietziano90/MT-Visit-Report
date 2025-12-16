# 🎙️ MT Voice Assistant - AI-Powered Voice-to-Record Solution

## Overview

MT Voice Assistant is a comprehensive Salesforce solution that transforms voice input into structured Salesforce records using AI. It supports multi-modal input (voice + images), intelligent field mapping, and seamless record creation across any Salesforce object.

---

## ✨ Key Features

- 🎤 **Voice Transcription** - Convert speech to text using Einstein AI or OpenAI Whisper
- 🖼️ **Image Support** - Attach and process images (business cards, documents, etc.)
- 🤖 **AI-Powered Record Suggestions** - Automatically parse voice input into structured fields
- 📱 **Mobile Optimized** - Beautiful, responsive UI for mobile devices
- 🔄 **Multi-Object Support** - Works with any Salesforce standard or custom object
- ⚙️ **Configurable** - Customize prompts, fields, and behavior per object
- 🔐 **Secure** - Enterprise-grade security with permission sets and external credentials

---

## 🚀 Quick Deployment

### 🌟 Option 1: Direct Download (Easiest - No Git Login!)

**No authentication required! Just download and run:**

**Mac/Linux:**
```bash
curl -L https://github.com/mtietze/MT-Visit-Report/-/archive/main/MT-Visit-Report-main.tar.gz | tar xz
cd MT-Visit-Report-main
./deploy.sh
```

**Windows:**
1. Download: [MT-Visit-Report-main.zip](https://github.com/mtietze/MT-Visit-Report/-/archive/main/MT-Visit-Report-main.zip)
2. Extract the ZIP
3. Double-click `deploy.bat`

📖 **See:** [SIMPLE_DEPLOY_INSTRUCTIONS.md](SIMPLE_DEPLOY_INSTRUCTIONS.md) for details

---

### Option 2: Git-Based Deployment (Always Latest)

**Automatically pull and deploy the latest code:**

**Mac/Linux:**
```bash
./deploy-from-git.sh
```
Or double-click: `Deploy from Git.command`

**Windows:**
```cmd
deploy-from-git.bat
```

**Benefits:**
- ✅ Always deploys the latest version
- ✅ No manual download needed
- ✅ Automatic cleanup
- ✅ One command deployment

📖 **See:** [GIT_DEPLOYMENT_GUIDE.md](GIT_DEPLOYMENT_GUIDE.md) for details

---

### Option 3: Visual Guide (Optional)

**Double-click:** `deploy-wizard.html`

A beautiful web interface that:
- ✅ Explains each step visually
- ✅ Checks prerequisites
- ✅ Shows you which script to run
- ✅ Provides post-deployment checklist

**Perfect for:** First-time users who want a visual walkthrough

---

📖 **Need more details?** See [QUICK_START.md](QUICK_START.md)

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [GIT_DEPLOYMENT_GUIDE.md](GIT_DEPLOYMENT_GUIDE.md) | 🌟 **NEW!** Git-based deployment guide |
| [QUICK_START.md](QUICK_START.md) | Fast track deployment (2 minutes) |
| [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) | Complete deployment documentation |
| [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md) | Deployment summary and metrics |
| [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md) | Component checklist and verification |

---

## 🎯 Use Cases

### 1. **Visit Reports**
Record customer visit details, action items, and follow-ups using voice input while on-site.

### 2. **Business Card Scanning**
Take a photo of a business card and create a Contact record with all details extracted.

### 3. **Meeting Notes**
Capture meeting outcomes, decisions, and next steps as Task or Event records.

### 4. **Opportunity Updates**
Update opportunity stages, amounts, and close dates using voice commands.

### 5. **Custom Objects**
Configure for any custom object - Cases, Projects, Work Orders, etc.

---

## 🏗️ Architecture

### Components

```
┌─────────────────────────────────────────────────────────────┐
│                    MT Voice Assistant                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐      ┌──────────────┐                    │
│  │   Voice      │      │    Image     │                    │
│  │   Input      │      │    Input     │                    │
│  └──────┬───────┘      └──────┬───────┘                    │
│         │                     │                             │
│         └──────────┬──────────┘                             │
│                    │                                         │
│         ┌──────────▼──────────┐                            │
│         │  Einstein AI /      │                            │
│         │  OpenAI Whisper     │                            │
│         └──────────┬──────────┘                            │
│                    │                                         │
│         ┌──────────▼──────────┐                            │
│         │   GenAI Prompts     │                            │
│         │   (Field Parsing)   │                            │
│         └──────────┬──────────┘                            │
│                    │                                         │
│         ┌──────────▼──────────┐                            │
│         │  Record Suggestion  │                            │
│         │  UI (Edit/Review)   │                            │
│         └──────────┬──────────┘                            │
│                    │                                         │
│         ┌──────────▼──────────┐                            │
│         │   Salesforce        │                            │
│         │   Record Creation   │                            │
│         └─────────────────────┘                            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack

- **Frontend:** Lightning Web Components (LWC)
- **Backend:** Apex
- **AI:** Einstein AI / OpenAI Whisper
- **Orchestration:** Salesforce Flows
- **Configuration:** Custom Metadata Types

---

## 📦 What's Included

### Apex Classes (8)
- Configuration management
- Object metadata services
- Record services
- Image processing
- Transcription controller

### Lightning Web Components (4)
- Voice input component
- Record suggestion UI
- Admin setup page
- Custom date input

### Flows (2)
- Multi-modal account flow
- Standalone generic flow

### GenAI Prompt Templates (2)
- Account-specific prompts (used by MultiModal flow)
- Generic prompts (used by Standalone flow)

### Configuration
- Custom Metadata Types (3)
- Permission Sets (2)
- External Credentials (2)
- Named Credentials (2)
- Connected App (1)

---

## 🔧 Configuration

### Admin Setup Page

Access via: **App Launcher → MT Voice Assistant Settings**

The setup page provides:
- ✅ Step-by-step configuration wizard
- ✅ Named credential setup
- ✅ Einstein AI configuration
- ✅ OpenAI Whisper configuration (optional)
- ✅ Object-specific settings
- ✅ Prompt template management
- ✅ Test connection functionality

### Per-Object Configuration

Configure for each object:
- **Allowed Fields** - Which fields can be populated
- **Mandatory Fields** - Required fields for record creation
- **Allow Create** - Enable/disable record creation
- **Allow Edit** - Enable/disable editing existing records

---

## 🔐 Security

### Permission Sets

**MT Voice Assistant Admin**
- Full configuration access
- Metadata management
- Credential configuration

**MT Voice Assistant User**
- Voice input access
- Record creation
- External credential usage

### Data Security

- ✅ External credentials for API keys
- ✅ Named credentials for secure API calls
- ✅ Field-level security respected
- ✅ Object-level security enforced
- ✅ Sharing rules applied

---

## 📱 Mobile Experience

Fully optimized for mobile devices:
- ✅ Touch-friendly UI
- ✅ Responsive design
- ✅ Image compression for mobile uploads
- ✅ Simplified field selection
- ✅ One-tap record saving

---

## 🧪 Testing

### Test the Installation

1. **Navigate to an Account record**
2. **Click "Run Flow"** or use Quick Actions
3. **Select "MT_Visit_Report_MultiModal"**
4. **Record voice input** or type text
5. **Optionally attach an image**
6. **Review suggested fields**
7. **Save the record**

### Verify Success

- ✅ Voice transcription works
- ✅ AI suggests correct fields
- ✅ Records are created successfully
- ✅ Images are attached (if provided)
- ✅ Mobile experience is smooth

---

## 🐛 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Voice transcription fails | Check Named Credential configuration |
| GenAI prompts not working | Ensure Einstein AI is enabled |
| Permission errors | Assign permission sets to users |
| Mobile image upload fails | Check image compression settings |
| Flow errors | Verify all Apex classes deployed |

📖 **Full troubleshooting guide:** [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

---

## 🔄 Updates and Maintenance

### Updating the Solution

1. Pull latest code changes
2. Run deployment script again
3. Review release notes
4. Test in sandbox first

### Monitoring

- Check Setup Audit Trail for configuration changes
- Monitor Flow execution logs
- Review API usage for Einstein/OpenAI calls
- Track permission set assignments

---

## 📊 Best Practices

### 1. **Start with Standard Objects**
Test with Account, Contact, or Opportunity before custom objects.

### 2. **Customize Prompts**
Tailor GenAI prompts to your specific business terminology.

### 3. **Train Users**
Provide clear examples of voice input format.

### 4. **Test in Sandbox**
Always test configuration changes in sandbox first.

### 5. **Monitor API Usage**
Track Einstein AI and OpenAI API consumption.

### 6. **Regular Backups**
Back up custom metadata configurations regularly.

---

## 🎓 Training Resources

### For Administrators

1. Review the setup page walkthrough
2. Understand custom metadata configuration
3. Learn prompt template customization
4. Practice user management

### For End Users

1. Practice voice input with clear speech
2. Learn field selection on mobile
3. Understand image attachment process
4. Review record suggestions before saving

---

## 📞 Support

### Contact

**Email:** mtietze@salesforce.com  
**Author:** Michael Tietze, Principal AI Architect  
**Organization:** Salesforce

### Getting Help

1. Check documentation files
2. Review troubleshooting guide
3. Contact support email
4. Review Salesforce Trailhead for LWC/Flow basics

---

## 📄 License

**Copyright © 2025 Salesforce, Inc. All rights reserved.**

**INTERNAL USE ONLY** - This code may not be shared externally or distributed outside of Salesforce without prior written approval from Michael Tietze (mtietze@salesforce.com).

---

## 🎉 Get Started Now!

```bash
# Mac/Linux
./deploy.sh

# Windows
deploy.bat
```

**Questions?** Read [QUICK_START.md](QUICK_START.md) or [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

---

**Version:** 1.0  
**Last Updated:** December 16, 2025  
**Status:** Production Ready ✅  
**Code Coverage:** 88% Average (All classes >75%)  
**Repository:** https://github.com/mtietze/MT-Visit-Report
