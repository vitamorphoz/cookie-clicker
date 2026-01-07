#!/bin/bash

# SSH Setup Script for cookie-clicker repository
# This script helps you set up SSH access to GitHub

set -e

echo "=== SSH Setup for GitHub ==="
echo ""

# Check if SSH key already exists
if [ -f ~/.ssh/id_ed25519 ] || [ -f ~/.ssh/id_rsa ]; then
    echo "⚠️  SSH key already exists!"
    echo ""
    echo "Existing keys found:"
    ls -la ~/.ssh/id_* 2>/dev/null | grep -v '.pub' || true
    echo ""
    read -p "Do you want to use the existing key? (y/n): " use_existing
    
    if [ "$use_existing" != "y" ] && [ "$use_existing" != "Y" ]; then
        echo "Exiting. Please manually manage your SSH keys."
        exit 0
    fi
else
    # Generate new SSH key
    echo "📝 Generating new SSH key..."
    read -p "Enter your email address: " email
    
    if [ -z "$email" ]; then
        echo "❌ Email is required!"
        exit 1
    fi
    
    # Try Ed25519 first (more secure and modern)
    if ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519 -N ""; then
        echo "✅ Ed25519 SSH key generated successfully!"
        KEY_FILE=~/.ssh/id_ed25519
    else
        # Fallback to RSA if Ed25519 is not supported
        echo "Ed25519 not supported, using RSA..."
        ssh-keygen -t rsa -b 4096 -C "$email" -f ~/.ssh/id_rsa -N ""
        echo "✅ RSA SSH key generated successfully!"
        KEY_FILE=~/.ssh/id_rsa
    fi
fi

# Determine which key to use
if [ -z "$KEY_FILE" ]; then
    if [ -f ~/.ssh/id_ed25519 ]; then
        KEY_FILE=~/.ssh/id_ed25519
    elif [ -f ~/.ssh/id_rsa ]; then
        KEY_FILE=~/.ssh/id_rsa
    else
        echo "❌ No SSH key found!"
        exit 1
    fi
fi

echo ""
echo "🔑 Starting SSH agent..."
eval "$(ssh-agent -s)"

echo ""
echo "➕ Adding SSH key to agent..."
ssh-add "$KEY_FILE"

echo ""
echo "📋 Your SSH public key:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "${KEY_FILE}.pub"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Copy to clipboard if possible
if command -v xclip &> /dev/null; then
    cat "${KEY_FILE}.pub" | xclip -selection clipboard
    echo "✅ Key copied to clipboard!"
elif command -v pbcopy &> /dev/null; then
    cat "${KEY_FILE}.pub" | pbcopy
    echo "✅ Key copied to clipboard!"
elif command -v clip &> /dev/null; then
    cat "${KEY_FILE}.pub" | clip
    echo "✅ Key copied to clipboard!"
else
    echo "ℹ️  Please manually copy the key above."
fi

echo ""
echo "📖 Next steps:"
echo "1. Go to https://github.com/settings/ssh/new"
echo "2. Paste your SSH key"
echo "3. Give it a descriptive title"
echo "4. Click 'Add SSH key'"
echo ""

read -p "Press Enter after you've added the key to GitHub..."

echo ""
echo "🧪 Testing SSH connection to GitHub..."
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "✅ SSH connection successful!"
else
    echo "⚠️  Could not verify connection. Please check your GitHub settings."
    echo "   You can test manually with: ssh -T git@github.com"
fi

echo ""
echo "🔄 Switching repository remote from HTTPS to SSH..."
if git remote get-url origin | grep -q "https://"; then
    git remote set-url origin git@github.com:vitamorphoz/cookie-clicker.git
    echo "✅ Remote URL updated to SSH!"
    echo ""
    git remote -v
else
    echo "ℹ️  Repository is already using SSH or non-standard remote."
    git remote -v
fi

echo ""
echo "🎉 SSH setup complete!"
echo ""
echo "You can now push and pull using SSH authentication."
