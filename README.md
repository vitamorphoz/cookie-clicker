# cookie-clicker

## SSH Setup for GitHub

This guide will help you set up SSH access for this repository.

### Generate SSH Key

1. **Generate a new SSH key pair:**
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```
   Or if your system doesn't support Ed25519:
   ```bash
   ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
   ```

2. **When prompted for a file location, press Enter to use the default location:**
   ```
   Enter file in which to save the key (/home/you/.ssh/id_ed25519): [Press enter]
   ```

3. **Enter a secure passphrase (optional but recommended):**
   ```
   Enter passphrase (empty for no passphrase): [Type a passphrase]
   Enter same passphrase again: [Type passphrase again]
   ```

### Add SSH Key to SSH Agent

1. **Start the SSH agent:**
   ```bash
   eval "$(ssh-agent -s)"
   ```

2. **Add your SSH private key to the SSH agent:**
   ```bash
   ssh-add ~/.ssh/id_ed25519
   ```
   Or for RSA key:
   ```bash
   ssh-add ~/.ssh/id_rsa
   ```

### Add SSH Key to GitHub

1. **Copy your SSH public key to clipboard:**
   
   On Linux:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
   
   On macOS:
   ```bash
   pbcopy < ~/.ssh/id_ed25519.pub
   ```
   
   On Windows (Git Bash):
   ```bash
   clip < ~/.ssh/id_ed25519.pub
   ```

2. **Add the key to GitHub:**
   - Go to GitHub.com and sign in
   - Click your profile photo, then click **Settings**
   - In the "Access" section of the sidebar, click **SSH and GPG keys**
   - Click **New SSH key**
   - Add a descriptive title for the key
   - Paste your key into the "Key" field
   - Click **Add SSH key**

### Test SSH Connection

Test your SSH connection to GitHub:
```bash
ssh -T git@github.com
```

You should see a message like:
```
Hi username! You've successfully authenticated, but GitHub does not provide shell access.
```

### Switch Repository to SSH

If you cloned this repository using HTTPS, you can switch to SSH:

```bash
git remote set-url origin git@github.com:vitamorphoz/cookie-clicker.git
```

Verify the change:
```bash
git remote -v
```

You should see:
```
origin  git@github.com:vitamorphoz/cookie-clicker.git (fetch)
origin  git@github.com:vitamorphoz/cookie-clicker.git (push)
```

### Clone with SSH (for new clones)

To clone this repository using SSH from the start:
```bash
git clone git@github.com:vitamorphoz/cookie-clicker.git
```

## Quick Setup Script

For a quick setup, you can use the provided setup script:
```bash
./setup-ssh.sh
```
