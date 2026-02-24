# Presentation Guide: Code Locations

## 📍 Quick Reference for Common Questions

This document provides exact locations of key code sections for your presentation.

---

## 1. 🔐 Password Hashing & Authentication

### **Question: "Where is the password hashing code?"**

### **Answer:**

**Password hashing is handled by Firebase Authentication (server-side), not in the app code.**

- **Location:** No explicit hashing code in the app
- **File:** `lib/services/auth_service.dart`
- **Method:** `registerWithEmailPassword()` (lines 22-69) and `loginWithEmailPassword()` (lines 72-85)

### **Explanation:**

Firebase Authentication automatically handles password hashing and encryption on the server-side. When a user registers or logs in:

1. **Registration:**
   ```dart
   // File: lib/services/auth_service.dart, Line 27-30
   final userCredential = await _auth.createUserWithEmailAndPassword(
     email: email,
     password: password,  // Firebase handles hashing on server
   );
   ```

2. **Login:**
   ```dart
   // File: lib/services/auth_service.dart, Line 77-80
   final userCredential = await _auth.signInWithEmailAndPassword(
     email: email,
     password: password,  // Firebase verifies hash on server
   );
   ```

3. **Password Reset:**
   ```dart
   // File: lib/services/auth_service.dart, Line 88-94
   await _auth.sendPasswordResetEmail(email: email);
   ```

### **Security Features:**
- ✅ Passwords are **never stored in plain text**
- ✅ Firebase uses **bcrypt** (industry-standard) for password hashing
- ✅ Passwords are **hashed on Firebase servers**, not in the app
- ✅ All authentication is done through **HTTPS encrypted connections**
- ✅ Firebase handles **salt generation** and **key stretching** automatically

### **Related Files:**
- `lib/services/auth_service.dart` - Authentication service
- `lib/providers/auth_provider.dart` - Auth state management
- `lib/screens/auth/register_screen.dart` - Registration UI
- `lib/screens/auth/login_screen.dart` - Login UI

---

## 2. 💾 Profile Saving Code

### **Question: "Where is the code for saving profile?"**

### **Answer:**

Profile saving happens in multiple places:

### **A. Saving Profile After Registration**

**File:** `lib/providers/auth_provider.dart`  
**Method:** `register()` (lines 337-420)  
**Calls:** `lib/services/firestore_service.dart` → `saveUserData()` (lines 12-30)

```dart
// File: lib/providers/auth_provider.dart, Line 357-358
await _firestoreService.saveUserData(
    uid: _user!.uid, 
    fullName: fullName, 
    email: email
);
```

### **B. Updating Profile (Name & Picture)**

**File:** `lib/providers/auth_provider.dart`  
**Method:** `updateUserFullName()` (lines 756-961)

**Flow:**
1. **Update name in Firestore:**
   ```dart
   // Line 773-775
   await _firestoreService.updateUserFullName(_user!.uid, fullName);
   ```

2. **Save profile picture to local storage:**
   ```dart
   // Line 794-797
   profilePicturePath = await _localStorageService.saveProfilePicture(
       _user!.uid,
       profilePicture,
   );
   ```

3. **Save profile picture path to Firestore:**
   ```dart
   // Line 810-812
   await _firestoreService.updateProfilePicture(_user!.uid, profilePicturePath);
   ```

### **C. Firestore Service - Saving User Data**

**File:** `lib/services/firestore_service.dart`  
**Method:** `saveUserData()` (lines 12-30)

```dart
await _firestore.collection('users').doc(uid).set({
  'fullName': fullName,
  'email': email,
  'uid': uid,
  'createdAt': FieldValue.serverTimestamp(),
  'profilePicture': '', // Empty string initially
});
```

### **D. Firestore Service - Updating Profile**

**File:** `lib/services/firestore_service.dart`

1. **Update Full Name:**
   ```dart
   // Method: updateUserFullName() (lines 168-178)
   await _firestore.collection('users').doc(uid).update({
     'fullName': fullName,
     'updatedAt': FieldValue.serverTimestamp(),
   });
   ```

2. **Update Profile Picture:**
   ```dart
   // Method: updateProfilePicture() (lines 180-217)
   await _firestore.collection('users').doc(uid).update({
     'profilePicture': imageUrl,
     'updatedAt': FieldValue.serverTimestamp(),
   });
   ```

