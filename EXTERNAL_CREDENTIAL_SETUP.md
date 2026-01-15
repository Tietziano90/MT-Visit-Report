# 🔐 External Credential Setup Guide

## Issue: API Authentication Errors

If you're seeing API errors after deployment, it's because the External Credentials need to be configured with actual API keys.

---

## ✅ Step-by-Step Fix

### 1. Configure MT Einstein Transcribe API

**Navigate to:**
```
Setup → Named Credentials → External Credentials → MT Einstein Transcribe API
```

**Click on the Principal "AuthDetails":**
- **Parameter Name:** `client_id`
- **Value:** Your Salesforce Connected App Consumer Key
  
- **Parameter Name:** `client_secret`  
- **Value:** Your Salesforce Connected App Consumer Secret

**How to get these values:**
1. Go to: `Setup → App Manager`
2. Find: `mt_Einstein_Transcribe` Connected App
3. Click "View" → "Manage Consumer Details"
4. Copy the Consumer Key and Consumer Secret

**Principal Access:**
- Make sure both permission sets are listed:
  - `mt_Einstein_Transcribe` (PermissionSet)
  - `mt_VoiceAssistant_User` (PermissionSet)

---

### 2. Configure OpenAI Whisper (Optional)

If you want to use OpenAI Whisper instead of Einstein:

**Navigate to:**
```
Setup → Named Credentials → External Credentials → mt_OpenAI_Whisper
```

**Configure the Principal:**
- **Parameter Name:** `api_key`
- **Value:** Your OpenAI API Key (starts with `sk-...`)

**Get OpenAI API Key:**
1. Go to: https://platform.openai.com/api-keys
2. Create a new API key
3. Copy and paste it here

---

### 3. Verify Named Credentials

**Check MT Einstein Transcribe Named Credential:**
```
Setup → Named Credentials → mt_EinsteinTranscribe
```

**Verify:**
- ✅ URL is set to: `https://[YOUR-ORG-DOMAIN].my.salesforce.com`
- ✅ External Credential is: `MT Einstein Transcribe API`
- ✅ "Generate Authorization Header" is checked
- ✅ "Allow Formulas in HTTP Body" is checked

**Update the URL:**
Replace `[YOUR-ORG-DOMAIN]` with your actual org's My Domain.

Example:
- ❌ Bad: `https://minerva--prompt2.sandbox.my.salesforce.com`
- ✅ Good: Your actual org domain from the browser URL

---

### 4. Test the Connection

**After configuration:**

1. Go to: `App Launcher → MT Voice Assistant Settings`
2. Click "Test Connection" (if available)
3. Or try creating a visit report on an Account

---

## 🚨 Common Errors & Fixes

### Error: "Authentication Status: Unknown"

**Fix:**
- The principal parameters (client_id, client_secret) are not set
- Follow Step 1 above to configure them

### Error: "Invalid client credentials"

**Fix:**
- The client_id or client_secret is incorrect
- Regenerate the Consumer Secret in the Connected App
- Update the External Credential with the new values

### Error: "URL not configured"

**Fix:**
- The Named Credential URL is not set to your org's domain
- Update the URL in the Named Credential (Step 3)

### Error: "Insufficient permissions"

**Fix:**
- Assign the permission sets to your user:
  ```bash
  sf org assign permset --name mt_VoiceAssistant_Admin --target-org [YOUR_ORG_ALIAS]
  sf org assign permset --name mt_VoiceAssistant_User --target-org [YOUR_ORG_ALIAS]
  ```

---

## 📝 Quick Checklist

Before testing, verify:

- [ ] Connected App `mt_Einstein_Transcribe` exists
- [ ] External Credential `MT Einstein Transcribe API` has principals configured
- [ ] Named Credential `mt_EinsteinTranscribe` URL is correct
- [ ] Permission sets are assigned to your user
- [ ] Einstein AI is enabled in your org

---

## 🆘 Still Having Issues?

If you're still seeing API errors:

1. **Check the browser console** (F12) for detailed error messages
2. **Check Setup → Debug Logs** for API callout details
3. **Verify your org has Einstein AI enabled**:
   - Setup → Einstein → Einstein Setup
   - Enable "Einstein AI"

---

## 💡 Alternative: Use OpenAI Instead

If Einstein AI is not available in your org:

1. Configure the OpenAI External Credential (Step 2)
2. Update the Voice Assistant configuration to use OpenAI
3. In `MT Voice Assistant Settings`, select "OpenAI Whisper" as the transcription service

---

**Need Help?**
Contact: mtietze@salesforce.com
