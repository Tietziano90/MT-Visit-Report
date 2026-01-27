# MT Voice Assistant - Component Tree

## 📦 Core Components

### 🎯 Flows (3)
```
flows/
├── MT_Visit_Report_MultiModal.flow-meta.xml              # Account-based flow
├── MT_Visit_Report_MultiModal_Advanced.flow-meta.xml     # Advanced account-based flow
└── MT_Visit_Report_Standalone_v2.flow-meta.xml           # Standalone flow (no account)
```

### 🤖 GenAI Prompt Templates (4)
```
genAiPromptTemplates/
├── MT_Account_Finder_Advanced.genAiPromptTemplate-meta.xml           # Account detection
├── MT_Voice_Account_MultiModal.genAiPromptTemplate-meta.xml          # Account-based extraction
├── MT_Voice_Account_MultiModal_Advanced.genAiPromptTemplate-meta.xml # Advanced extraction
└── MT_Voice_Standalone_MultiModal_v2.genAiPromptTemplate-meta.xml    # Standalone extraction
```

### ⚡ Lightning Web Components (4)
```
lwc/
├── mtDateInput/                    # Date picker component
│   ├── mtDateInput.js
│   ├── mtDateInput.html
│   └── mtDateInput.css
├── mtEinsteinTranscribe/           # Voice recording & transcription
│   ├── mtEinsteinTranscribe.js
│   ├── mtEinsteinTranscribe.html
│   ├── mtEinsteinTranscribe.css
│   └── audioVisualisationHelper.js
├── mtRecordSuggestion/             # AI record suggestions display
│   ├── mtRecordSuggestion.js
│   ├── mtRecordSuggestion.html
│   └── mtRecordSuggestion.css
└── mtVoiceAssistantAdmin/          # Admin settings UI
    ├── mtVoiceAssistantAdmin.js
    ├── mtVoiceAssistantAdmin.html
    └── mtVoiceAssistantAdmin.css
```

### 🔧 Apex Classes (14)
```
classes/
├── mt_AccountFinderParser.cls              # Parse account detection JSON
├── mt_ConfigMetadataService.cls            # Metadata configuration service
├── mt_ConfigProfilePicklist.cls            # Config profile picklist
├── mt_FileCombinerService.cls              # Combine multiple files
├── mt_GetObjectConfigForPrompt.cls         # Generate object config for prompts
├── mt_ImageFileService.cls                 # Handle image uploads
├── mt_ObjectMetadataService.cls            # Object metadata operations
├── mt_RecordService.cls                    # Record CRUD operations
└── mt_TranscribeController.cls             # Main transcription controller
    └── (+ 5 test classes)
```

## ⚙️ Configuration Components

### 📊 Custom Metadata Types (2)
```
objects/
├── MT_VoiceAssistantConfig__mdt/           # Main configuration
│   └── fields/
│       ├── DefaultSpokenLanguage__c
│       ├── DefaultTranscriptionLanguage__c
│       ├── AllowLanguageOverride__c
│       ├── TranscriptionEndpoint__c
│       ├── TranscriptionEngine__c
│       ├── EnableDiarization__c
│       ├── TranscriptionModel__c
│       ├── EinsteinNamedCredential__c
│       ├── EnableImageInput__c
│       └── PromptTemplateName__c
├── MT_VoiceAssistantObjectConfig__mdt/     # Object-level configuration
│   └── fields/
│       ├── ObjectApiName__c
│       ├── AllowCreate__c
│       ├── AllowEdit__c
│       ├── AllowedFields__c
│       └── MandatoryFields__c
└── EinsteinTranscribeSettings__mdt/        # Einstein API settings
    └── fields/
        └── EinsteinTranscribeBaseURL__c
```

