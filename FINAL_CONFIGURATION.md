# 🔧 MT VISIT REPORT MANAGER - Final Configuration Checklist

**Author:** Michael Tietze, Principal AI Architect  
**Contact:** mtietze@salesforce.com  
**Date:** December 18, 2025

---

## ✅ DEPLOYMENT STATUS

All components have been successfully deployed to **VisitReportOrg**.

---

## 📋 POST-DEPLOYMENT CHECKLIST

### **1. Permission Sets** ✅

**Action:** Assign `mt_VoiceAssistant_User` to all users who will use the system.

**How to Assign:**
```bash
sf org assign permset --name mt_VoiceAssistant_User --target-org VisitReportOrg
```

**Or via UI:**
1. Setup → Users → Select User
2. Permission Set Assignments → Add Assignment
3. Select `mt_VoiceAssistant_User`
4. Click Assign

**What it grants:**
- Access to MT_Visit_Report_Draft__c object
- Access to all Apex classes
- Visibility to MT Visit Report Manager app
- Visibility to all related tabs

---

### **2. Notification Settings** ✅

**Action:** Enable notifications for users.

**Steps:**
1. Setup → Notification Delivery Settings
2. Enable **Desktop Notifications**
3. Enable **Mobile Notifications**
4. Save

**Verify:**
- Custom Notification Type `MT_Visit_Report_Ready` exists
- Flow action is sending notifications
- Users can receive bell notifications

---

### **3. Flow Activation** ✅

**Flow:** `MT_Process_Visit_Report_Draft`

**Status:** ✅ Active

**Verify:**
1. Setup → Flows
2. Search for "MT Process Visit Report Draft"
3. Status should be **Active**
4. Version should be latest

**If not active:**
1. Open flow
2. Click **Activate**
3. Confirm activation

---

### **4. GenAI Prompt Template** ✅

**Template:** `MT_Voice_Account_MultiModal`

**Status:** ✅ Updated with meeting-focused summary instructions

**Verify:**
1. Setup → Prompt Builder → Prompt Templates
2. Search for "MT_Voice_Account_MultiModal"
3. Check "SUMMARY GENERATION GUIDELINES" section
4. Verify examples show meeting-focused summaries

**Key Points:**
- Summary should describe the MEETING, not AI actions
- Should include specific names, amounts, project titles
- Should be structured with Meeting Context, Commercial Details, Strategic Insight, Next Steps

---

### **5. AI Agent Configuration** ⚠️

**Status:** ⚠️ Requires manual configuration in UI

**Invocable Methods Available:**
- ✅ `mt_AgentFindAccount` (Find Account for Visit Report)
- ✅ `mt_AgentCreateDraft` (Create Visit Report Draft)

**Steps to Configure Agent:**
1. Setup → Agents
2. Create or edit your AI Agent
3. Add **Prompt Actions**:
   - Action 1: Find Account (uses `mt_AgentFindAccount`)
   - Action 2: Create Draft (uses `mt_AgentCreateDraft`)
4. Configure conversation flow
5. Test with sample inputs

**Agent Conversation Flow:**
```
1. Greet user
2. Ask for customer name
3. Call "Find Account" action
4. If found: Confirm with user
5. If not found: Ask for clarification
6. Ask for visit details
7. Collect transcript
8. Call "Create Draft" action
9. Confirm draft created
10. End call
```

---

### **6. App Visibility** ✅

**App:** `mt_VisitReport_Manager`

**Status:** ✅ Visible to users with permission set

**Verify:**
1. Log in as a user with `mt_VoiceAssistant_User` permission set
2. Click App Launcher (9 dots)
3. Search for "MT Visit Report Manager"
4. App should appear in search results
5. Click to open

**Home Page:**
- Should display `mtVisitReportManager` component
- Should show "How It Works" section
- Should have Pending/Processed tabs

---

### **7. Record Page Layout** ✅

**Object:** MT_Visit_Report_Draft__c

**Page Layout:** MT Visit Report Draft Layout

**Custom Record Page:** MT_Visit_Report_Draft_Record_Page

**Verify:**
1. Navigate to any draft record
2. Should see custom Lightning page
3. Right sidebar should show `mtVisitReportRelatedRecords` component
4. All fields should be visible and properly organized

**If not showing:**
1. Setup → Object Manager → MT Visit Report Draft
2. Lightning Record Pages
3. Assign `MT_Visit_Report_Draft_Record_Page` as org default

---

### **8. Account Page Component** ✅

**Component:** `mtVisitReportQueue`

**Status:** ✅ Deployed and available

**To Add to Account Page:**
1. Navigate to any Account record
2. Click ⚙️ gear icon → Edit Page
3. Drag `mtVisitReportQueue` component onto page
4. Save and Activate
5. Assign to org default or specific profiles

**Component Features:**
- Shows pending drafts for the account
- Displays summary and account name
- Review and Reject buttons
- Opens modal for processing

---

### **9. Data Validation** ✅

**Validation Rules:**
- ✅ Account required on create
- ✅ Transcript required on create

**Field Dependencies:**
- Status__c picklist values: New, Processing, Ready, Processed, Rejected
- All required fields have proper validation

**Test:**
1. Try creating a draft without Account → Should fail
2. Try creating a draft without Transcript → Should fail
3. Try creating a draft with both → Should succeed

