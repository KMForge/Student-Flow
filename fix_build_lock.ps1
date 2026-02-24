# PowerShell script to fix CMake build lock issues on Windows
# This script kills processes that might be locking build files

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Fixing CMake Build Lock Issues" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Kill Java processes (Gradle)
Write-Host "Checking for Java/Gradle processes..." -ForegroundColor Yellow
$javaProcesses = Get-Process | Where-Object {$_.ProcessName -match "java"}
if ($javaProcesses) {
    Write-Host "Found Java processes. Killing them..." -ForegroundColor Yellow
    $javaProcesses | Stop-Process -Force
    Write-Host "✅ Java processes killed" -ForegroundColor Green
} else {
    Write-Host "No Java processes found" -ForegroundColor Green
}

# Kill Gradle daemon (if JAVA_HOME is set correctly)
Write-Host ""
Write-Host "Stopping Gradle daemon..." -ForegroundColor Yellow
try {
    if (Test-Path "android\gradlew.bat") {
        Push-Location android
        .\gradlew.bat --stop 2>&1 | Out-Null
        Pop-Location
        Write-Host "✅ Gradle daemon stopped" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Gradle wrapper not found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ Could not stop Gradle daemon (may not be running or JAVA_HOME issue)" -ForegroundColor Yellow
    Write-Host "   This is OK - continuing with other fixes..." -ForegroundColor Yellow
}

# Clean Flutter build
Write-Host ""
Write-Host "Cleaning Flutter build..." -ForegroundColor Yellow
flutter clean
Write-Host "✅ Flutter build cleaned" -ForegroundColor Green

# Try to remove build directory manually if it still exists
Write-Host ""
Write-Host "Removing build directory if it exists..." -ForegroundColor Yellow
if (Test-Path "build") {
    try {
        Remove-Item -Path "build" -Recurse -Force -ErrorAction Stop
        Write-Host "✅ Build directory removed" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Could not remove build directory: $_" -ForegroundColor Yellow
        Write-Host "   You may need to close Android Studio or other IDEs" -ForegroundColor Yellow
        Write-Host "   Or restart your computer if the issue persists" -ForegroundColor Yellow
    }
} else {
    Write-Host "Build directory does not exist" -ForegroundColor Green
}

# Try to remove .cxx directory if it exists
Write-Host ""
Write-Host "Removing .cxx directory if it exists..." -ForegroundColor Yellow
if (Test-Path "build\.cxx") {
    try {
        Remove-Item -Path "build\.cxx" -Recurse -Force -ErrorAction Stop
        Write-Host "✅ .cxx directory removed" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Could not remove .cxx directory: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host ".cxx directory does not exist" -ForegroundColor Green
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "1. Close Android Studio or any IDE that might have the project open" -ForegroundColor White
Write-Host "2. Close any file explorers with the build directory open" -ForegroundColor White
Write-Host "3. Temporarily disable antivirus or add build directory to exclusions" -ForegroundColor White
Write-Host "4. Run: flutter pub get" -ForegroundColor Green
Write-Host "5. Run: flutter build apk --release" -ForegroundColor Green
Write-Host ""
Write-Host "If the issue persists:" -ForegroundColor Yellow
Write-Host "- Restart your computer" -ForegroundColor White
Write-Host "- Check Windows Task Manager for hanging processes" -ForegroundColor White
Write-Host "- Add build directory to antivirus exclusions" -ForegroundColor White
Write-Host ""

