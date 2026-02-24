# Firebase Cloud Messaging (FCM) Setup and Troubleshooting Guide

## 🔍 What Was Wrong

Your Flutter app was **missing Firebase Cloud Messaging (FCM) implementation entirely**. The app only had local notifications (`flutter_local_notifications`) but no push notification support via FCM. Here are the issues that were fixed:

### Issues Fixed:

1. ❌ **Missing `firebase_messaging` package** - FCM package was not in `pubspec.yaml`
2. ❌ **Missing `permission_handler` package** - No runtime permission handling for Android 13+
3. ❌ **No FCM initialization** - FCM was not initialized in `main.dart`
4. ❌ **Missing background message handler** - No handler for FCM messages when app is in background
5. ❌ **Missing FCM service in AndroidManifest.xml** - Firebase Messaging Service was not declared
6. ❌ **Missing ProGuard rules** - No rules to prevent Firebase classes from being obfuscated in release builds
7. ❌ **No runtime permission requests** - Android 13+ requires runtime permission for notifications

## ✅ What Was Fixed

### 1. Added FCM Dependencies
- Added `firebase_messaging: ^15.1.3` to `pubspec.yaml`
- Added `permission_handler: ^11.3.1` for runtime permissions

### 2. Created FCM Service
- Created `lib/services/fcm_service.dart` with:
  - FCM initialization
  - Token management
  - Foreground message handling
  - Permission requests
  - Topic subscription support

### 3. Created Background Message Handler
- Created `lib/fcm_background_handler.dart` with top-level function for handling background messages
- This is required by Firebase and must be registered before `runApp()`

### 4. Updated main.dart
- Initialize Firebase before FCM
- Register background message handler
- Initialize FCM service
- Proper error handling

### 5. Updated AndroidManifest.xml
- Added Firebase Messaging Service
- Added default notification channel metadata
- Added notification icon and color metadata

### 6. Added ProGuard Rules
- Created `android/app/proguard-rules.pro` with rules to prevent Firebase classes from being obfuscated
- Updated `build.gradle.kts` to reference ProGuard rules

## 🔑 Critical: SHA-1 and SHA-256 Keys

**This is the most common reason FCM doesn't work on real devices!**

Firebase requires your app's SHA-1 and SHA-256 certificate fingerprints to be added to the Firebase Console. Without these, FCM will not work on release builds (real devices).

### How to Get SHA-1 and SHA-256 Keys

#### Option 1: Using Gradle (Recommended for Release Builds)

1. **For Debug Keystore:**
   ```bash
   # Windows (PowerShell)
   cd android
   .\gradlew signingReport
   
   # macOS/Linux
   cd android
   ./gradlew signingReport
   ```

2. **For Release Keystore:**
   If you have a release keystore, you'll need to specify it:
   ```bash
   keytool -list -v -keystore <path-to-your-release-keystore.jks> -alias <your-key-alias>
   ```
   Enter your keystore password when prompted.

#### Option 2: Using Keytool (For Existing Keystores)

1. **Find your debug keystore:**
   - Windows: `C:\Users\<username>\.android\debug.keystore`
   - macOS/Linux: `~/.android/debug.keystore`
   - Default password: `android`
   - Default alias: `androiddebugkey`

2. **Get SHA-1:**
   ```bash
   keytool -list -v -keystore <path-to-keystore> -alias <alias-name>
   ```

3. **Look for:**
   - `SHA1: XX:XX:XX:...` (this is your SHA-1)
   - `SHA256: XX:XX:XX:...` (this is your SHA-256)

#### Option 3: Using Android Studio

1. Open Android Studio
2. Go to **Gradle** → **android** → **Tasks** → **android** → **signingReport**
3. Run the task
4. Copy the SHA-1 and SHA-256 from the output

### How to Add SHA Keys to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `student-task-manager-4bc6a`
3. Click the **⚙️ Settings icon** → **Project settings**
4. Scroll down to **Your apps** section
5. Find your Android app: `com.example.students_task_manager`
6. Click **Add fingerprint**
7. Paste your **SHA-1** key
8. Click **Add fingerprint** again
9. Paste your **SHA-256** key
10. Click **Save**

**Important:** You need to add BOTH debug AND release SHA keys if you want FCM to work in both builds!

## 🧪 Testing FCM

### 1. Get FCM Token

The app will automatically log the FCM token when it initializes. Check your console/logcat for:
```
🔥 FCM Token: <your-token-here>
```

You can also get it programmatically:
```dart
final token = await FCMService().getFCMToken();
print('FCM Token: $token');
```

### 2. Test Notification from Firebase Console

1. Go to Firebase Console → **Cloud Messaging**
2. Click **Send your first message** or **New campaign**
3. Enter notification title and text
4. Click **Send test message**
5. Enter your FCM token (from step 1)
6. Click **Test**
7. Check your device - notification should appear!

### 3. Test on Real Device

1. Build release APK:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