### **E. Local Storage Service - Saving Profile Picture**

**File:** `lib/services/local_storage_service.dart`  
**Method:** `saveProfilePicture()` (lines 21-63)

```dart
// Saves profile picture to device local storage
// Returns the local file path
Future<String> saveProfilePicture(String uid, File imageFile) async {
  // Saves to: app_documents/profile_pictures/{uid}.jpg
}
```

### **F. UI - Edit Profile Screen**

**File:** `lib/screens/account/edit_profile_screen.dart`  
**Method:** `_saveProfile()` (lines 88-250)

```dart
// Calls AuthProvider to update profile
final success = await authProvider.updateUserFullName(
    newName, 
    profilePicture: _selectedImage
);
```

### **Complete Flow:**

1. **User edits profile** → `edit_profile_screen.dart` → `_saveProfile()`
2. **Save to local storage** → `local_storage_service.dart` → `saveProfilePicture()`
3. **Update Firestore** → `firestore_service.dart` → `updateUserFullName()` & `updateProfilePicture()`
4. **Update UI** → `auth_provider.dart` → `notifyListeners()`

---

## 3. 📱 Task Management Code

### **Question: "Where is the code for creating/updating/deleting tasks?"**

### **Answer:**

### **A. Database Service - Task CRUD Operations**

**File:** `lib/services/database_service.dart`

1. **Create Task:**
   ```dart
   // Method: insertTask() (lines 44-48)
   Future<int> insertTask(Task task) async {
     final db = await database;
     return await db.insert('tasks', task.toMap());
   }
   ```

2. **Read Tasks:**
   ```dart
   // Method: getAllTasks() (lines 50-61)
   Future<List<Task>> getAllTasks(String userId) async {
     final db = await database;
     final maps = await db.query('tasks', where: 'userId = ?', whereArgs: [userId]);
     return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
   }
   ```

3. **Update Task:**
   ```dart
   // Method: updateTask() (lines 100-109)
   Future<int> updateTask(Task task) async {
     final db = await database;
     return await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
   }
   ```

4. **Delete Task:**
   ```dart
   // Method: deleteTask() (lines 122-126)
   Future<int> deleteTask(int id) async {
     final db = await database;
     return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
   }
   ```

### **B. Task Provider - Business Logic**

**File:** `lib/providers/task_provider.dart`

1. **Create Task:**
   ```dart
   // Method: createTask() (lines 182-205)
   Future<bool> createTask(Task task) async {
     await _databaseService.insertTask(task);
     await loadTasks(task.userId);
   }
   ```

2. **Update Task:**
   ```dart
   // Method: updateTask() (lines 207-256)
   Future<bool> updateTask(Task task) async {
     await _databaseService.updateTask(task);
     await loadTasks(task.userId);
   }
   ```

3. **Delete Task:**
   ```dart
   // Method: deleteTask() (lines 258-279)
   Future<bool> deleteTask(int taskId, String userId) async {
     await _databaseService.deleteTask(taskId);
     await loadTasks(userId);
   }
   ```

### **C. Task Model**

**File:** `lib/models/task_model.dart`

```dart
// Task data structure
class Task {
  final int? id;
  final String title;
  final String description;
  final String subject;
  final DateTime deadline;
  final String priority;
  final String status;
  final String userId;
  
  // Convert to Map for database storage
  Map<String, dynamic> toMap() { ... }
  
  // Create from Map (database retrieval)
  factory Task.fromMap(Map<String, dynamic> map) { ... }
}
```

---

## 4. 🔔 Notification Code

### **Question: "Where is the notification code?"**

### **Answer:**

### **A. Local Notifications (Task Reminders)**

**File:** `lib/services/notification_service.dart`

1. **Initialize Notifications:**
   ```dart
   // Method: initialize() (lines 23-80)
   Future<void> initialize() async {
     // Sets timezone to Asia/Manila
     // Requests permissions
     // Creates notification channels
   }
   ```

2. **Schedule Notifications:**
   ```dart
   // Method: scheduleTaskNotifications() (lines 209-384)
   Future<void> scheduleTaskNotifications({
     required int taskId,
     required String taskTitle,
     required DateTime deadline,
   }) async {
     // Schedules 1-hour and 30-minute reminders
   }
   ```

### **B. Firebase Cloud Messaging (Push Notifications)**

**File:** `lib/services/fcm_service.dart`

