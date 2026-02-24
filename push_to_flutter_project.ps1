# Script to push to FlutterProject repository
# This script helps you push to the rhodeyreyk/FlutterProject repository

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Push to FlutterProject Repository" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Repository: https://github.com/rhodeyreyk/FlutterProject" -ForegroundColor Yellow
Write-Host ""

Write-Host "⚠ Authentication Required" -ForegroundColor Red
Write-Host "To push to this repository, you need to authenticate as 'rhodeyreyk' user." -ForegroundColor Yellow
Write-Host ""

Write-Host "Option 1: Use Personal Access Token (Recommended)" -ForegroundColor Green
Write-Host "1. Go to: https://github.com/settings/tokens" -ForegroundColor White
Write-Host "2. Click 'Generate new token (classic)'" -ForegroundColor White
Write-Host "3. Name it: 'FlutterProject Push'" -ForegroundColor White
Write-Host "4. Select scope: ✅ repo (Full control)" -ForegroundColor White
Write-Host "5. Generate and copy the token" -ForegroundColor White
Write-Host ""
Write-Host "Then run:" -ForegroundColor Yellow
Write-Host "  git remote set-url flutter-project https://YOUR_TOKEN@github.com/rhodeyreyk/FlutterProject.git" -ForegroundColor Cyan
Write-Host "  git push -u flutter-project main --force" -ForegroundColor Cyan
Write-Host ""

Write-Host "Option 2: Use GitHub CLI" -ForegroundColor Green
Write-Host "1. Install: winget install GitHub.cli" -ForegroundColor White
Write-Host "2. Login: gh auth login" -ForegroundColor White
Write-Host "3. Push: git push -u flutter-project main --force" -ForegroundColor White
Write-Host ""

Write-Host "Option 3: Merge Remote Content First" -ForegroundColor Green
Write-Host "If you want to preserve the existing README/LICENSE:" -ForegroundColor White
Write-Host "  git pull flutter-project main --allow-unrelated-histories" -ForegroundColor Cyan
Write-Host "  # Resolve any conflicts" -ForegroundColor Cyan
Write-Host "  git push -u flutter-project main" -ForegroundColor Cyan
Write-Host ""

Write-Host "Current Remote Configuration:" -ForegroundColor Yellow
git remote -v
Write-Host ""

Write-Host "Note: The remote repository has an initial commit with README/LICENSE." -ForegroundColor Yellow
Write-Host "You can either force push (overwrite) or merge the content first." -ForegroundColor Yellow

