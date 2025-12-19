# AI Agent Phone Call Visit Reports

## Overview

The MT Voice Assistant now supports **AI Agent phone call integration** for creating visit reports. Sales people can call a dedicated phone number, dictate their visit report details to an AI Agent, and the system automatically processes the information in the background. Users receive a notification when their report is ready for review on the Account page.

---

## How It Works

### User Journey

1. **Sales person calls the AI Agent** phone number
2. **Agent asks:** "Which customer is this visit report for?"
3. **Sales person responds:** "Acme Corporation"
4. **Agent confirms:** "Great! Tell me about your meeting."
5. **Sales person dictates** visit details (attendees, outcomes, next steps)
6. **Agent creates draft** in Salesforce with Status = "New"
7. **Background flow processes** the transcript through GenAI prompt
8. **User receives notification:** "Visit Report Ready for Review"
9. **User clicks notification** → Navigates to Account page
10. **User opens "Visit Reports" tab** → Sees pending draft
11. **User clicks "Review"** → Modal opens with suggested records
12. **User approves/edits** records → Clicks "Save All"
13. **Draft status updates** to "Processed"

---

## Components Created

### 1. Custom Object: `MT_Visit_Report_Draft__c`
Stores AI Agent conversation transcripts and processed JSON for review.

**Key Fields:**
- `Status__c`: New → Processing → Ready → Processed/Rejected
- `Transcript__c`: Raw conversation from AI Agent
- `Prompt_Response_JSON__c`: GenAI output with suggested records
- `Account__c`: Customer account (required)
- `Summary__c`: AI-generated summary
- `Reasoning__c`: AI explanation

### 2. Apex Class: `mt_VisitReportService`
Backend service for draft management.

**Methods:**
- `getDraftsForAccount()`: Query drafts for an Account
- `updateDraftStatus()`: Mark draft as Processed/Rejected
- `findAccountByName()`: Search accounts for AI Agent
- `parsePromptResponse()`: Extract Summary/Reasoning from JSON
- `getMyPendingDrafts()`: Get current user's pending drafts

### 3. Test Class: `mt_VisitReportServiceTest`
Comprehensive test coverage (75%+) for all service methods.

### 4. Custom Notification Type: `MT_Visit_Report_Ready`
Bell notification sent when draft is ready for review.

### 5. Record-Triggered Flow: `MT_Process_Visit_Report_Draft`
Automatically processes drafts when created by AI Agent.

**Flow Steps:**
1. Update Status → "Processing"
2. Get Account details
3. Get Object Config (Default profile)
4. Call GenAI Prompt Template
5. Parse JSON response
6. Update Draft with results (Status → "Ready")
7. Send bell notification to user
8. Error handling (reset to "New" on failure)

### 6. LWC Component: `mtVisitReportQueue`
Displays pending drafts on Account page with review modal.

**Features:**
- Shows list of drafts with Status = "Ready"
- Displays: Draft #, Created Date, Summary
- Actions: Review (opens modal), Reject
- Modal contains `mtRecordSuggestion` component
- Auto-refreshes after save/reject

### 7. Permission Set Updates: `mt_VoiceAssistant_User`
Added permissions for:
- `MT_Visit_Report_Draft__c` (CRUD)
- `mt_VisitReportService` (Apex class)
- `MT_Visit_Report_Ready` (Custom notification)

---

## Setup Instructions

### For Salesforce Admins

1. **Deploy all components** to your org (already included in the package)
2. **Assign permission set** `mt_VoiceAssistant_User` to sales users
3. **Add "Visit Reports" tab** to Account record page:
   - Edit Account page in Lightning App Builder
   - Add new tab: "Visit Reports"
   - Drag `mtVisitReportQueue` component into tab
   - Save and activate
4. **Configure Agentforce AI Agent** (see `AGENTFORCE_CONFIGURATION.md`)

### For Agentforce Admins

Follow the detailed guide in `AGENTFORCE_CONFIGURATION.md` to:
1. Create Voice Agent
2. Add Apex actions (`findAccountByName`, create draft)
3. Design conversation flow
4. Test the integration

---

## Usage Examples

### Example 1: Simple Visit Report

**User:** "I need to create a visit report for Acme Corporation"  
**Agent:** "Great! Tell me about your meeting."  
**User:** "I met with John Smith. We discussed the Q1 renewal worth $100K. I need to send a proposal by Friday."  
**Agent:** "Your visit report has been created. You'll receive a notification when it's ready."