1. **Initialize FCM:**
   ```dart
   // Method: initialize() (lines 18-63)
   Future<void> initialize() async {
     // Requests permissions
     // Gets FCM token
     // Sets up message handlers
   }
   ```

2. **Get FCM Token:**
   ```dart
   // Method: getFCMToken() (lines 149-167)
   Future<String?> getFCMToken() async {
     _fcmToken = await _firebaseMessaging.getToken();
     return _fcmToken;
   }
   ```

3. **Background Message Handler:**
   ```dart
   // File: lib/fcm_background_handler.dart
   @pragma('vm:entry-point')
   Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
     // Handles notifications when app is in background
   }
   ```

---

## 5. 📊 Database Schema

### **Question: "What is the database structure?"**

### **Answer:**

### **A. SQLite Database (Tasks)**

**File:** `lib/services/database_service.dart`  
**Method:** `_createDB()` (lines 29-42)

```sql
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  subject TEXT NOT NULL,
  deadline INTEGER NOT NULL,
  priority TEXT NOT NULL,
  status TEXT NOT NULL,
  userId TEXT NOT NULL
)
```

### **B. Firestore Database (User Profiles)**

**File:** `lib/services/firestore_service.dart`  
**Collection:** `users`  
**Document ID:** User UID

```json
{
  "fullName": "John Doe",
  "email": "john@example.com",
  "uid": "user123",
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z",
  "profilePicture": "/path/to/image.jpg"
}
```

---

## 6. 🔑 Key Architecture Components

### **A. State Management (Provider Pattern)**

**Files:**
- `lib/providers/auth_provider.dart` - Authentication state
- `lib/providers/task_provider.dart` - Task state
- `lib/providers/theme_provider.dart` - Theme state

### **B. Services (Business Logic)**

**Files:**
- `lib/services/auth_service.dart` - Authentication
- `lib/services/firestore_service.dart` - Firestore operations
- `lib/services/storage_service.dart` - Firebase Storage
- `lib/services/database_service.dart` - SQLite operations
- `lib/services/notification_service.dart` - Local notifications
- `lib/services/fcm_service.dart` - Push notifications
- `lib/services/local_storage_service.dart` - Local file storage

### **C. Models (Data Structures)**

**Files:**
- `lib/models/task_model.dart` - Task data model

### **D. Screens (UI)**

**Files:**
- `lib/screens/auth/login_screen.dart` - Login
- `lib/screens/auth/register_screen.dart` - Registration
- `lib/screens/account/edit_profile_screen.dart` - Edit profile
- `lib/screens/tasks/` - Task management screens
- `lib/screens/dashboard/dashboard_screen.dart` - Dashboard

---

## 7. 🎯 Common Questions & Answers

### **Q1: "How are passwords secured?"**
**A:** Firebase Authentication handles password hashing server-side using bcrypt. No passwords are stored in plain text. See `lib/services/auth_service.dart`.

### **Q2: "Where are user profiles stored?"**
**A:** User profiles are stored in Firestore (`users` collection). See `lib/services/firestore_service.dart` → `saveUserData()`.

### **Q3: "Where are tasks stored?"**
**A:** Tasks are stored in SQLite database (`tasks.db`). See `lib/services/database_service.dart`.

### **Q4: "How are notifications scheduled?"**
**A:** Notifications are scheduled using `flutter_local_notifications` with timezone support (Asia/Manila). See `lib/services/notification_service.dart` → `scheduleTaskNotifications()`.

### **Q5: "How does profile picture uploading work?"**
**A:** 
1. Image is saved to local storage → `lib/services/local_storage_service.dart`
2. Path is saved to Firestore → `lib/services/firestore_service.dart` → `updateProfilePicture()`
3. See `lib/providers/auth_provider.dart` → `updateUserFullName()` for complete flow

### **Q6: "How is authentication handled?"**
**A:** Firebase Authentication is used. See `lib/services/auth_service.dart` for login, register, and Google Sign-In.

### **Q7: "Where is the main app entry point?"**
**A:** `lib/main.dart` - Initializes Firebase, FCM, and notification services.

### **Q8: "How is data synchronized?"**
**A:** 
- **User data:** Firestore (cloud) + SharedPreferences (local cache)
- **Tasks:** SQLite (local only)
- **Profile pictures:** Local storage + Firestore (path)

