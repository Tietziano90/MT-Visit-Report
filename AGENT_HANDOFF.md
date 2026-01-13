# 🤖 Agent Handoff Documentation
## MT Voice Assistant - Visit Report Application

---

## 📋 Project Overview

This is a Salesforce Voice Assistant application that processes voice transcripts from customer visits and automatically creates/updates Salesforce records (Contacts, Opportunities, Tasks, Events, Leads).

**Two Versions Exist:**
1. **Original Version** (Manual Entry) - User manually reviews and saves records
2. **Draft Version** (Agentic) - AI agent automatically creates drafts for review

---

## 📂 Repository Structure

### **IMPORTANT: Two Separate Folders**

#### 1️⃣ Original Version (Manual Entry)
```
📁 /Users/mtietze/Documents/Voice Assistant/Voice Assistant Visit Report
```
- **GitHub Repo:** `MT-Visit-Report` (existing)
- **Purpose:** Manual record creation workflow
- **Deployment:** Uses `deploy-voice-assistant.sh` script
- **Status:** ✅ Clean and working
- **Key Components:**
  - `MT_Visit_Report_MultiModal` flow (manual entry)
  - `mtRecordSuggestion` LWC (record creation UI)
  - `mtEinsteinTranscribe` LWC (voice recording)
  - `mtVoiceAssistantAdmin` LWC (setup page)
  - Prompt templates: `MT_Voice_Account_MultiModal`, `MT_Voice_Standalone_MultiModal_v2`

#### 2️⃣ Draft Version (Agentic)
```
📁 /Users/mtietze/Documents/Voice Assistant/Voice Assistant Visit Report - Draft Version
```
- **GitHub Repo:** `MT-Visit-Report-Draft` (new, ready to push)
- **Purpose:** AI agent creates drafts automatically
- **Deployment:** TBD (needs deployment script)
- **Status:** ✅ All components copied, ready for development
- **Additional Components:**
  - `MT_Visit_Report_Draft__c` custom object
  - `mtVisitReportManager` LWC (draft review/processing)
  - `mtVisitReportQueue` LWC (account-specific draft queue)
  - `MT_Process_Visit_Report_Draft_V2` flow (auto-processing)
  - Agent Apex classes:
    - `mt_AgentFindAccount` - Find account by name
    - `mt_AgentCreateDraft` - Create draft records
    - `mt_VisitReportService` - Draft management & JSON parsing
  - `MT_Visit_Report_Ready` notification type

---

## 🎯 Key Features

### Original Version (Manual)
1. User records voice transcript
2. AI generates JSON with suggested records
3. User manually reviews and selects fields
4. User clicks "Save All" to create records

### Draft Version (Agentic)
1. Agent invokes `mt_AgentCreateDraft` with transcript
2. Draft record created with status "Pending"
3. `MT_Process_Visit_Report_Draft_V2` flow triggers (async):
   - Calls Einstein AI
   - Parses JSON response
   - Updates draft with Summary/Reasoning
   - Sets status to "Ready"
   - Sends notification to System Admins
4. Admin reviews draft in `mtVisitReportManager`
5. Admin clicks "Review & Process" to see suggested records
6. Admin saves records, clicks "Confirm & Complete"
7. Draft moves to "Processed" status

---

## 🔧 Technical Architecture

### AI Integration
- **Einstein AI:** GenAI Prompt Templates with Claude 3.5 Sonnet
- **Named Credential:** `mt_EinsteinTranscribe`
- **Prompt Templates:**
  - `MT_Voice_Account_MultiModal` (account-focused)
  - `MT_Voice_Standalone_MultiModal_v2` (standalone)

### Key Apex Classes
- `mt_VisitReportService` - Draft management, JSON parsing
- `mt_AgentFindAccount` - Account lookup for agents
- `mt_AgentCreateDraft` - Draft creation for agents

### Key LWCs
- `mtRecordSuggestion` - Dynamic record creation from JSON
- `mtVisitReportManager` - Draft review interface (tabs: Pending/Processed)
- `mtVisitReportQueue` - Account-specific draft list
- `mtEinsteinTranscribe` - Voice recording component

### Flows
- `MT_Visit_Report_MultiModal` - Original manual flow
- `MT_Process_Visit_Report_Draft_V2` - Async draft processing flow

---

## ⚠️ Critical Issues & Solutions