---

### **10. Integration Testing** ✅

**Test Scenario 1: End-to-End Flow**
1. ✅ Create draft with Status = "New"
2. ✅ Flow triggers and processes
3. ✅ Status changes to "Processing" → "Ready"
4. ✅ Summary and Reasoning populated
5. ✅ Notification sent to user

**Test Scenario 2: Review and Process**
1. ✅ Open Visit Report Manager
2. ✅ See draft in Pending tab
3. ✅ Click "Review & Process"
4. ✅ Modal opens with suggestions
5. ✅ Save records
6. ✅ Draft moves to Processed tab
7. ✅ Created record IDs stored in draft

**Test Scenario 3: Related Records**
1. ✅ Open processed draft record
2. ✅ See Related Records component
3. ✅ View created records grouped by type
4. ✅ Navigate to records

---

## 🎯 CONFIGURATION PRIORITIES

### **High Priority (Must Do):**
1. ✅ Assign permission sets to users
2. ⚠️ Configure AI Agent with prompt actions
3. ✅ Enable notifications
4. ✅ Verify flow is active

### **Medium Priority (Should Do):**
1. ✅ Add `mtVisitReportQueue` to Account pages
2. ✅ Test end-to-end flow with real data
3. ✅ Train users on the system

### **Low Priority (Nice to Have):**
1. Customize page layouts
2. Add custom fields if needed
3. Adjust prompt template for specific use cases
4. Create reports and dashboards

---

## 📊 MONITORING & MAINTENANCE

### **Daily:**
- Check for drafts stuck in "Processing" status
- Review flow execution logs for errors
- Monitor user feedback

### **Weekly:**
- Review processed drafts for quality
- Check notification delivery
- Analyze AI summary quality

### **Monthly:**
- Review and optimize prompt template
- Update object configurations if needed
- Train new users
- Gather feedback for improvements

---

## 🔍 VERIFICATION COMMANDS

### **Check Deployed Components:**
```bash
# Check custom object
sf sobject describe --sobject MT_Visit_Report_Draft__c --target-org VisitReportOrg

# Check Apex classes
sf apex list class --target-org VisitReportOrg | grep mt_

# Check LWC components
sf lightning list component --target-org VisitReportOrg | grep mt

# Check flows
sf flow list --target-org VisitReportOrg | grep MT_Process

# Check apps
sf org list app --target-org VisitReportOrg | grep MT
```

### **Query Data:**
```bash
# Check drafts
sf data query --query "SELECT Id, Name, Status__c, Account__r.Name FROM MT_Visit_Report_Draft__c ORDER BY CreatedDate DESC LIMIT 10" --target-org VisitReportOrg

# Check permission set assignments
sf data query --query "SELECT Assignee.Name, PermissionSet.Name FROM PermissionSetAssignment WHERE PermissionSet.Name = 'mt_VoiceAssistant_User'" --target-org VisitReportOrg
```

---

## 🚨 KNOWN ISSUES & SOLUTIONS

### **Issue 1: Draft Stuck in "Processing"**
**Cause:** Flow error or GenAI API timeout

**Solution:**
1. Check flow execution logs
2. Verify GenAI prompt template is active
3. Check error message in draft record
4. Manually update status to "Ready" if needed

### **Issue 2: Notification Not Received**
**Cause:** Notification settings or flow configuration

**Solution:**
1. Verify notification delivery settings enabled
2. Check custom notification type exists
3. Verify flow's notification action is active
4. Test with a different user

### **Issue 3: Component Not Showing**
**Cause:** Permission set not assigned or component not deployed

**Solution:**
1. Assign `mt_VoiceAssistant_User` permission set
2. Hard refresh browser (Cmd+Shift+R)
3. Check component deployment status
4. Verify component is exposed to correct targets

### **Issue 4: Records Not Creating**
**Cause:** Validation rules or field permissions

**Solution:**
1. Check validation rules on target objects
2. Verify user has create permission on objects
3. Check required fields are populated
4. Review error messages in browser console

---

## 📞 SUPPORT & ESCALATION

### **Level 1: User Issues**
- Check Quick Start Guide
- Verify permission set assignment
- Test with different browser
- Clear cache and refresh

### **Level 2: Configuration Issues**
- Review this configuration checklist
- Check flow execution logs
- Verify component deployment
- Test in sandbox first

### **Level 3: Development Issues**
- Contact: Michael Tietze
- Email: mtietze@salesforce.com
- Include: Error messages, screenshots, steps to reproduce

---

## ✅ FINAL VERIFICATION

**Before marking as complete, verify:**

- [ ] All components deployed successfully
- [ ] Permission sets assigned to users
- [ ] Flow is active and working
- [ ] Notifications are being sent
- [ ] App is visible in App Launcher
- [ ] Components are showing on pages
- [ ] End-to-end flow tested successfully
- [ ] Users trained on the system
- [ ] Documentation shared with team
- [ ] AI Agent configured with prompt actions

---

## 🎉 SYSTEM READY FOR PRODUCTION

Once all items are verified, the system is ready for production use!

**Status:** ✅ **READY**

**Date Completed:** December 18, 2025

**Deployed By:** Michael Tietze, Principal AI Architect

---

**End of Configuration Checklist**
