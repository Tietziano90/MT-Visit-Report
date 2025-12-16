# 🚀 How to Push Your Code to Git - Simple Instructions

## 📋 What You Need to Do (3 Easy Steps)

---

### **Step 1: Get Your SSH Key**

Open Terminal and run this command:

```bash
cat ~/.ssh/id_ed25519_soma.pub
```

**You'll see something like this:**
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAywjw4KXTbf9bmgO+n6IRYsIa6hVnUa8+hxqkYNuPvF mtietze@salesforce.com
```

**👉 Copy that entire line** (it starts with `ssh-ed25519`)

---

### **Step 2: Add the Key to soma.git Website**

1. **Open this URL in your browser:**
   ```
   https://git.soma.salesforce.com/-/profile/keys
   ```

2. **Click the blue "Add new key" button**

3. **Fill in the form:**
   - **Title:** Type anything, like `My Mac Computer`
   - **Key:** Paste the line you copied from Step 1
   - **Expires at:** Leave blank (or set a future date)

4. **Click "Add key"**

That's it! Your computer can now talk to Git.

---

### **Step 3: Push Your Code**

Open Terminal and run these commands:

```bash
cd "/Users/mtietze/Documents/Voice Assistant/Voice Assistant Visit Report"

# Set Git to use SSH
git remote set-url origin git@git.soma.salesforce.com:mtietze/MT-Visit-Report.git

# Push your code
git push -u origin main
```

**You should see:**
```
Enumerating objects: 174, done.
Counting objects: 100% (174/174), done.
...
To git.soma.salesforce.com:mtietze/MT-Visit-Report.git
 * [new branch]      main -> main
```

**✅ Done!** Your code is now on Git!

---

## 🎉 After Pushing Successfully

Your repository will be available at:
```
https://github.com/Tietziano90/MT-Visit-Report
```

Then I'll update all the deployment scripts with the correct URL!

---

## ❓ Troubleshooting

### "Permission denied (publickey)"
- Make sure you completed Step 2 (adding the key to the website)
- Wait 1-2 minutes after adding the key, then try again

### "Could not read from remote repository"
- Check that the repository exists: https://github.com/Tietziano90/MT-Visit-Report
- Make sure you have access to it

### Need Help?
Just let me know what error message you see!

---

## 🔄 Alternative: Use HTTPS Instead (Easier but requires password each time)

If SSH is too complicated, you can use HTTPS:

```bash
cd "/Users/mtietze/Documents/Voice Assistant/Voice Assistant Visit Report"

# Use HTTPS instead
git remote set-url origin https://github.com/Tietziano90/MT-Visit-Report.git

# Push (will ask for username and password)
git push -u origin main
```

When prompted:
- **Username:** `mtietze`
- **Password:** Your Git password or personal access token

---

**That's it! Just 3 simple steps!** 🎯

