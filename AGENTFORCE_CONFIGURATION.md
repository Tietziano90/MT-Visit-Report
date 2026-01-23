# Agentforce AI Agent Configuration Guide

## Overview

This guide explains how to configure an Agentforce AI Agent to work with the MT Voice Assistant Visit Report system. The AI Agent will handle phone calls from sales people, collect visit report information, and automatically create draft records in Salesforce for review.

---

## Prerequisites

1. **Salesforce Agentforce** license and access
2. **Phone number** provisioned for Agentforce voice calls
3. **MT Voice Assistant** fully deployed to your org
4. **System Administrator** or **Agentforce Administrator** permissions

---

## Architecture Overview

```
Sales Person → Phone Call → Agentforce AI Agent → Salesforce API
                                                       ↓
                                          MT_Visit_Report_Draft__c (Status=New)
                                                       ↓
                                          Record-Triggered Flow (Auto-runs)
                                                       ↓
                                          GenAI Prompt Processing
                                                       ↓
                                          Draft Updated (Status=Ready)
                                                       ↓
                                          Bell Notification Sent
                                                       ↓
                                          User Reviews on Account Page
```

---

## Step 1: Create Agentforce AI Agent

### 1.1 Navigate to Agentforce Setup
1. Go to **Setup** → Search for "**Agentforce**"
2. Click **Agents** → **New Agent**
3. Select **Voice Agent** as the agent type

### 1.2 Configure Basic Settings
- **Agent Name:** `Visit Report Voice Assistant`
- **Description:** `AI Agent for creating visit reports via phone calls`
- **Language:** English (or your preferred language)
- **Voice:** Select a natural-sounding voice (e.g., "Neural Voice - Female")

### 1.3 Assign Phone Number
1. In the agent settings, go to **Phone Numbers** tab
2. Click **Add Phone Number**
3. Select your provisioned phone number
4. Save the configuration

---

## Step 2: Configure Agent Actions

The AI Agent needs access to specific Salesforce actions to create draft records and query accounts.

### 2.1 Add "Find Account by Name" Action

**Purpose:** Allow the agent to search for accounts when the user says a customer name.

1. In the agent builder, go to **Actions** tab
2. Click **Add Action** → **Apex Action**
3. Select the Apex class: `mt_VisitReportService`
4. Select the method: `findAccountByName`
5. Configure the action:
   - **Action Name:** `Find Account`
   - **Description:** `Search for an account by name`
   - **Input Parameter:**
     - Name: `name` (String)
     - Description: "The account name to search for"
   - **Output:** `accountId` (String)

### 2.2 Add "Create Visit Report Draft" Action

**Purpose:** Allow the agent to create a draft record with the conversation transcript.

1. Click **Add Action** → **Standard Object Action**
2. Select **Create Record**
3. Select Object: `MT_Visit_Report_Draft__c`
4. Configure the action:
   - **Action Name:** `Create Visit Report Draft`
   - **Description:** `Create a new visit report draft for processing`
   - **Required Fields:**
     - `Account__c` (Lookup to Account) - From "Find Account" action output
     - `Transcript__c` (Long Text Area) - The full conversation transcript
     - `Status__c` (Picklist) - Set to "New"
     - `Created_By_User__c` (Lookup to User) - Current user ID
     - `Configuration_Profile__c` (Text) - Set to "Default"

---

## Step 3: Design Agent Conversation Flow

### 3.1 Create Agent Instructions

In the agent builder, add the following instructions to guide the agent's behavior:

```
You are a helpful AI assistant for sales people creating visit reports. Your job is to:

1. Greet the caller warmly
2. Ask which customer the visit report is for
3. Search for the customer account in Salesforce
4. If found, ask the caller to describe their meeting
5. Listen carefully and capture all details
6. Create a visit report draft in Salesforce
7. Confirm the report was created

Be conversational, professional, and efficient. Ask clarifying questions if needed.
```

### 3.2 Define Conversation Steps

**Step 1: Greeting**
- Agent says: "Hello! I'm your Visit Report Assistant. I can help you create a visit report. Which customer account is this for?"