**Result:**
- Draft created with transcript
- Flow processes → Suggests: Contact (John Smith), Opportunity ($100K), Task (Send proposal by Friday)
- User reviews → Saves all records
- Draft marked as Processed

### Example 2: Multiple Attendees

**User:** "Visit report for Beta Industries"  
**Agent:** "Tell me about your meeting."  
**User:** "I met with Sarah Johnson and Mike Chen. We discussed expanding to 50 more licenses. Sarah wants a demo next week. Mike needs pricing by Tuesday."  
**Agent:** "Got it. Your report is being processed."

**Result:**
- Suggests: 2 Contacts (Sarah, Mike), 1 Opportunity (50 licenses), 2 Tasks (demo, pricing)

---

## Account Page Tab

The **Visit Reports** tab on the Account page shows:

| Draft # | Created | Summary | Actions |
|---------|---------|---------|---------|
| VR-0001 | Dec 18, 2:30 PM | Met with John Smith, discussed Q1... | [Review] [Reject] |
| VR-0002 | Dec 18, 3:15 PM | Meeting with Sarah Johnson and... | [Review] [Reject] |

**Review Button:** Opens modal with `mtRecordSuggestion` component  
**Reject Button:** Marks draft as Rejected (no records created)

---

## Notification Behavior

When a draft is ready:
1. **Bell icon** (🔔) shows red dot
2. **Notification title:** "Visit Report Ready for Review"
3. **Notification body:** "Your visit report for [Account Name] is ready to review."
4. **Click notification:** Navigates to Account record page
5. **User manually opens** "Visit Reports" tab
6. **Sees pending draft** in the queue

---

## Troubleshooting

### Draft Stuck in "Processing"
- Check Flow runs: Setup → Process Automation → Flow → View Runs
- Verify GenAI Prompt Template is published
- Check debug logs for errors

### No Notification Received
- Verify user has `mt_VoiceAssistant_User` permission set
- Check custom notification type is enabled
- Verify `Created_By_User__c` field is populated

### Visit Reports Tab Not Showing
- Edit Account page in Lightning App Builder
- Add `mtVisitReportQueue` component manually
- Verify page is assigned to user's profile

### Agent Can't Find Account
- Check `findAccountByName` Apex method
- Verify agent user has Read access to Account
- Try using exact account name

---

## Files Created

```
force-app/main/default/
├── objects/MT_Visit_Report_Draft__c/
│   ├── MT_Visit_Report_Draft__c.object-meta.xml
│   ├── fields/*.field-meta.xml (10 fields)
│   ├── validationRules/*.validationRule-meta.xml (2 rules)
│   └── layouts/MT_Visit_Report_Draft__c-Layout.layout-meta.xml
├── classes/
│   ├── mt_VisitReportService.cls
│   ├── mt_VisitReportService.cls-meta.xml
│   ├── mt_VisitReportServiceTest.cls
│   └── mt_VisitReportServiceTest.cls-meta.xml
├── lwc/mtVisitReportQueue/
│   ├── mtVisitReportQueue.js
│   ├── mtVisitReportQueue.html
│   ├── mtVisitReportQueue.css
│   └── mtVisitReportQueue.js-meta.xml
├── flows/
│   └── MT_Process_Visit_Report_Draft.flow-meta.xml
├── notificationtypes/
│   └── MT_Visit_Report_Ready.notiftype-meta.xml
└── permissionsets/
    └── mt_VoiceAssistant_User.permissionset-meta.xml (updated)
```

---

## Next Steps

1. **Deploy to your org** (already included in package)
2. **Configure Agentforce** (see `AGENTFORCE_CONFIGURATION.md`)
3. **Test with a pilot group** of sales users
4. **Gather feedback** and iterate on agent instructions
5. **Roll out to all sales teams**

---

## Support

- **Email:** mtietze@salesforce.com
- **GitHub:** [MT-Visit-Report](https://github.com/Tietziano90/MT-Visit-Report)
- **Documentation:** See `AGENTFORCE_CONFIGURATION.md` for detailed setup

---

**Version:** 1.0  
**Last Updated:** December 2025  
**Author:** Michael Tietze, Principal AI Architect



