# PowerShell script to get SHA-1 and SHA-256 keys for Firebase
# This script helps you get the SHA keys needed for FCM to work on real devices

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Firebase SHA Key Generator" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if Java/keytool is available
$keytoolPath = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytoolPath) {
    Write-Host "ERROR: keytool not found!" -ForegroundColor Red
    Write-Host "Please install Java JDK and add it to your PATH." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Alternatively, you can use:" -ForegroundColor Yellow
    Write-Host "  cd android" -ForegroundColor Green
    Write-Host "  .\gradlew signingReport" -ForegroundColor Green
    exit 1
}

# Default debug keystore paths
$debugKeystoreWindows = "$env:USERPROFILE\.android\debug.keystore"
$debugKeystoreUnix = "$env:HOME/.android/debug.keystore"

# Determine keystore path
if (Test-Path $debugKeystoreWindows) {
    $keystorePath = $debugKeystoreWindows
} elseif (Test-Path $debugKeystoreUnix) {
    $keystorePath = $debugKeystoreUnix
} else {
    Write-Host "DEBUG keystore not found at default location." -ForegroundColor Yellow
    Write-Host ""
    $customPath = Read-Host "Enter path to your keystore file (or press Enter to use Gradle)"
    if ([string]::IsNullOrWhiteSpace($customPath)) {
        Write-Host ""
        Write-Host "Using Gradle to get SHA keys..." -ForegroundColor Cyan
        Write-Host "Run this command:" -ForegroundColor Green
        Write-Host "  cd android" -ForegroundColor Green
        Write-Host "  .\gradlew signingReport" -ForegroundColor Green
        exit 0
    }
    $keystorePath = $customPath
}

Write-Host "Using keystore: $keystorePath" -ForegroundColor Cyan
Write-Host ""

# Get alias
$alias = Read-Host "Enter keystore alias (default: androiddebugkey for debug)"
if ([string]::IsNullOrWhiteSpace($alias)) {
    $alias = "androiddebugkey"
}

# Get password
$password = Read-Host "Enter keystore password (default: android for debug)" -AsSecureString
$passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
if ([string]::IsNullOrWhiteSpace($passwordPlain)) {
    $passwordPlain = "android"
}

Write-Host ""
Write-Host "Getting SHA keys..." -ForegroundColor Cyan
Write-Host ""

# Get SHA keys using keytool
$keytoolOutput = & keytool -list -v -keystore $keystorePath -alias $alias -storepass $passwordPlain 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to get SHA keys!" -ForegroundColor Red
    Write-Host $keytoolOutput -ForegroundColor Red
    exit 1
}

# Extract SHA-1 and SHA-256
$sha1 = ($keytoolOutput | Select-String -Pattern "SHA1:\s+([A-F0-9:]+)").Matches.Groups[1].Value
$sha256 = ($keytoolOutput | Select-String -Pattern "SHA256:\s+([A-F0-9:]+)").Matches.Groups[1].Value

if ($sha1 -and $sha256) {
    Write-Host "================================================" -ForegroundColor Green
    Write-Host "SHA Keys Found!" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "SHA-1:" -ForegroundColor Yellow
    Write-Host $sha1 -ForegroundColor White
    Write-Host ""
    Write-Host "SHA-256:" -ForegroundColor Yellow
    Write-Host $sha256 -ForegroundColor White
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "1. Go to Firebase Console: https://console.firebase.google.com/" -ForegroundColor White
    Write-Host "2. Select your project: student-task-manager-4bc6a" -ForegroundColor White
    Write-Host "3. Go to Project Settings (gear icon)" -ForegroundColor White
    Write-Host "4. Scroll down to 'Your apps' section" -ForegroundColor White
    Write-Host "5. Find your Android app and click 'Add fingerprint'" -ForegroundColor White
    Write-Host "6. Paste SHA-1 key and click 'Add fingerprint' again" -ForegroundColor White
    Write-Host "7. Paste SHA-256 key" -ForegroundColor White
    Write-Host "8. Click 'Save'" -ForegroundColor White
    Write-Host ""
    Write-Host "IMPORTANT: Add BOTH debug AND release SHA keys!" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host "ERROR: Could not extract SHA keys from output!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Full output:" -ForegroundColor Yellow
    Write-Host $keytoolOutput -ForegroundColor White
    Write-Host ""
    Write-Host "Try using Gradle instead:" -ForegroundColor Yellow
    Write-Host "  cd android" -ForegroundColor Green
    Write-Host "  .\gradlew signingReport" -ForegroundColor Green
}