### 📝 Custom Metadata Records (8)
```
customMetadata/
├── MT_VoiceAssistantConfig.Default.md-meta.xml
├── MT_VoiceAssistantConfig.Standalone.md-meta.xml
├── MT_VoiceAssistantObjectConfig.Default_Contact.md-meta.xml
├── MT_VoiceAssistantObjectConfig.Default_Opportunity.md-meta.xml
├── MT_VoiceAssistantObjectConfig.Default_Task.md-meta.xml
├── MT_VoiceAssistantObjectConfig.Standalone_Lead.md-meta.xml
├── MT_VoiceAssistantObjectConfig.Standalone_Task.md-meta.xml
└── EinsteinTranscribeSettings.Default.md-meta.xml
```

## 🔐 Security & Integration

### 🔑 Named Credentials (2)
```
namedCredentials/
├── mt_EinsteinTranscribe.namedCredential-meta.xml    # Einstein API
└── mt_OpenAI_Whisper.namedCredential-meta.xml        # OpenAI Whisper API
```

### 🌐 External Credentials (2)
```
externalCredentials/
├── mt_EinsteinTranscribe.externalCredential-meta.xml
└── mt_OpenAI_Whisper.externalCredential-meta.xml
```

### 🔒 Connected Apps (1)
```
connectedApps/
└── mt_Einstein_Transcribe.connectedApp-meta.xml
```

### 🛡️ CSP Trusted Sites (1)
```
cspTrustedSites/
└── mt_EinsteinTranscribeAPI.cspTrustedSite-meta.xml
```

### 🎫 Custom Permissions (2)
```
customPermissions/
├── mt_VoiceAssistant_Admin.customPermission-meta.xml
└── mt_IsAIMeetingFollowUpUser.customPermission-meta.xml
```

### 👥 Permission Sets (2)
```
permissionsets/
├── mt_VoiceAssistant_Admin.permissionset-meta.xml
└── mt_VoiceAssistant_User.permissionset-meta.xml
```

## 🎨 UI Components

### 🏷️ Custom Labels (1)
```
labels/
└── CustomLabels.labels-meta.xml               # English & German translations
    ├── MT_Language_SpokenLanguage
    ├── MT_Language_TranscriptionLanguage
    ├── MT_Language_Auto
    ├── MT_Button_Save
    ├── MT_Button_Edit
    └── MT_Badge_New
```

### 📄 Page Layouts (2)
```
layouts/
├── MT_VoiceAssistantConfig__mdt-MT Voice Assistant Config Layout.layout-meta.xml
└── MT_VoiceAssistantObjectConfig__mdt-MT Voice Assistant Object Config Layout.layout-meta.xml
```

### 📑 Custom Tabs (1)
```
tabs/
└── MT_Voice_Assistant_Settings.tab-meta.xml
```

## 📈 Deployment Order

1. **Custom Metadata Types & Objects** (foundation)
2. **Custom Permissions** (security)
3. **Apex Classes** (business logic)
4. **Custom Labels** (i18n)
5. **Lightning Web Components** (UI)
6. **Page Layouts** (metadata UI)
7. **Custom Metadata Records** (configuration data)
8. **External Credentials** (auth)
9. **Named Credentials** (API connections)
10. **CSP Trusted Sites** (security)
11. **Connected App** (OAuth)
12. **GenAI Prompt Templates** (AI prompts) - **Must be activated manually**
13. **Custom Tab** (navigation)
14. **Flows** (orchestration)
15. **Permission Sets** (access control)

---

## 🚀 Quick Start

### Deployment
```bash
curl -sL https://raw.githubusercontent.com/Tietziano90/MT-Visit-Report/main/deploy-voice-assistant.sh | bash
```

### Post-Deployment
1. **Activate Prompt Templates** (Setup → Prompt Templates)
2. **Configure Named Credentials** (Setup → Named Credentials)
3. **Assign Permission Sets** (Setup → Permission Sets)
4. **Test on Account Record** (Run flow from Account page)

---

**Total Components:** 168 files across 87 directories

**Author:** Michael Tietze (mtietze@salesforce.com)  
**Version:** 1.5  
**Last Updated:** January 2026