**Step 2: Account Identification**
- User says: "Customer XYZ" (or similar)
- Agent calls: `Find Account` action with the customer name
- If found:
  - Agent says: "Great! I found [Account Name]. Please tell me about your meeting with them."
- If not found:
  - Agent says: "I couldn't find that account. Could you spell the name or provide more details?"
  - Retry or ask user to create the account first

**Step 3: Collect Visit Details**
- User dictates: Meeting details, attendees, outcomes, next steps, etc.
- Agent listens and captures the full transcript
- Agent can ask clarifying questions:
  - "Who did you meet with?"
  - "What were the key outcomes?"
  - "Are there any follow-up actions needed?"

**Step 4: Create Draft**
- Agent calls: `Create Visit Report Draft` action
  - `Account__c` = Found Account ID
  - `Transcript__c` = Full conversation transcript
  - `Status__c` = "New"
  - `Created_By_User__c` = Current user ID
  - `Configuration_Profile__c` = "Default"

**Step 5: Confirmation**
- Agent says: "Your visit report has been created and will be processed shortly. You'll receive a notification when it's ready for review. Is there anything else I can help you with?"

---

## Step 4: Configure Agent Permissions

### 4.1 Assign Permission Set to Agent User
1. Go to **Setup** → **Users**
2. Find the **Agentforce Integration User** (auto-created for the agent)
3. Click **Permission Set Assignments**
4. Add: `mt_VoiceAssistant_User`

### 4.2 Grant Object Access
Ensure the agent user has access to:
- `Account` (Read)
- `MT_Visit_Report_Draft__c` (Create, Read)
- `User` (Read - for Created_By_User__c)

---

## Step 5: Test the Agent

### 5.1 Test Call Flow
1. Call the agent's phone number
2. Say: "I need to create a visit report for [Test Account Name]"
3. Verify the agent finds the account
4. Dictate a test visit report (e.g., "I met with John Smith, discussed the Q1 project, and agreed to follow up next week.")
5. Verify the agent confirms the draft was created

### 5.2 Verify Draft Creation
1. Go to **Setup** → **Object Manager** → **Visit Report Draft**
2. Click **Records** (or use Developer Console)
3. Query: `SELECT Id, Name, Status__c, Account__c, Transcript__c FROM MT_Visit_Report_Draft__c ORDER BY CreatedDate DESC LIMIT 1`
4. Verify:
   - Status = "Processing" or "Ready" (depending on flow execution time)
   - Account__c = Correct Account ID
   - Transcript__c = Contains your dictated text

### 5.3 Verify Flow Execution
1. Go to **Setup** → **Process Automation** → **Flow**
2. Find: `MT Process Visit Report Draft`
3. Click **View Runs**
4. Verify the latest run:
   - Status = "Finished" (not "Failed")
   - Check debug logs if failed

### 5.4 Verify Notification
1. Click the **bell icon** (🔔) in Salesforce header
2. Verify you received: "Visit Report Ready for Review"
3. Click the notification → Should navigate to the Account page

### 5.5 Verify Account Page Tab
1. Navigate to the Account record
2. Look for the **Visit Reports** tab
3. Verify the draft appears in the queue
4. Click **Review** → Modal should open with `mtRecordSuggestion` component
5. Review suggested records → Click **Save All**
6. Verify draft status changes to "Processed"

---

## Step 6: Add Visit Reports Tab to Account Page

If the tab is not automatically added, follow these steps:

### 6.1 Edit Account Record Page
1. Go to any **Account** record
2. Click **⚙️ (Setup)** → **Edit Page**
3. In the Lightning App Builder, add a new **Tab**:
   - Tab Label: `Visit Reports`
   - Tab Icon: `custom:custom85`
4. Drag the **mtVisitReportQueue** component into the tab
5. Save and activate the page

### 6.2 Assign Page to Profiles
1. Click **Activation** button
2. Assign the page to:
   - **System Administrator**
   - **Sales User** (or your sales profiles)
3. Click **Save**

---

## Troubleshooting

### Issue 1: Agent Can't Find Account
**Symptoms:** Agent says "I couldn't find that account" even for valid names.

