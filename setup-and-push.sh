#!/bin/bash

echo "🔑 MT Voice Assistant - Git Setup & Push"
echo ""
echo "=========================================="
echo "STEP 1: Add SSH Key to soma.git"
echo "=========================================="
echo ""
echo "Your SSH Public Key:"
echo "-------------------"
cat ~/.ssh/id_ed25519_soma.pub
echo ""
echo "-------------------"
echo ""
echo "📋 Copy the key above and add it to soma.git:"
echo ""
echo "1. Go to: https://git.soma.salesforce.com/-/profile/keys"
echo "2. Click 'Add new key'"
echo "3. Title: MT Voice Assistant - Mac"
echo "4. Paste the key above"
echo "5. Click 'Add key'"
echo ""
read -p "Press Enter once you've added the SSH key to soma.git..."

echo ""
echo "=========================================="
echo "STEP 2: Test SSH Connection"
echo "=========================================="
echo ""

ssh -T git@git.soma.salesforce.com 2>&1 | head -5

if [ $? -eq 1 ]; then
    echo ""
    echo "✅ SSH connection successful!"
else
    echo ""
    echo "⚠️  SSH connection test completed (this is normal)"
fi

echo ""
echo "=========================================="
echo "STEP 3: Configure Git Remote (SSH)"
echo "=========================================="
echo ""

git remote set-url origin git@git.soma.salesforce.com:mtietze/MT-Visit-Report.git
echo "✅ Remote URL set to: git@git.soma.salesforce.com:mtietze/MT-Visit-Report.git"

echo ""
echo "=========================================="
echo "STEP 4: Push to Git Repository"
echo "=========================================="
echo ""

git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ SUCCESS!"
    echo "=========================================="
    echo ""
    echo "Your code has been pushed to:"
    echo "https://github.com/Tietziano90/MT-Visit-Report"
    echo ""
    echo "Next steps:"
    echo "1. View your repository in the browser"
    echo "2. Share the repository URL with users"
    echo "3. Users can deploy with: ./deploy-from-git.sh"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "❌ Push Failed"
    echo "=========================================="
    echo ""
    echo "Please check:"
    echo "1. SSH key was added correctly to soma.git"
    echo "2. You have push access to the repository"
    echo "3. The repository exists"
    echo ""
    echo "Try running: ssh -T git@git.soma.salesforce.com"
    echo "to test your SSH connection"
    echo ""
fi











