# 📦 MT Voice Assistant - Deployment Manifest

**Version:** Original (Manual Entry)  
**Last Updated:** December 19, 2025  
**Deployment Script:** `deploy.sh`

---

## 🎯 Overview

This manifest lists **ALL** components deployed by the `deploy.sh` script. This is the **original manual entry version** without the Visit Report Draft features.

---

## 📋 Complete Component List

### STEP 1: Custom Metadata Types & Objects (20 components)

#### MT_VoiceAssistantConfig__mdt (Configuration Profiles)
- Object definition
- `Description__c`
- `EinsteinNamedCredential__c`
- `EnableImageInput__c`
- `IsActive__c`
- `PromptTemplateName__c`
- `ShowProviderSelector__c`
- `TranscriptionProvider__c`
- `WhisperModel__c`
- `WhisperNamedCredential__c`

#### MT_VoiceAssistantObjectConfig__mdt (Object Configurations)
- Object definition
- `AllowCreate__c`
- `AllowEdit__c`
- `AllowedFields__c`
- `ConfigProfile__c`
- `MandatoryFields__c`
- `ObjectApiName__c`

#### EinsteinTranscribeSettings__mdt
- Object definition
- `EinsteinTranscribeBaseURL__c`

#### MT_VoiceAssistantSecrets__c (Custom Setting)
- Object definition
- `OpenAI_API_Key__c`

---

### STEP 2: Custom Permissions (2 components)

- `mt_IsAIMeetingFollowUpUser`
- `mt_VoiceAssistant_Admin`

---

### STEP 3: Apex Classes (15 classes + 15 test classes = 30 files)

#### Core Services
1. **`mt_ConfigMetadataService`** - Manages configuration metadata
   - `mt_ConfigMetadataServiceTest`

2. **`mt_TranscribeController`** - Handles transcription requests
   - `mt_TranscribeControllerTest`

3. **`mt_RecordService`** - Creates/updates Salesforce records
   - `mt_RecordServiceTest`

4. **`mt_ObjectMetadataService`** - Retrieves object metadata
   - `mt_ObjectMetadataServiceTest`

5. **`mt_GetObjectConfigForPrompt`** - Prepares config for AI prompts
   - `mt_GetObjectConfigForPromptTest`

6. **`mt_FileCombinerService`** - Combines transcript and image files
   - `mt_FileCombinerServiceTest`

7. **`mt_ImageFileService`** - Handles image file operations
   - `mt_ImageFileServiceTest`

8. **`mt_ConfigProfilePicklist`** - Dynamic picklist for config profiles

---

### STEP 4: Lightning Web Components (6 components)

1. **`mtDateInput`** - Custom date input component
   - Used by: `mtRecordSuggestion`

2. **`mtRecordSuggestion`** - Record review and editing interface
   - Used by: `mtEinsteinTranscribe`
   - Dependencies: `mtDateInput`

3. **`mtEinsteinTranscribe`** - Main transcription interface
   - Audio recording
   - Image upload
   - AI-powered record generation
   - Dependencies: `mtRecordSuggestion`, `mtDateInput`

4. **`mtVoiceAssistantAdmin`** - Setup and configuration page
   - Configuration wizard
   - Credential setup
   - Testing interface

5. **`mtEinsteinTranscribeAdvanced`** - Advanced transcription features
   - Extended functionality
   - Additional options

6. **`mtVoiceAssistantAdvanced`** - Advanced admin features
   - Extended configuration
   - Advanced settings

---

### STEP 5: Page Layouts (3 layouts)

1. `MT_VoiceAssistantConfig__mdt` - Config profile layout
2. `MT_VoiceAssistantObjectConfig__mdt` - Object config layout
3. `MT_Visit_Report_Draft__c` - Draft layout (legacy, not used)

---

### STEP 6: Custom Metadata Records (8 records)

#### Configuration Profiles
1. **`EinsteinTranscribeSettings.Default`** - Einstein transcribe settings
2. **`MT_VoiceAssistantConfig.Default`** - Account-based configuration
3. **`MT_VoiceAssistantConfig.Standalone`** - Standalone configuration

#### Object Configurations (Default Profile)
4. **`MT_VoiceAssistantObjectConfig.Default_Contact`**
5. **`MT_VoiceAssistantObjectConfig.Default_Opportunity`**
6. **`MT_VoiceAssistantObjectConfig.Default_Task`**

#### Object Configurations (Standalone Profile)
7. **`MT_VoiceAssistantObjectConfig.Standalone_Lead`**
8. **`MT_VoiceAssistantObjectConfig.Standalone_Task`**

---

### STEP 7: External Credentials (2 credentials)

1. **`mt_EinsteinTranscribe`** - For Einstein AI API
2. **`mt_OpenAI_Whisper`** - For OpenAI Whisper API

---

### STEP 8: Named Credentials (2 credentials)

1. **`mt_EinsteinTranscribe`** - Einstein transcription endpoint
   - **Post-Deployment:** Update URL with org's My Domain

2. **`mt_OpenAI_Whisper`** - OpenAI Whisper endpoint
   - **Post-Deployment:** Configure API key

---

### STEP 9: CSP Trusted Sites (1 site)

1. **`mt_EinsteinTranscribeAPI`** - Allows Einstein API calls

---

### STEP 10: Connected App (1 app)

1. **`mt_Einstein_Transcribe`** - OAuth for Einstein API
   - **Post-Deployment:** May require manual configuration

