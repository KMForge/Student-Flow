# CMake Build Lock Error Fix

## 🔍 Problem

You're getting this error when building:

```
FAILURE: Build failed with an exception.

* What went wrong:

Execution failed for task ':app:configureCMakeDebug[armeabi-v7a]'.

> java.nio.file.FileSystemException: C:\students_task_manager\build\.cxx\Debug\4255j845\armeabi-v7a\CMakeFiles\CMakeTmp: The process cannot access the file because it is being used by another process
```

## 🔎 Root Cause

This is a **Windows file locking issue**. The CMake build process cannot access files in the build directory because they're locked by another process. Common causes:

1. **Gradle daemon** is still running from a previous build
2. **Android Studio** or other IDE has the build directory open
3. **Antivirus software** is scanning the build directory
4. **File Explorer** has the build directory open
5. **Previous build process** didn't terminate properly

## ✅ Solutions

### Solution 1: Stop Gradle Daemon and Clean Build (Recommended)

Run these commands in order:

```powershell
# Stop Gradle daemon
cd android
.\gradlew --stop
cd ..

# Clean Flutter build
flutter clean

# Get dependencies
flutter pub get

# Try building again
flutter build apk --release
```

### Solution 2: Use the Fix Script

Run the provided fix script:

```powershell
.\fix_build_lock.ps1
```

This script will:
- Kill Java/Gradle processes
- Stop Gradle daemon
- Clean Flutter build
- Remove build directories

### Solution 3: Manual Process Kill

If the script doesn't work, manually kill processes:

1. **Open Task Manager** (Ctrl+Shift+Esc)
2. **Find and end these processes:**
   - `java.exe` (Gradle daemon)
   - `dart.exe` (Dart processes)
   - `gradle.exe` (if running)
3. **Close Android Studio** or other IDEs
4. **Close File Explorer** windows with the build directory
5. **Run `flutter clean`** and rebuild

### Solution 4: Close IDEs and File Explorers

1. **Close Android Studio** completely
2. **Close VS Code** or other editors
3. **Close any File Explorer** windows that might have the build directory open
4. **Wait a few seconds** for file locks to release
5. **Run `flutter clean`** and rebuild

### Solution 5: Antivirus Exclusions

Antivirus software can lock files during scanning:

1. **Temporarily disable antivirus** (for testing)
2. **Or add exclusions:**
   - Add `C:\students_task_manager\build` to antivirus exclusions
   - Add `C:\students_task_manager\.dart_tool` to exclusions
   - Add `C:\Users\<your-username>\.gradle` to exclusions

### Solution 6: Restart Computer

If nothing else works:

1. **Save your work**
2. **Restart your computer**
3. **After restart, run:**
   ```powershell
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

## 🔧 Quick Fix Commands

Run these commands in PowerShell (as Administrator if needed):

```powershell
# Stop all Java processes (be careful - this will kill ALL Java processes)
Get-Process java -ErrorAction SilentlyContinue | Stop-Process -Force

# Stop Gradle daemon
cd android
.\gradlew --stop
cd ..

# Clean build
flutter clean

# Remove build directory manually if it still exists
Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue

# Get dependencies
flutter pub get

# Build
flutter build apk --release
```

## 🚨 Important Notes

1. **Don't kill processes while Android Studio is running** - This can corrupt your project
2. **Save your work** before killing processes
3. **Close IDEs first** - This is safer than killing processes
4. **Antivirus can cause issues** - Consider adding build directories to exclusions

## 📋 Step-by-Step Troubleshooting

1. ✅ **Close Android Studio/IDE**
2. ✅ **Close File Explorer** windows
3. ✅ **Stop Gradle daemon** (`.\gradlew --stop`)
4. ✅ **Clean build** (`flutter clean`)
5. ✅ **Wait 5-10 seconds** for file locks to release
6. ✅ **Get dependencies** (`flutter pub get`)
7. ✅ **Build again** (`flutter build apk --release`)

If still failing:
8. ✅ **Kill Java processes** (Task Manager)
9. ✅ **Restart computer**
10. ✅ **Check antivirus** exclusions

## 🎯 Prevention

To prevent this issue in the future:

1. **Always close Android Studio** before building from command line
2. **Add build directories to antivirus exclusions**
3. **Use `flutter clean`** regularly to clear locked files
4. **Stop Gradle daemon** when done: `.\gradlew --stop`

## ✅ Expected Result

After applying the fix:
- ✅ Build completes without file lock errors
- ✅ CMake can access all required files
- ✅ No "process cannot access the file" errors

## 🔍 Verify Fix

After applying the fix, verify:

1. **No Java/Gradle processes** are running (check Task Manager)
2. **Build directory** can be deleted manually
3. **Build completes** successfully
4. **No file lock errors** in the build output

---

**Note:** This is a common Windows issue with CMake builds. The solutions above should resolve it in most cases. If the issue persists after trying all solutions, it may be a deeper Windows file system issue that requires a system restart.

