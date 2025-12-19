#!/bin/bash

echo "🚀 Pushing MT Voice Assistant to GitHub"
echo ""
echo "Repository: https://github.com/Tietziano90/MT-Visit-Report"
echo ""
echo "⚠️  Make sure the repository is PUBLIC on GitHub first!"
echo "   Go to: https://github.com/Tietziano90/MT-Visit-Report/settings"
echo "   Scroll to 'Danger Zone' → 'Change visibility' → 'Make public'"
echo ""
read -p "Press Enter once the repository is public..."

echo ""
echo "🔑 You'll be prompted for your GitHub credentials:"
echo "   Username: Tietziano90"
echo "   Password: Your GitHub Personal Access Token"
echo ""
echo "   Don't have a token? Create one here:"
echo "   https://github.com/settings/tokens/new"
echo "   (Select 'repo' scope)"
echo ""

git push -u github main

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Successfully pushed to GitHub!"
    echo ""
    echo "🎉 Your repository is now public at:"
    echo "   https://github.com/Tietziano90/MT-Visit-Report"
    echo ""
    echo "📋 Share this command with users:"
    echo "   git clone https://github.com/Tietziano90/MT-Visit-Report.git"
    echo "   cd MT-Visit-Report"
    echo "   ./deploy.sh"
    echo ""
else
    echo ""
    echo "❌ Push failed. Please check:"
    echo "   1. Repository is public"
    echo "   2. You're using a Personal Access Token (not password)"
    echo "   3. Token has 'repo' scope"
    echo ""
fi







