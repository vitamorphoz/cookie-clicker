#!/bin/bash

# SSH Setup Script for cookie-clicker repository
# This script helps you set up SSH access to GitHub

set -euo pipefail

echo "=== SSH Setup for GitHub ==="
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: This script must be run from within a git repository!"
    echo "   Please navigate to your repository directory and try again."
    exit 1
fi

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
    
    echo ""
    echo "⚠️  Security Note: SSH keys can be protected with a passphrase."
    echo "   A passphrase adds an extra layer of security but will be required"
    echo "   each time you use the key (unless you use ssh-agent)."
    echo ""
    read -p "Do you want to set a passphrase? (y/n): " use_passphrase
    
    PASSPHRASE=""
    if [ "$use_passphrase" = "y" ] || [ "$use_passphrase" = "Y" ]; then
        echo "You will be prompted to enter a passphrase during key generation."
        echo "Press Enter to proceed..."
        read
        PASSPHRASE_FLAG=""
    else
        echo "⚠️  Warning: Creating key without passphrase (less secure)."
        PASSPHRASE_FLAG="-N \"\""
    fi
    
    # Try Ed25519 first (more secure and modern)
    if [ -z "$PASSPHRASE_FLAG" ]; then
        if ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519; then
            echo "✅ Ed25519 SSH key generated successfully!"
            KEY_FILE=~/.ssh/id_ed25519
        else
            echo "Ed25519 not supported, using RSA..."
            ssh-keygen -t rsa -b 4096 -C "$email" -f ~/.ssh/id_rsa
            echo "✅ RSA SSH key generated successfully!"
            KEY_FILE=~/.ssh/id_rsa
        fi
    else
        if ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519 -N ""; then
            echo "✅ Ed25519 SSH key generated successfully!"
            KEY_FILE=~/.ssh/id_ed25519
        else
            echo "Ed25519 not supported, using RSA..."
            ssh-keygen -t rsa -b 4096 -C "$email" -f ~/.ssh/id_rsa -N ""
            echo "✅ RSA SSH key generated successfully!"
            KEY_FILE=~/.ssh/id_rsa
        fi
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
# Only check for success message, don't display full output for security
if ssh -T git@github.com 2>&1 | grep -q "You've successfully authenticated"; then
    echo "✅ SSH connection successful!"
else
    echo "⚠️  Could not verify connection. Please check your GitHub settings."
    echo "   You can test manually with: ssh -T git@github.com"
fi

echo ""
echo "🔄 Switching repository remote from HTTPS to SSH..."
CURRENT_URL=$(git remote get-url origin 2>/dev/null || echo "")
if [ -n "$CURRENT_URL" ] && echo "$CURRENT_URL" | grep -q "https://github.com/"; then
    # Extract repository path from HTTPS URL
    REPO_PATH=$(echo "$CURRENT_URL" | sed 's|https://github.com/||' | sed 's|\.git$||')
    SSH_URL="git@github.com:${REPO_PATH}.git"
    git remote set-url origin "$SSH_URL"
    echo "✅ Remote URL updated to SSH!"
    echo ""
    git remote -v
elif [ -n "$CURRENT_URL" ] && echo "$CURRENT_URL" | grep -q "git@github.com:"; then
    echo "ℹ️  Repository is already using SSH."
    git remote -v
else
    echo "ℹ️  Could not determine repository URL or non-GitHub remote."
    git remote -v
fi

echo ""
echo "🎉 SSH setup complete!"
echo ""
echo "You can now push and pull using SSH authentication."
