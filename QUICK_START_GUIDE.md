# 🚀 MT VISIT REPORT MANAGER - Quick Start Guide

**Welcome to your new AI-powered Visit Report system!**

---

## 📱 HOW TO USE THE SYSTEM

### **Step 1: Open the App**

1. Log in to Salesforce
2. Click the **App Launcher** (9 dots in top left)
3. Search for **"MT Visit Report Manager"**
4. Click to open

You'll see a beautiful home page with:
- 📊 Pending draft count badge
- ℹ️ "How It Works" flow diagram
- 📋 Pending and Processed tabs

---

### **Step 2: Call the AI Agent**

1. Call your AI Agent phone number
2. Dictate your visit report:
   - Customer name
   - People you met
   - What was discussed
   - Next steps
   - Any products/projects mentioned

**Example:**
> "I just visited SwissMech AG and met with Peter Smith, their new Lead Project Manager. We discussed the Gewerbepark Süd project worth 550,000 euros. They need 2,500 square meters of Schüco C2C facades for DGNB Gold certification. I need to send them a quote by Friday."

---

### **Step 3: Wait for Processing**

The AI Agent will:
1. ✅ Find the customer account (fuzzy search)
2. ✅ Create a draft record
3. ✅ AI processes the transcript
4. ✅ Generates summary and record suggestions
5. 🔔 Sends you a bell notification

**Processing time:** Usually 30-60 seconds

---

### **Step 4: Review the Draft**

When you receive the notification:

1. Click the **bell icon** 🔔 in Salesforce
2. Click the notification message
3. You'll be taken to the **Visit Report Manager**
4. See your draft in the **"Pending"** tab

Each draft card shows:
- 📝 Draft number (e.g., VR-0006)
- 🏢 Customer account name
- 📅 Creation date/time
- 📄 Summary preview

---

### **Step 5: Process the Draft**

1. Click **"Review & Process"** on the draft
2. A modal opens showing AI suggestions:
   - 👤 **Contacts** to create
   - 💼 **Opportunities** to create
   - ✅ **Tasks** to create
   - 📅 **Events** to create
   - 🎯 **Leads** to create

3. **Review each suggestion:**
   - Edit fields if needed
   - Uncheck items you don't want to create
   - Add additional information

4. Click **"Save All"**

---

### **Step 6: View Results**

After saving:
- ✅ Records are created in Salesforce
- ✅ Draft moves to **"Processed"** tab
- ✅ Success toast notification appears

**To see created records:**
1. Click on the processed draft
2. Opens the draft record page
3. Look at the **"Related Records"** component (right sidebar)
4. See all created records grouped by type
5. Click **"View"** to navigate to each record

---

## 🎯 TIPS FOR BEST RESULTS

### **When Calling the AI Agent:**

✅ **DO:**
- Speak clearly and at a normal pace
- Mention the customer name early
- Include specific numbers (amounts, quantities)
- Mention people's names and roles
- State clear next steps

❌ **DON'T:**
- Rush through the information
- Use vague terms like "some" or "maybe"
- Forget to mention the customer
- Skip important details

---

### **When Reviewing Drafts:**

✅ **DO:**
- Check all suggested records carefully
- Edit fields to add missing information
- Uncheck duplicates if contact/opportunity already exists
- Add notes or descriptions for context

❌ **DON'T:**
- Blindly accept all suggestions
- Create duplicate contacts
- Skip reviewing the summary

---

## 📊 UNDERSTANDING THE SUMMARY

The AI generates a **meeting-focused summary** with:

### **Meeting Context & People:**
- Who did you meet?
- What is their role?
- Are they a NEW contact?

### **Commercial Details:**
- Specific project names
- Revenue amounts
- Quantities (sqm, units, etc.)
- Products discussed

### **Strategic Insight:**
- Why do they want this?
- What certifications/goals are they pursuing?
- What's our competitive advantage?