**Solutions:**
- Check the `findAccountByName` Apex method is working:
  ```apex
  String accountId = mt_VisitReportService.findAccountByName('Test Account');
  System.debug('Found Account ID: ' + accountId);
  ```
- Verify the agent user has **Read** access to Account object
- Try using the exact account name (case-sensitive in some orgs)

### Issue 2: Draft Not Created
**Symptoms:** Agent confirms creation, but no draft record exists.

**Solutions:**
- Check **Debug Logs** for the Agentforce Integration User
- Verify the agent has **Create** permission on `MT_Visit_Report_Draft__c`
- Check validation rules on the object (Account__c and Transcript__c are required)
- Verify the agent is passing all required fields

### Issue 3: Flow Doesn't Trigger
**Symptoms:** Draft is created with Status="New" but never changes to "Ready".

**Solutions:**
- Go to **Setup** → **Process Automation** → **Flow**
- Find `MT Process Visit Report Draft` → Click **View Runs**
- Check for failed runs and error messages
- Verify the flow is **Active**
- Check if GenAI Prompt Template `MT_Voice_Account_MultiModal` is published

### Issue 4: No Notification Received
**Symptoms:** Draft is processed (Status="Ready") but no bell notification appears.

**Solutions:**
- Verify the custom notification type `MT_Visit_Report_Ready` exists
- Check the user has the `mt_VoiceAssistant_User` permission set assigned
- Go to **Setup** → **Custom Notifications** → Verify the notification type is enabled
- Check the flow's "Send Notification" action is configured correctly

### Issue 5: Visit Reports Tab Not Showing
**Symptoms:** Account page doesn't have a "Visit Reports" tab.

**Solutions:**
- Edit the Account record page in Lightning App Builder
- Add the `mtVisitReportQueue` component manually (see Step 6 above)
- Verify the component is assigned to the correct page layout
- Check the user's profile has access to the page

---

## Advanced Configuration

### Custom Greeting Message
Edit the agent instructions to customize the greeting:
```
Greet the caller with: "Hi [Caller Name], this is [Your Company] Visit Report Assistant. How can I help you today?"
```

### Multi-Language Support
1. Create multiple agents for different languages
2. Assign different phone numbers per language
3. Update the `Configuration_Profile__c` field to use language-specific configs

### Custom Validation
Add validation rules to `MT_Visit_Report_Draft__c` to enforce:
- Minimum transcript length (e.g., 50 characters)
- Required keywords (e.g., "meeting", "discussed")
- Account must be active

### Scheduled Processing
For high-volume orgs, consider batching draft processing:
1. Create a scheduled Apex job to process drafts in bulk
2. Disable the record-triggered flow
3. Run the batch job every 5-10 minutes

---

## Best Practices

1. **Train Sales Team:** Provide a script or guidelines for what to say during the call
2. **Monitor Agent Performance:** Review call recordings and draft quality weekly
3. **Iterate on Instructions:** Refine agent instructions based on user feedback
4. **Set Up Alerts:** Create reports for failed drafts or long processing times
5. **Archive Old Drafts:** Schedule a job to delete drafts older than 90 days

---

## Support

For issues or questions:
- **Email:** mtietze@salesforce.com
- **Slack:** #mt-voice-assistant (if available)
- **Documentation:** [GitHub Repository](https://github.com/Tietziano90/MT-Visit-Report)

---

## Appendix: Sample Agent Conversation

**Agent:** "Hello! I'm your Visit Report Assistant. Which customer account is this for?"

**User:** "Acme Corporation"

**Agent:** "Great! I found Acme Corporation. Please tell me about your meeting with them."

**User:** "I met with Sarah Johnson, their VP of Sales. We discussed the Q1 renewal, which is valued at $250,000. They're interested in adding 50 more licenses. I need to send them a proposal by Friday and schedule a follow-up call next Tuesday."

**Agent:** "Thank you! I've captured all those details. Your visit report has been created and will be processed shortly. You'll receive a notification when it's ready for review. Is there anything else?"

**User:** "No, that's all. Thanks!"

**Agent:** "You're welcome! Have a great day!"

---

**Last Updated:** December 2025  
**Version:** 1.0







