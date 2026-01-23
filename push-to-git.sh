#!/bin/bash

echo "🚀 Pushing MT Voice Assistant to Git Repository"
echo ""
echo "Repository: https://github.com/Tietziano90/MT-Visit-Report.git"
echo ""

# Configure credential helper if not already set
git config --global credential.helper osxkeychain

echo "You will be prompted for your Git credentials..."
echo ""

# Push to repository
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Successfully pushed to Git repository!"
    echo ""
    echo "Repository URL: https://github.com/Tietziano90/MT-Visit-Report"
    echo ""
else
    echo ""
    echo "❌ Push failed. Please check:"
    echo "  1. Your Git credentials are correct"
    echo "  2. You have push access to the repository"
    echo "  3. The repository exists: https://github.com/Tietziano90/MT-Visit-Report"
    echo ""
    echo "To create a personal access token:"
    echo "  1. Go to: https://git.soma.salesforce.com/-/profile/personal_access_tokens"
    echo "  2. Create a token with 'write_repository' scope"
    echo "  3. Use the token as your password"
    echo ""
fi











