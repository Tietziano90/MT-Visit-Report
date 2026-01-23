# 📦 MT Voice Assistant - Deployment Strategy

## Overview

This repository contains **TWO versions** of the MT Voice Assistant:

1. **Original Version** (Production-Ready)
   - Manual entry approach
   - Works with `deploy.sh` script
   - Safe for all customer deployments

2. **Visit Report Draft Version** (Beta)
   - Agent-based approach with drafts
   - Visit Report Manager UI
   - Account-specific views
   - Requires manual deployment

---

## 🎯 How It Works

### Local Folder Structure
```
Voice Assistant Visit Report/
├── force-app/main/default/
│   ├── classes/              # Both versions
│   ├── lwc/                  # Both versions
│   ├── flows/                # Both versions
│   ├── objects/              # Both versions
│   └── ...
├── deploy.sh                 # Deploys ONLY original version
└── .forceignore              # Excludes Visit Report Draft components
```

### .forceignore Configuration

The `.forceignore` file automatically excludes Visit Report Draft components from standard deployments:

- `MT_Visit_Report_Draft__c` object
- `mtVisitReportManager`, `mtVisitReportQueue`, `mtVisitReportRelatedRecords` LWCs
- Visit Report Manager App & Pages
- Visit Report Draft Flows
- Agent-specific Apex classes
- Notification types

---

## 🚀 Deployment Options

### Option 1: Standard Deployment (Original Version)

**Use Case:** Customer deployments, production orgs

```bash
./deploy.sh
```

This will deploy:
- ✅ `mtEinsteinTranscribe` LWC
- ✅ `mtRecordSuggestion` LWC
- ✅ `mtDateInput` LWC
- ✅ `mtVoiceAssistantAdmin` LWC
- ✅ Original flows (`MT_Visit_Report_MultiModal`, `MT_Visit_Report_Standalone_v2`)
- ✅ Core Apex classes
- ✅ Prompt templates
- ✅ Permission sets

This will **NOT** deploy:
- ❌ Visit Report Draft components
- ❌ Visit Report Manager
- ❌ Agent actions

---

### Option 2: Manual Deployment (Visit Report Draft Version)

**Use Case:** Development orgs, testing, orgs with Agent features

#### Deploy All Components (Including Drafts)

```bash
# Deploy to VisitReportOrg
sf project deploy start \
  --source-dir force-app/main/default \
  --target-org VisitReportOrg \
  --ignore-conflicts
```

#### Deploy Specific Draft Components

```bash
# Deploy Visit Report Manager LWC
sf project deploy start \
  --source-dir force-app/main/default/lwc/mtVisitReportManager \
  --target-org VisitReportOrg

# Deploy Visit Report Draft Object
sf project deploy start \
  --source-dir force-app/main/default/objects/MT_Visit_Report_Draft__c \
  --target-org VisitReportOrg

# Deploy Visit Report Draft Flows
sf project deploy start \
  --source-dir force-app/main/default/flows/MT_Process_Visit_Report_Draft_V2.flow-meta.xml \
  --target-org VisitReportOrg
```

---

## 📋 Component Comparison

| Component | Original Version | Visit Report Draft Version |
|-----------|-----------------|---------------------------|
| **Entry Method** | Manual transcription | Agent creates draft |
| **UI Components** | `mtEinsteinTranscribe` | `mtVisitReportManager`, `mtVisitReportQueue` |
| **Flows** | `MT_Visit_Report_MultiModal` | `MT_Process_Visit_Report_Draft_V2` |
| **Objects** | None (direct record creation) | `MT_Visit_Report_Draft__c` |
| **Notifications** | None | Bell notifications to admins |
| **Review Process** | Immediate | Draft → Review → Confirm |

---

## 🔄 Workflow Differences

### Original Version Workflow
1. User navigates to Account
2. User clicks "Start Recording" in `mtEinsteinTranscribe`
3. User speaks or uploads image
4. AI generates records
5. User reviews and saves
6. Records created immediately

### Visit Report Draft Version Workflow
1. Agent creates `MT_Visit_Report_Draft__c` record
2. Flow processes draft (async)
3. Notification sent to System Admins
4. Admin opens Visit Report Manager
5. Admin reviews draft
6. Admin clicks "Confirm & Complete"
7. Records created and draft marked as "Processed"

---

## 🎯 When to Use Each Version

### Use Original Version When:
- ✅ Deploying to customer orgs
- ✅ No Agent/AI features required
- ✅ Users prefer manual entry
- ✅ Immediate record creation needed
- ✅ Simpler setup required

### Use Visit Report Draft Version When:
- ✅ Agent/AI features available
- ✅ Draft/review workflow preferred
- ✅ Multiple admins need to review
- ✅ Audit trail required
- ✅ Account-specific views needed

---

## 🛠️ Maintenance

### Updating .forceignore

If you add new Visit Report Draft components, update `.forceignore`:

```bash
# Add new component to .forceignore
echo "**/lwc/myNewDraftComponent/**" >> .forceignore
```

### Testing Deployment

To see what **would** be deployed without actually deploying:

```bash
# Dry run
sf project deploy start \
  --source-dir force-app/main/default \
  --target-org YourOrg \
  --dry-run \
  --verbose
```

---

## 📞 Support

For questions or issues:
- **Author:** Michael Tietze, Principal AI Architect
- **Email:** mtietze@salesforce.com

---

## 🔐 Security Note

The `deploy.sh` script can be password-protected for additional security. See the script comments for details.

---

**Last Updated:** December 19, 2025





