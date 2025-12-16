# 📋 MT Voice Assistant - Complete Deployment Checklist

## Components Included in Deployment

### ✅ Apex Classes (8 + 8 Test Classes)

**Production Classes:**
- [ ] `mt_ConfigMetadataService` - Configuration metadata management
- [ ] `mt_ConfigProfilePicklist` - Dynamic configuration profile picklist
- [ ] `mt_FileCombinerService` - File combining and processing
- [ ] `mt_GetObjectConfigForPrompt` - Object configuration for AI prompts
- [ ] `mt_ImageFileService` - Image file handling and ContentDocument creation
- [ ] `mt_ObjectMetadataService` - Dynamic object metadata retrieval
- [ ] `mt_RecordService` - Record CRUD operations
- [ ] `mt_TranscribeController` - Main transcription and AI controller

**Test Classes:**
- [ ] `mt_ConfigMetadataServiceTest`
- [ ] `mt_FileCombinerServiceTest`
- [ ] `mt_GetObjectConfigForPromptTest`
- [ ] `mt_ImageFileServiceTest`
- [ ] `mt_ObjectMetadataServiceTest`
- [ ] `mt_RecordServiceTest`
- [ ] `mt_TranscribeControllerTest`

---

### ✅ Lightning Web Components (4 Components)

- [ ] `mtEinsteinTranscribe` - Main voice input and transcription component
- [ ] `mtRecordSuggestion` - AI-powered record suggestion and editing UI
- [ ] `mtDateInput` - Custom date input component
- [ ] `mtVoiceAssistantAdmin` - Admin setup and configuration page

---

### ✅ Flows (2 Flows)

- [ ] `MT_Visit_Report_MultiModal` - Account-based flow with image support
- [ ] `MT_Visit_Report_Standalone_v2` - Standalone flow for any object

---

### ✅ GenAI Prompt Templates (2 Templates)

- [ ] `MT Voice Account (Multi-Modal)` - Used by MT_Visit_Report_MultiModal flow
- [ ] `MT Voice Standalone (Multi-Modal v2)` - Used by MT_Visit_Report_Standalone_v2 flow

---

### ✅ Custom Metadata Types (3 Types)

**Metadata Type Definitions:**
- [ ] `Einstein Transcribe Settings` - Einstein API configuration
- [ ] `MT Voice Assistant Config` - Application configuration
- [ ] `MT Voice Assistant Object Config` - Object-specific settings

**Metadata Records:**
- [ ] `EinsteinTranscribeSettings.Default` - Default Einstein settings
- [ ] `MT_VoiceAssistantConfig.Default` - Default app configuration
- [ ] `MT_VoiceAssistantObjectConfig.Default_Contact` - Contact configuration
- [ ] `MT_VoiceAssistantObjectConfig.Default_Opportunity` - Opportunity configuration
- [ ] `MT_VoiceAssistantObjectConfig.Default_Task` - Task configuration

---

### ✅ Custom Settings (1 Setting)

- [ ] `MT Voice Assistant Secrets` - Secure storage for API keys

---

### ✅ Custom Permissions (2 Permissions)

- [ ] `mt_IsAIMeetingFollowUpUser` - Meeting follow-up feature access
- [ ] `mt_VoiceAssistant_Admin` - Admin feature access

---

### ✅ Permission Sets (2 Sets)

- [ ] `MT Voice Assistant Admin` - Full admin access
  - Custom Metadata Type Access
  - Custom Setting Access
  - Custom Permissions
  - Tab Visibility
  
- [ ] `MT Voice Assistant User` - End-user access
  - External Credential Access
  - Custom Permissions
  - Tab Visibility

---

### ✅ External Credentials (2 Credentials)

- [ ] `mt_EinsteinTranscribe` - Einstein AI authentication
- [ ] `mt_OpenAI_Whisper` - OpenAI Whisper authentication

---

### ✅ Named Credentials (2 Credentials)