### **Next Steps:**
- What needs to happen next?
- Any deadlines?

**Example Summary:**
> - **Meeting Context & People:** Met with Peter Smith (New Lead PM) at SwissMech AG.
> - **Commercial Details:** Discussed the "Gewerbepark Süd" project valued at €550k. Focus on 2,500sqm of Schüco C2C facades.
> - **Strategic Insight:** Client is aiming for DGNB Gold certification; our C2C facades provide the competitive edge.
> - **Next Steps:** Need to send detailed quote by Friday, December 20th.

---

## 🔔 NOTIFICATIONS

You'll receive a bell notification when:
- ✅ A new draft is ready for review
- 📱 Visible in Salesforce desktop and mobile
- 🔗 Click to open Visit Report Manager directly

**To enable notifications:**
1. Go to **Setup** → **Notification Delivery Settings**
2. Enable **Desktop Notifications**
3. Enable **Mobile Notifications**

---

## 🏢 VIEWING DRAFTS BY ACCOUNT

You can also view drafts from the **Account page:**

1. Navigate to any Account record
2. Look for the **"Visit Reports"** component
3. See all pending drafts for that account
4. Click **"Review"** to process

---

## 📋 DRAFT STATUSES

| Status | Meaning |
|--------|---------|
| **New** | Just created, waiting for AI processing |
| **Processing** | AI is analyzing the transcript |
| **Ready** | Ready for your review (appears in Pending tab) |
| **Processed** | You've reviewed and created records (appears in Processed tab) |
| **Rejected** | You've rejected the draft (appears in Processed tab) |

---

## ❓ TROUBLESHOOTING

### **"No drafts showing in Pending tab"**
- Check if you have the `mt_VoiceAssistant_User` permission set assigned
- Verify drafts have Status = "Ready"
- Refresh the page

### **"Draft stuck in Processing status"**
- Check the flow execution logs in Setup → Flows → MT Process Visit Report Draft
- Verify GenAI prompt template is active
- Check for error messages in the draft record

### **"Notification not received"**
- Check notification settings in Setup
- Verify custom notification type `MT_Visit_Report_Ready` exists
- Check if flow's notification action is active

### **"Can't find the app"**
- Check if `mt_VoiceAssistant_User` permission set is assigned
- Search for "Visit Report" in App Launcher
- Contact your Salesforce admin

---

## 🎓 TRAINING RESOURCES

### **For New Users:**
1. Watch the "How It Works" section on the app home page
2. Create a test draft with a sample account
3. Practice reviewing and processing drafts
4. Explore the related records component

### **For Admins:**
1. Review `COMPLETE_IMPLEMENTATION_SUMMARY.md`
2. Check flow execution logs regularly
3. Monitor draft statuses
4. Customize prompt template if needed

---

## 📞 SUPPORT

**Questions or Issues?**

**Contact:** Michael Tietze, Principal AI Architect  
**Email:** mtietze@salesforce.com  
**GitHub:** https://github.com/Tietziano90/MT-Visit-Report

---

## 🌟 BEST PRACTICES

### **Daily Workflow:**
1. ☀️ **Morning:** Check Pending tab for new drafts
2. 📝 **Review:** Process drafts within 24 hours
3. ✅ **Follow-up:** Use created tasks/events to track next steps
4. 📊 **Weekly:** Review Processed tab to see trends

### **Data Quality:**
- Always verify contact information before creating
- Add notes to opportunities for context
- Set realistic close dates
- Assign tasks to the right team members

### **Continuous Improvement:**
- Provide feedback on AI suggestions
- Report any issues promptly
- Suggest improvements to the prompt template
- Share success stories with the team

---

## 🎉 YOU'RE READY!

Start using the **MT Visit Report Manager** today and experience the power of AI-assisted visit reporting!

**Happy reporting!** 🚀

---

**Last Updated:** December 18, 2025  
**Version:** 1.0
