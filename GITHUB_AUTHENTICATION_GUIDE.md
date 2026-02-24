# GitHub Authentication Guide for Student_Flow_Application Repository

## Problem
You need to authenticate to push to the `rhodeyreyk/Student_Flow_Application` repository.

## Solution Options

### Option 1: Personal Access Token (Recommended)

1. **Create a Personal Access Token:**
   - Go to: https://github.com/settings/tokens
   - Click "Generate new token" → "Generate new token (classic)"
   - Name it: "Student Flow App"
   - Select scopes: ✅ `repo` (Full control of private repositories)
   - Click "Generate token"
   - **Copy the token immediately** (you won't see it again!)

2. **Update the remote URL with your token:**
   ```powershell
   git remote set-url student-flow https://YOUR_TOKEN@github.com/rhodeyreyk/Student_Flow_Application.git
   ```

3. **Push to the repository:**
   ```powershell
   git push -u student-flow main
   ```

### Option 2: GitHub CLI (Easiest)

1. **Install GitHub CLI:**
   ```powershell
   winget install GitHub.cli
   ```

2. **Login to GitHub:**
   ```powershell
   gh auth login
   ```
   - Follow the prompts
   - Select: GitHub.com
   - Select: HTTPS
   - Authenticate: Login with a web browser

3. **Push to the repository:**
   ```powershell
   git push -u student-flow main
   ```

### Option 3: SSH Keys

1. **Check if you have SSH keys:**
   ```powershell
   ls ~/.ssh
   ```

2. **Generate SSH key (if needed):**
   ```powershell
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

3. **Add SSH key to GitHub:**
   - Copy your public key: `cat ~/.ssh/id_ed25519.pub`
   - Go to: https://github.com/settings/ssh/new
   - Paste the key and save

4. **Update remote to use SSH:**
   ```powershell
   git remote set-url student-flow git@github.com:rhodeyreyk/Student_Flow_Application.git
   ```

5. **Push to the repository:**
   ```powershell
   git push -u student-flow main
   ```

### Option 4: Windows Credential Manager

1. **Update stored credentials:**
   - Press `Win + R`
   - Type: `control /name Microsoft.CredentialManager`
   - Go to "Windows Credentials"
   - Find "git:https://github.com"
   - Remove or update the credential

2. **Push and enter credentials when prompted:**
   ```powershell
   git push -u student-flow main
   ```

## Quick Test

After setting up authentication, test with:
```powershell
git push -u student-flow main
```

## Current Remote Configuration

- **origin**: https://github.com/Eye-que/FlutterProjStudentFlow.git (already working)
- **student-flow**: https://github.com/rhodeyreyk/Student_Flow_Application.git (needs authentication)

## Troubleshooting

### Error: "Permission denied"
- Make sure you have write access to the repository
- Verify you're using the correct GitHub account
- Check that your token has `repo` permissions

### Error: "Authentication failed"
- Verify your token is correct
- Check if the token has expired
- Try generating a new token

### Error: "Repository not found"
- Verify the repository URL is correct
- Check that you have access to the repository
- Ensure the repository exists and is not private (or you have access)

## Next Steps

Once authenticated, you can push with:
```powershell
git push student-flow main
```

To push to both repositories:
```powershell
git push origin main
git push student-flow main
```