- [ ] `mt_EinsteinTranscribe` - Einstein API endpoint
- [ ] `mt_OpenAI_Whisper` - OpenAI API endpoint

---

### ✅ Connected App (1 App)

- [ ] `MT Einstein Transcribe` - OAuth configuration for Einstein AI

---

### ✅ CSP Trusted Sites (1 Site)

- [ ] `mt_EinsteinTranscribeAPI` - Content Security Policy for Einstein API

---

### ✅ Custom Tab (1 Tab)

- [ ] `MT Voice Assistant Settings` - Admin settings tab

---

### ✅ Page Layouts (2 Layouts)

- [ ] `MT Voice Assistant Config Layout` - Configuration metadata layout
- [ ] `MT Voice Assistant Object Config Layout` - Object config metadata layout

---

## Post-Deployment Configuration Checklist

### 🔧 Required Manual Steps

- [ ] **Update Named Credential URL**
  - Setup → Named Credentials → mt_EinsteinTranscribe
  - Replace URL with your My Domain URL
  
- [ ] **Enable Einstein AI** (if not already enabled)
  - Setup → Einstein → Einstein AI
  - Accept terms and conditions
  
- [ ] **Configure External Credentials** (Optional - for Whisper)
  - Setup → Named Credentials → External Credentials → mt_OpenAI_Whisper
  - Add OpenAI API key
  
- [ ] **Assign Permission Sets**
  - Setup → Users → Permission Sets
  - Assign `MT Voice Assistant User` to end users
  - Assign `MT Voice Assistant Admin` to administrators
  
- [ ] **Access Setup Page**
  - App Launcher → MT Voice Assistant Settings
  - Complete guided setup wizard
  
- [ ] **Test Installation**
  - Navigate to Account record
  - Run MT_Visit_Report_MultiModal flow
  - Test voice transcription
  - Test record creation

---

## Deployment Order (Automated by Script)

1. ✅ Custom Metadata Types & Objects
2. ✅ Custom Permissions
3. ✅ Apex Classes
4. ✅ Lightning Web Components
5. ✅ Page Layouts
6. ✅ Custom Metadata Records
7. ✅ External Credentials
8. ✅ Named Credentials (may require manual config)
9. ✅ CSP Trusted Sites
10. ✅ Connected App (may require manual config)
11. ✅ GenAI Prompt Templates (requires Einstein AI) - **BEFORE Flows**
12. ✅ Flows (depend on prompt templates) - **AFTER Prompt Templates**
13. ✅ Permission Sets
14. ✅ Custom Tab

---

## Verification Steps

### After Deployment, Verify:

- [ ] All Apex classes deployed successfully
- [ ] All LWC components are visible in Setup
- [ ] Flows are active and visible
- [ ] Prompt templates are deployed (if Einstein AI enabled)
- [ ] Permission sets exist and have correct permissions
- [ ] Custom tab appears in App Launcher
- [ ] Named credentials are configured with correct URLs
- [ ] External credentials have principals assigned
- [ ] CSP Trusted Site is active
- [ ] Test flow execution works end-to-end

---

## Troubleshooting Reference

| Issue | Solution |
|-------|----------|
| GenAI Prompt Templates failed | Enable Einstein AI in Setup |
| Named Credentials failed | Manual configuration required - see guide |
| Connected App failed | Manual configuration required - see guide |
| Permission sets not working | Re-assign to users |
| Flow errors | Check Apex class deployment status |
| LWC not visible | Verify permission set assignments |

---

## Success Criteria

✅ All components deployed without critical errors  
✅ Permission sets assigned to users  
✅ Named credentials configured  
✅ Setup page accessible  
✅ Test flow executes successfully  
✅ Voice transcription works  
✅ Record creation works  
✅ Image upload works (mobile)  

---

## Support

📧 **Email:** mtietze@salesforce.com  
📖 **Documentation:** DEPLOYMENT_GUIDE.md  
🚀 **Quick Start:** QUICK_START.md  

---

**Last Updated:** December 2025  
**Version:** 1.0