### 1. JSON Parsing Errors
**Problem:** AI wraps JSON in markdown code fences (` ```json `)

**Solution:** Prompt templates explicitly instruct:
```
CRITICAL: Return ONLY raw JSON. Do NOT wrap in markdown code fences.
Do NOT use ```json or ``` anywhere in your response.
```

### 2. Missing AccountId in Records
**Problem:** Records created without AccountId, not linked to account

**Solution:** Prompt template includes explicit instructions:
```
For Contacts/Opportunities: "AccountId": "{!$Input:Account.Id}"
For Tasks/Events: "WhatId": "{!$Input:Account.Id}"
```

### 3. Draft Not Moving to Processed Tab
**Problem:** Saving records didn't update draft status

**Solution:** Added "Confirm & Complete" button that explicitly:
```javascript
handleMarkAsProcessed() {
    // Update draft status to 'Processed'
    // Refresh both pending and processed lists
    // Close modal
}
```

### 4. Notification Issues
**Problem:** Flow used API name instead of ID for notification type

**Solution:** Use actual ID in flow:
```xml
<customNotifTypeId>0MLKj000000TVv8OAG</customNotifTypeId>
```

### 5. Asynchronous Processing
**Problem:** Agent waits 20+ seconds for flow to complete

**Solution:** Flow configured with:
```xml
<processMetadataValues>
    <name>TriggerType</name>
    <value><stringValue>AsyncAfterCommit</stringValue></value>
</processMetadataValues>
```

---

## 🚀 Deployment

### Original Version
```bash
cd "/Users/mtietze/Documents/Voice Assistant/Voice Assistant Visit Report"
./deploy-voice-assistant.sh
```

**Manual Steps After Deployment:**
1. Configure Named Credential URL (Setup → Named Credentials)
2. Enable Einstein AI
3. Activate flows manually (CLI can't activate flows)
4. Assign permission sets to users

### Draft Version
- **Status:** Not yet deployed to production
- **Next Steps:** Create deployment script similar to original version
- **GitHub:** Ready to push to `MT-Visit-Report-Draft` repo

---

## 📝 Important Notes for Future Agents

### DO NOT Mix Repositories
- Keep Original and Draft versions completely separate
- Original repo should NOT contain any Draft components
- Draft repo contains ALL components (original + draft)

### Files to Watch
- **Prompt Templates:** Frequently updated, always retrieve latest from org before deploying
- **Flows:** Must be activated manually in UI (CLI limitation)
- **Permission Sets:** Check for references to tabs/objects before deploying

### Common Pitfalls
1. ❌ Don't deploy Draft components with Original deployment script
2. ❌ Don't use API names for notification types (use IDs)
3. ❌ Don't forget to make flows asynchronous for long-running AI calls
4. ❌ Don't assume JSON is clean (AI may add markdown formatting)
5. ❌ Don't forget AccountId/WhatId in prompt instructions

### Testing Checklist
- [ ] Voice recording works
- [ ] AI generates valid JSON
- [ ] Records save with correct AccountId
- [ ] Notifications sent to admins
- [ ] Draft moves to Processed after confirmation
- [ ] Both tabs (Pending/Processed) refresh correctly
- [ ] Account page shows filtered drafts

---

## 🔗 Key Resources

### Salesforce Orgs
- **VisitReportOrg** - Development/testing org for Draft version
- **TestTemp** - Testing org for Original version deployment

### GitHub Repositories
- **MT-Visit-Report** - Original version (manual entry)
- **MT-Visit-Report-Draft** - Draft version (agentic)

### Contact
- **Developer:** mtietze@salesforce.com

---

## 🎯 Current Status (as of Dec 19, 2025)

### ✅ Completed
- Original version deployment script working
- Draft version components fully developed
- All UI/UX improvements implemented
- JSON parsing issues resolved
- AccountId linking fixed
- Asynchronous processing configured
- Notification system working
- Separate repositories created

### 🔄 In Progress
- Testing Draft version in production org
- Creating deployment script for Draft version

### 📋 Pending
- Documentation for Draft version deployment
- User training materials
- Performance monitoring setup

---

## 💡 Quick Start for New Agent

1. **Understand the two versions:**
   - Original = Manual entry workflow
   - Draft = Agentic workflow with review

2. **Check which folder you're in:**
   ```bash
   pwd
   # Should show either:
   # .../Voice Assistant Visit Report (Original)
   # .../Voice Assistant Visit Report - Draft Version (Draft)
   ```

3. **Read the error messages carefully:**
   - Deployment errors often indicate wrong folder or mixed components
   - Flow errors often indicate missing activation or wrong API names
   - JSON errors often indicate AI formatting issues

4. **Always retrieve latest from org before deploying:**
   ```bash
   sf project retrieve start --metadata GenAiPromptTemplate:MT_Voice_Account_MultiModal
   sf project retrieve start --metadata Flow:MT_Process_Visit_Report_Draft_V2
   ```

5. **Test in sandbox first:**
   - Never deploy untested changes to production
   - Use VisitReportOrg for Draft version testing
   - Use TestTemp for Original version testing

---

**Good luck! 🚀**

