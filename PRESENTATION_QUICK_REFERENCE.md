# 🎤 Presentation Quick Reference Card

## 🔐 Password Hashing

**Question:** "Where is the password hashing code?"

**Answer:** 
- **No code in app** - Firebase handles hashing server-side
- **File:** `lib/services/auth_service.dart`
- **Method:** `registerWithEmailPassword()` (line 27)
- **Explanation:** Firebase uses bcrypt on their servers. Passwords are never stored in plain text.

---

## 💾 Profile Saving

**Question:** "Where is the code for saving profile?"

**Answer:**
- **Registration:** `lib/providers/auth_provider.dart` → `register()` (line 357) → calls `firestore_service.dart` → `saveUserData()` (line 12)
- **Update Profile:** `lib/providers/auth_provider.dart` → `updateUserFullName()` (line 756)
- **Firestore Save:** `lib/services/firestore_service.dart` → `saveUserData()` (line 12)
- **Firestore Update:** `lib/services/firestore_service.dart` → `updateUserFullName()` (line 168) & `updateProfilePicture()` (line 180)
- **Profile Picture:** `lib/services/local_storage_service.dart` → `saveProfilePicture()` (line 21)

---

## 📝 Task Management

**Question:** "Where is the code for creating/updating/deleting tasks?"

**Answer:**
- **Create:** `lib/services/database_service.dart` → `insertTask()` (line 44)
- **Read:** `lib/services/database_service.dart` → `getAllTasks()` (line 50)
- **Update:** `lib/services/database_service.dart` → `updateTask()` (line 100)
- **Delete:** `lib/services/database_service.dart` → `deleteTask()` (line 122)
- **Business Logic:** `lib/providers/task_provider.dart`

---

## 🔔 Notifications

**Question:** "Where is the notification code?"

**Answer:**
- **Local Notifications:** `lib/services/notification_service.dart` → `scheduleTaskNotifications()` (line 209)
- **Push Notifications (FCM):** `lib/services/fcm_service.dart` → `initialize()` (line 18)
- **Background Handler:** `lib/fcm_background_handler.dart`

---

## 📊 Database

**Question:** "Where is the database code?"

**Answer:**
- **SQLite (Tasks):** `lib/services/database_service.dart` → `_createDB()` (line 29)
- **Firestore (Users):** `lib/services/firestore_service.dart` → `saveUserData()` (line 12)

---

## 🎯 Key Files

| Feature | File | Method |
|---------|------|--------|
| Password Hashing | `lib/services/auth_service.dart` | `registerWithEmailPassword()` |
| Profile Saving | `lib/services/firestore_service.dart` | `saveUserData()` |
| Profile Updating | `lib/providers/auth_provider.dart` | `updateUserFullName()` |
| Task Creation | `lib/services/database_service.dart` | `insertTask()` |
| Task Update | `lib/services/database_service.dart` | `updateTask()` |
| Notifications | `lib/services/notification_service.dart` | `scheduleTaskNotifications()` |
| FCM Push | `lib/services/fcm_service.dart` | `initialize()` |
| Authentication | `lib/services/auth_service.dart` | `loginWithEmailPassword()` |

---

## 💡 Quick Answers

### Q: "How are passwords secured?"
**A:** Firebase Authentication handles hashing server-side using bcrypt. See `auth_service.dart` line 27.

### Q: "Where are profiles stored?"
**A:** Firestore cloud database. See `firestore_service.dart` → `saveUserData()`.

### Q: "Where are tasks stored?"
**A:** SQLite local database. See `database_service.dart` → `_createDB()`.

### Q: "How are notifications scheduled?"
**A:** Local notifications with timezone (Asia/Manila). See `notification_service.dart` → `scheduleTaskNotifications()`.

### Q: "How does profile picture work?"
**A:** Saved to local storage, then path saved to Firestore. See `local_storage_service.dart` → `saveProfilePicture()`.

---

## 🚀 Architecture

- **State Management:** Provider pattern (`lib/providers/`)
- **Services:** Business logic (`lib/services/`)
- **Models:** Data structures (`lib/models/`)
- **Screens:** UI (`lib/screens/`)
- **Database:** SQLite (local) + Firestore (cloud)

---

**For detailed explanations, see `PRESENTATION_CODE_LOCATIONS.md`**

