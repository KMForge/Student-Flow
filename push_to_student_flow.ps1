# Script to push to Student_Flow_Application repository
# This script helps you push to the rhodeyreyk/Student_Flow_Application repository

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Push to Student Flow Application" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "To push to this repository, you need to authenticate." -ForegroundColor Yellow
Write-Host ""
Write-Host "Option 1: Use Personal Access Token (Recommended)" -ForegroundColor Green
Write-Host "1. Go to GitHub > Settings > Developer settings > Personal access tokens > Tokens (classic)" -ForegroundColor White
Write-Host "2. Generate a new token with 'repo' permissions" -ForegroundColor White
Write-Host "3. Copy the token" -ForegroundColor White
Write-Host "4. Update the remote URL with:" -ForegroundColor White
Write-Host "   git remote set-url student-flow https://YOUR_TOKEN@github.com/rhodeyreyk/Student_Flow_Application.git" -ForegroundColor Cyan
Write-Host ""
Write-Host "Option 2: Use GitHub CLI" -ForegroundColor Green
Write-Host "1. Install GitHub CLI: winget install GitHub.cli" -ForegroundColor White
Write-Host "2. Run: gh auth login" -ForegroundColor White
Write-Host "3. Then push: git push student-flow main" -ForegroundColor White
Write-Host ""
Write-Host "Option 3: Use SSH (if you have SSH keys set up)" -ForegroundColor Green
Write-Host "1. Update remote: git remote set-url student-flow git@github.com:rhodeyreyk/Student_Flow_Application.git" -ForegroundColor White
Write-Host "2. Push: git push student-flow main" -ForegroundColor White
Write-Host ""

# Check if user wants to try with current credentials
$response = Read-Host "Do you want to try pushing now? (y/n)"
if ($response -eq "y" -or $response -eq "Y") {
    Write-Host ""
    Write-Host "Attempting to push..." -ForegroundColor Yellow
    git push -u student-flow main
} else {
    Write-Host ""
    Write-Host "Please set up authentication first, then run:" -ForegroundColor Yellow
    Write-Host "git push -u student-flow main" -ForegroundColor Cyan
}