---

### STEP 11: GenAI Prompt Templates (2 templates)

1. **`MT_Voice_Account_MultiModal`** - Account-based AI prompt
   - Used for: Account record page transcriptions
   - Supports: Audio + Image input
   - Creates: Contacts, Opportunities, Tasks, Events

2. **`MT_Voice_Standalone_MultiModal_v2`** - Standalone AI prompt
   - Used for: Standalone transcriptions
   - Supports: Audio + Image input
   - Creates: Leads, Tasks, Events

---

### STEP 12: Custom Tabs (1 tab)

1. **`MT_Voice_Assistant_Settings`** - Setup page tab
   - Opens: `mtVoiceAssistantAdmin` component

---

### STEP 13: Flows (2 flows)

1. **`MT_Visit_Report_MultiModal`** - Account-based flow
   - Triggered from: Account record pages
   - Calls: Einstein AI with account context
   - Creates: Records linked to account

2. **`MT_Visit_Report_Standalone_v2`** - Standalone flow
   - Triggered from: Anywhere
   - Calls: Einstein AI without account context
   - Creates: Independent records (Leads, Tasks)

---

### STEP 14: Permission Sets (2 sets)

1. **`mt_VoiceAssistant_Admin`** - Full admin access
   - All objects (Read/Create/Edit)
   - All Apex classes
   - All LWCs
   - All custom permissions
   - Setup page access

2. **`mt_VoiceAssistant_User`** - Standard user access
   - Limited object access
   - Transcription features
   - Record creation

---

## 📊 Component Summary

| Category | Count | Notes |
|----------|-------|-------|
| **Apex Classes** | 15 | + 15 test classes |
| **LWC Components** | 6 | Includes admin and transcribe |
| **Flows** | 2 | Account-based + Standalone |
| **Custom Tabs** | 1 | Setup page |
| **Prompt Templates** | 2 | Account + Standalone |
| **Named Credentials** | 2 | Einstein + OpenAI |
| **External Credentials** | 2 | Einstein + OpenAI |
| **Permission Sets** | 2 | Admin + User |
| **Custom Metadata Types** | 4 | Config + Object Config + Settings + Secrets |
| **Custom Metadata Records** | 8 | 2 configs + 6 object configs |
| **Custom Permissions** | 2 | Admin + User |
| **CSP Trusted Sites** | 1 | Einstein API |
| **Connected Apps** | 1 | Einstein OAuth |
| **Page Layouts** | 3 | Metadata layouts |

**Total Components:** ~100+ files

---

## 🚫 What's NOT Included (Draft Version Components)

The following components are **NOT** deployed by this script (they're in the separate Draft repo):

- ❌ `MT_Visit_Report_Draft__c` object
- ❌ `mtVisitReportManager` LWC
- ❌ `mtVisitReportQueue` LWC
- ❌ `mtVisitReportRelatedRecords` LWC
- ❌ `MT_Process_Visit_Report_Draft_V2` flow
- ❌ `mt_VisitReportService` Apex class
- ❌ `mt_AgentFindAccount` Apex class
- ❌ `mt_AgentCreateDraft` Apex class
- ❌ Visit Report Manager app
- ❌ Visit Report notifications
- ❌ Agent-related components

---

## 🔄 Deployment Order

The `deploy.sh` script deploys components in this specific order to handle dependencies:

1. **Objects & Metadata Types** (foundation)
2. **Custom Permissions** (security)
3. **Apex Classes** (business logic)
4. **LWCs** (UI components, in dependency order)
5. **Page Layouts** (UI configuration)
6. **Custom Metadata Records** (configuration data)
7. **External Credentials** (authentication)
8. **Named Credentials** (API endpoints)
9. **CSP Trusted Sites** (security)
10. **Connected App** (OAuth)
11. **Prompt Templates** (AI configuration)
12. **Custom Tab** (navigation)
13. **Flows** (automation)
14. **Permission Sets** (access control)

---

## ✅ Post-Deployment Checklist

After running `deploy.sh`, complete these manual steps:

### 1. Configure Named Credentials
- [ ] Setup → Named Credentials → `mt_EinsteinTranscribe`
- [ ] Update URL with your org's My Domain
- [ ] Setup → Named Credentials → `mt_OpenAI_Whisper`
- [ ] Configure API key (if using OpenAI)

### 2. Enable Einstein AI
- [ ] Setup → Einstein → Einstein AI
- [ ] Enable Einstein features

### 3. Configure OpenAI (Optional)
- [ ] Setup → Custom Settings → MT Voice Assistant Secrets
- [ ] Add OpenAI API Key

### 4. Access Setup Page
- [ ] App Launcher → MT Voice Assistant Settings
- [ ] Follow guided setup wizard
- [ ] Test transcription
- [ ] Test record creation

### 5. Assign Permission Sets
- [ ] Assign `mt_VoiceAssistant_Admin` to admins
- [ ] Assign `mt_VoiceAssistant_User` to users

### 6. Test Installation
- [ ] Navigate to Account record
- [ ] Run `MT_Visit_Report_MultiModal` flow
- [ ] Test audio recording
- [ ] Test image upload
- [ ] Verify record creation

---

## 📞 Support

**Author:** Michael Tietze, Principal AI Architect  
**Email:** mtietze@salesforce.com  
**Repository:** MT Voice Assistant (Original Version)

---

**Last Updated:** December 19, 2025





