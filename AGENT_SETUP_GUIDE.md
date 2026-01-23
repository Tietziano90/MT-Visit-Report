# 🤖 Visit Report Voice Agent Setup Guide

## Overview
This guide will help you set up the AI Voice Agent for creating Visit Reports via phone calls.

---

## ✅ Prerequisites (Already Deployed)

The following Apex actions are now available in your org:
- ✅ `mt_AgentFindAccount` - Searches for Account by name
- ✅ `mt_AgentCreateDraft` - Creates Visit Report Draft record

---

## 📋 Agent Configuration Steps

### Step 1: Create the Agent

1. Go to **Setup** → Search for **"Agents"** → Click **"Agents"**
2. Click **"New Agent"**
3. Configure:
   - **Name:** `Visit Report Agent`
   - **Description:** `Voice agent for creating visit report drafts via phone calls`
   - **Type:** Select **"Agent"** (not Service Agent)
   - **Role:** `I help sales reps create visit report drafts by collecting information about their customer meetings`

### Step 2: Configure Agent Instructions

In the Agent Builder, set the **System Instructions**:

```
You are a helpful voice assistant for sales representatives. Your job is to help them create visit report drafts after customer meetings.

CONVERSATION FLOW:
1. Greet the user warmly
2. Ask which company/account the visit report is for
3. Search for the account using the provided action
4. If found, ask the user to describe their visit
5. Listen to the full visit report details
6. Ask if there's anything else to add
7. Create the draft using the provided action
8. Confirm completion

IMPORTANT GUIDELINES:
- Keep responses SHORT and NATURAL for voice conversations
- Don't repeat information unnecessarily
- Be conversational and friendly
- If account not found, ask user to spell it differently
- Always confirm the account name before proceeding
- Let the user speak freely when describing their visit
- Don't interrupt or ask too many questions during the visit description
```

### Step 3: Add Topics

Create the following topics:

#### Topic 1: Greeting
- **Name:** `Greeting`
- **Instructions:** `Greet the user and ask which company they want to create a visit report for`
- **Sample Utterances:**
  - "Hi"
  - "Hello"
  - "I want to create a visit report"
  - "I need to log a customer visit"

#### Topic 2: Find Account
- **Name:** `Find Account`
- **Instructions:** `Use the Find Account action to search for the company name provided by the user. Confirm the account name with the user before proceeding.`
- **Actions:** Add `Find Account for Visit Report` (mt_AgentFindAccount)
- **Sample Utterances:**
  - "The company is [company name]"
  - "It's for [company name]"
  - "[company name]"

#### Topic 3: Collect Visit Details
- **Name:** `Collect Visit Details`
- **Instructions:** `Ask the user to describe their visit. Let them speak freely. Listen for details about who they met, what was discussed, next steps, etc. When they're done, ask if there's anything else to add.`
- **Sample Utterances:**
  - "I met with..."
  - "The visit was about..."
  - "We discussed..."

#### Topic 4: Create Draft
- **Name:** `Create Draft`
- **Instructions:** `Use the Create Visit Report Draft action with the account ID and the full transcript of what the user said. Confirm that the draft has been created and will be processed automatically.`
- **Actions:** Add `Create Visit Report Draft` (mt_AgentCreateDraft)
- **Sample Utterances:**
  - "Create the draft"
  - "Save it"
  - "That's everything"
  - "No, that's all"

### Step 4: Configure Actions

For each action, map the variables:

#### Find Account for Visit Report
- **Input:**
  - `accountName` → Use the company name mentioned by the user
- **Output:**
  - Store `accountId` in a variable called `foundAccountId`
  - Store `accountName` in a variable called `foundAccountName`
  - Store `success` in a variable called `accountSearchSuccess`
  - Use `message` to respond to the user

#### Create Visit Report Draft
- **Input:**
  - `accountId` → Use `foundAccountId` from previous action
  - `transcript` → Use the full conversation transcript or visit details
  - `configProfile` → Set to "Default" (or leave blank)
- **Output:**
  - Store `draftId` in a variable called `createdDraftId`
  - Store `success` in a variable called `draftCreationSuccess`
  - Use `message` to respond to the user

### Step 5: Configure Voice Channel (Optional)

If you want to enable phone access:

1. Go to **Setup** → **Voice**
2. Configure your telephony provider (e.g., Amazon Connect, Twilio)
3. Create a phone number
4. Route the phone number to your Visit Report Agent

---

## 🎯 Example Conversation Flow

```
Agent: "Hi! I'm here to help you create a visit report. Which company is this visit report for?"

User: "SwissMech AG"

Agent: "Found account: SwissMech AG in Zurich. Is that correct?"

User: "Yes"

Agent: "Great! Please tell me about your visit."

User: "I met with Hans Mueller, the new VP of Sales. He's very interested in our Enterprise package for their team of 50 users. We discussed pricing around 50,000 Swiss Francs annually. He mentioned they need better CRM integration and mobile access. Hans wants a formal proposal by next Friday. His email is hans.mueller@swissmech.ch. We should follow up with a demo in early January."

Agent: "Thank you. Is there anything else you'd like to add?"

User: "No, that's everything."

Agent: "Perfect! I've created your visit report draft. It will be processed automatically and you'll see it in your account shortly. Have a great day!"
```

---

## 🔒 Permissions

Make sure users have the following permissions:
- ✅ `mt_VoiceAssistant_User` permission set (already includes access to the Apex classes)
- ✅ Access to the `MT_Visit_Report_Draft__c` object
- ✅ Access to Account object (read)

---

## 🧪 Testing

1. **Test via Agent Builder:**
   - Use the "Preview" button in Agent Builder
   - Try the sample conversation flow above

2. **Test the Apex Actions Directly:**
   ```apex
   // Test Find Account
   mt_AgentFindAccount.AccountSearchRequest req1 = new mt_AgentFindAccount.AccountSearchRequest();
   req1.accountName = 'SwissMech';
   List<mt_AgentFindAccount.AccountSearchResult> results1 = mt_AgentFindAccount.findAccount(new List<mt_AgentFindAccount.AccountSearchRequest>{req1});
   System.debug(results1[0].message);
   
   // Test Create Draft
   mt_AgentCreateDraft.CreateDraftRequest req2 = new mt_AgentCreateDraft.CreateDraftRequest();
   req2.accountId = results1[0].accountId;
   req2.transcript = 'Test visit report transcript';
   req2.configProfile = 'Default';
   List<mt_AgentCreateDraft.CreateDraftResult> results2 = mt_AgentCreateDraft.createVisitReportDraft(new List<mt_AgentCreateDraft.CreateDraftRequest>{req2});
   System.debug(results2[0].message);
   ```

---

## 📱 What Happens After the Agent Creates a Draft?

1. **Draft Created** → `MT_Visit_Report_Draft__c` record with Status = "New"
2. **Flow Triggers** → `MT_Process_Visit_Report_Draft` flow automatically runs
3. **AI Processing** → GenAI Prompt Template processes the transcript
4. **Status Updated** → Status changes to "Ready"
5. **User Reviews** → User sees the draft in the `mtVisitReportQueue` component on the Account page
6. **Records Created** → User reviews and creates Contacts, Tasks, Opportunities, etc.

---

## 🎉 You're All Set!

The Apex actions are deployed and ready. Just follow the steps above to configure your Agent in the Salesforce UI.

For support, contact: mtietze@salesforce.com