### **Q9: "Where are API calls made?"**
**A:** 
- **Firebase Auth:** `lib/services/auth_service.dart`
- **Firestore:** `lib/services/firestore_service.dart`
- **Firebase Storage:** `lib/services/storage_service.dart`
- **FCM:** `lib/services/fcm_service.dart`

### **Q10: "How is error handling done?"**
**A:** 
- Try-catch blocks in all service methods
- User-friendly error messages
- Retry logic for transient errors (Firestore)
- See `lib/services/firestore_service.dart` → `getUserData()` for retry example

---

## 8. 📁 File Structure Summary

```
lib/
├── main.dart                          # App entry point
├── firebase_options.dart              # Firebase configuration
├── fcm_background_handler.dart        # FCM background handler
├── models/
│   └── task_model.dart                # Task data model
├── providers/
│   ├── auth_provider.dart             # Authentication state
│   ├── task_provider.dart             # Task state
│   └── theme_provider.dart            # Theme state
├── services/
│   ├── auth_service.dart              # Authentication
│   ├── firestore_service.dart         # Firestore operations
│   ├── storage_service.dart           # Firebase Storage
│   ├── database_service.dart          # SQLite operations
│   ├── notification_service.dart      # Local notifications
│   ├── fcm_service.dart               # Push notifications
│   └── local_storage_service.dart     # Local file storage
└── screens/
    ├── auth/
    │   ├── login_screen.dart          # Login UI
    │   └── register_screen.dart       # Registration UI
    ├── account/
    │   └── edit_profile_screen.dart   # Edit profile UI
    └── tasks/
        └── ...                        # Task management screens
```

---

## 9. 🔍 Quick Search Guide

### **To find code for:**

- **Password hashing:** Search for `createUserWithEmailAndPassword` in `auth_service.dart`
- **Profile saving:** Search for `saveUserData` in `firestore_service.dart`
- **Profile updating:** Search for `updateUserFullName` in `auth_provider.dart`
- **Task creation:** Search for `insertTask` in `database_service.dart`
- **Task updating:** Search for `updateTask` in `task_provider.dart`
- **Notifications:** Search for `scheduleTaskNotifications` in `notification_service.dart`
- **FCM:** Search for `getFCMToken` in `fcm_service.dart`
- **Database schema:** Search for `CREATE TABLE` in `database_service.dart`

---

## 10. 🎤 Presentation Tips

### **When asked about password security:**
1. **Explain:** "Firebase Authentication handles password hashing server-side using industry-standard bcrypt algorithm."
2. **Show:** `lib/services/auth_service.dart` lines 27-30
3. **Emphasize:** "Passwords are never stored in plain text and are never sent over unencrypted connections."

### **When asked about profile saving:**
1. **Explain:** "Profile data is saved in Firestore cloud database."
2. **Show:** `lib/services/firestore_service.dart` → `saveUserData()` method
3. **Show:** `lib/providers/auth_provider.dart` → `updateUserFullName()` method
4. **Explain:** "Profile pictures are saved to local storage first, then the path is saved to Firestore."

### **When asked about data storage:**
1. **Explain:** "We use two storage systems:"
   - **SQLite** for tasks (local, fast access)
   - **Firestore** for user profiles (cloud, synchronized)
2. **Show:** `lib/services/database_service.dart` for SQLite
3. **Show:** `lib/services/firestore_service.dart` for Firestore

### **When asked about notifications:**
1. **Explain:** "We use two notification systems:"
   - **Local notifications** for task reminders (scheduled on device)
   - **FCM** for push notifications (from server)
2. **Show:** `lib/services/notification_service.dart` for local notifications
3. **Show:** `lib/services/fcm_service.dart` for push notifications

---

## ✅ Key Takeaways

1. **Password Hashing:** Handled by Firebase (server-side), no code in app
2. **Profile Saving:** `lib/services/firestore_service.dart` → `saveUserData()`
3. **Profile Updating:** `lib/providers/auth_provider.dart` → `updateUserFullName()`
4. **Task Management:** `lib/services/database_service.dart` (SQLite)
5. **Notifications:** `lib/services/notification_service.dart` (local) + `lib/services/fcm_service.dart` (push)
6. **Authentication:** `lib/services/auth_service.dart`
7. **State Management:** Provider pattern in `lib/providers/`

---

**Good luck with your presentation! 🎉**