2. Install on device:
   ```bash
   flutter install
   ```

3. Check logs:
   ```bash
   flutter logs
   # or
   adb logcat | grep -i "fcm\|firebase"
   ```

4. Look for:
   - `✅ Firebase initialized successfully`
   - `✅ FCM Service initialized successfully`
   - `🔥 FCM Token: <token>`

## 🔧 Troubleshooting

### Issue: FCM Token is null

**Possible causes:**
1. ❌ SHA-1/SHA-256 keys not added to Firebase Console
2. ❌ `google-services.json` is missing or incorrect
3. ❌ Google Services plugin not applied in `build.gradle.kts`
4. ❌ Firebase project not set up correctly

**Solutions:**
1. ✅ Add SHA keys to Firebase Console (see above)
2. ✅ Verify `android/app/google-services.json` exists and is correct
3. ✅ Verify `apply(plugin = "com.google.gms.google-services")` is in `android/app/build.gradle.kts`
4. ✅ Verify Firebase project is set up correctly

### Issue: Notifications not showing on real device

**Possible causes:**
1. ❌ Notification permission not granted (Android 13+)
2. ❌ Battery optimization enabled for your app
3. ❌ Do Not Disturb mode enabled
4. ❌ App notifications disabled in system settings
5. ❌ Wrong SHA keys in Firebase Console (release vs debug)

**Solutions:**
1. ✅ Grant notification permission when app requests it
2. ✅ Disable battery optimization:
   - Settings → Apps → Your App → Battery → Unrestricted
3. ✅ Check Do Not Disturb settings
4. ✅ Enable notifications in system settings:
   - Settings → Apps → Your App → Notifications → Enable
5. ✅ Add BOTH debug AND release SHA keys to Firebase Console

### Issue: Notifications work on emulator but not real device

**This is almost always a SHA key issue!**

1. ✅ Get SHA-1 and SHA-256 from your release keystore
2. ✅ Add them to Firebase Console
3. ✅ Rebuild and reinstall the app
4. ✅ Test again

### Issue: App crashes on startup

**Possible causes:**
1. ❌ Firebase not initialized before FCM
2. ❌ Background message handler not registered
3. ❌ Missing dependencies

**Solutions:**
1. ✅ Check `main.dart` - Firebase must be initialized before FCM
2. ✅ Verify background message handler is registered before `runApp()`
3. ✅ Run `flutter pub get` to ensure all dependencies are installed

## 📱 Ensuring Notifications Work After Publishing

### 1. Before Publishing to Play Store

1. **Create Release Keystore:**
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Get Release SHA Keys:**
   ```bash
   keytool -list -v -keystore ~/upload-keystore.jks -alias upload
   ```

3. **Add Release SHA Keys to Firebase Console:**
   - Follow the steps above to add SHA-1 and SHA-256

4. **Configure Release Signing in build.gradle.kts:**
   ```kotlin
   android {
       signingConfigs {
           release {
               storeFile file('<path-to-keystore>')
               storePassword '<password>'
               keyAlias 'upload'
               keyPassword '<password>'
           }
       }
       buildTypes {
           release {
               signingConfig = signingConfigs.getByName("release")
           }
       }
   }
   ```

### 2. Test Release Build

1. Build release APK:
   ```bash
   flutter build apk --release
   ```

2. Install and test:
   ```bash
   flutter install
   ```

3. Verify FCM token is generated
4. Send test notification from Firebase Console
5. Verify notification is received

### 3. After Publishing to Play Store

1. ✅ Notifications should work automatically
2. ✅ Monitor Firebase Console for any errors
3. ✅ Check Play Console for crash reports
4. ✅ Test on multiple devices/Android versions

## 🔒 Security Best Practices

1. **Never commit keystore files to version control**
2. **Store keystore passwords securely** (use environment variables or secure storage)
3. **Use different keystores for debug and release**
4. **Keep SHA keys private** (they're tied to your app's identity)

## 📚 Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging Plugin](https://pub.dev/packages/firebase_messaging)
- [Android Notification Permissions](https://developer.android.com/develop/ui/views/notifications/notification-permission)
- [ProGuard Rules for Firebase](https://firebase.google.com/support/guides/fcm-android#proguard)

## ✅ Checklist

Before publishing, make sure:

- [ ] SHA-1 and SHA-256 keys added to Firebase Console (both debug AND release)
- [ ] `google-services.json` is in `android/app/`
- [ ] Google Services plugin applied in `build.gradle.kts`
- [ ] ProGuard rules added and referenced in `build.gradle.kts`
- [ ] FCM initialized in `main.dart`
- [ ] Background message handler registered
- [ ] Notification permissions requested (Android 13+)
- [ ] Tested on real device with release build
- [ ] Test notification sent from Firebase Console
- [ ] Notifications received successfully

## 🎉 Success!

If you've followed all the steps above, FCM should work perfectly on real devices. The most common issue is missing SHA keys, so make sure those are added to Firebase Console!

