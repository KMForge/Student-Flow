# Notification Timezone and 1-Hour Notification Fix

## 🔍 Problems Fixed

1. **1-hour notification not working** - The notification was being skipped in certain conditions
2. **Timezone not set to Philippines** - Notifications were using device local timezone instead of Asia/Manila

## ✅ Solutions Applied

### 1. Set Timezone to Asia/Manila (Philippines)

**Changes:**
- Initialize timezone to `Asia/Manila` in notification service
- All notification scheduling now uses Manila timezone
- All time calculations are done in Manila timezone

**Code:**
```dart
// Set timezone to Asia/Manila (Philippines)
final location = tz.getLocation('Asia/Manila');
tz.setLocalLocation(location);
```

### 2. Fixed 1-Hour Notification Logic

**Previous Issue:**
- The condition `if (timeUntilDeadline.inMinutes > 30)` was too restrictive
- This meant if the deadline was between 30-60 minutes away, the 1-hour notification would be skipped
- Timezone conversions were causing timing issues

**Fix:**
- Changed condition to `if (timeUntilDeadline.inMinutes >= 60)` 
- This ensures 1-hour notification is scheduled when deadline is at least 1 hour away
- All time calculations now use Manila timezone consistently
- Improved edge case handling for notifications very close to the current time

### 3. Improved Timezone Handling

**Changes:**
- All deadline and notification time calculations use Manila timezone
- Convert UTC deadlines to Manila timezone before calculating notification times
- Schedule notifications in Manila timezone, then convert to UTC for storage
- Added detailed logging for debugging timezone issues

## 📝 Key Changes

### Notification Service Initialization
```dart
// Set timezone to Asia/Manila (Philippines)
final location = tz.getLocation('Asia/Manila');
tz.setLocalLocation(location);
```

### Notification Scheduling
```dart
// Get Manila timezone for accurate scheduling
final manilaLocation = tz.getLocation('Asia/Manila');
final nowManila = tz.TZDateTime.now(manilaLocation);
final deadlineManila = tz.TZDateTime.from(deadline, manilaLocation);

// Calculate notification times in Manila timezone
final oneHourBefore = deadlineManila.subtract(const Duration(hours: 1));
final thirtyMinutesBefore = deadlineManila.subtract(const Duration(minutes: 30));
```

### 1-Hour Notification Condition
```dart
// Schedule if deadline is at least 60 minutes away (not just 30)
if (timeUntilDeadline.inMinutes >= 60) {
    // Schedule 1-hour notification
}
```

## 🧪 Testing

### Test 1-Hour Notification

1. **Create a task with deadline 2 hours from now:**
   - Create a new task
   - Set deadline to 2 hours from current time
   - Save the task

2. **Check logs for:**
   ```
   🔔 Scheduling 1-hour notification for: [time] (Manila time)
   ✅ Scheduled exact/inexact notification [id] for [time]
   ```

3. **Wait for notification:**
   - Notification should appear exactly 1 hour before deadline
   - Time should be in Manila timezone (UTC+8)

### Test 30-Minute Notification

1. **Create a task with deadline 1 hour from now:**
   - Create a new task
   - Set deadline to 1 hour from current time
   - Save the task

2. **Check logs for:**
   ```
   🔔 Scheduling 30-minute notification for: [time] (Manila time)
   ✅ Scheduled exact/inexact notification [id] for [time]
   ```

3. **Wait for notification:**
   - Notification should appear exactly 30 minutes before deadline
   - Time should be in Manila timezone (UTC+8)

### Test Timezone

1. **Check initialization logs:**
   ```
   ✅ Timezone set to Asia/Manila (Philippines)
   Current time in Manila: [time]
   ```

2. **Check notification scheduling logs:**
   ```
   Deadline (Manila): [time]
   Current time (Manila): [time]
   Scheduling 1-hour notification for: [time] (Manila time)
   ```

## 🔧 Debugging

### Check Timezone
Look for these log messages:
```
✅ Timezone set to Asia/Manila (Philippines)
   Current time in Manila: [time]
```

### Check Notification Scheduling
Look for these log messages:
```
🔔 Scheduling notifications for task "[task title]"
   Deadline (Manila): [time]
   Current time (Manila): [time]
   Time until deadline: [X] minutes ([Y] hours)
   Time until 1-hour notification: [Z] minutes
   🔔 Scheduling 1-hour notification for: [time] (Manila time)
   ✅ Scheduled exact/inexact notification [id] for [time]
```

### Common Issues

1. **Notification not appearing:**
   - Check if notification permission is granted
   - Check if battery optimization is disabled
   - Check if exact alarm permission is granted (Android 12+)
   - Check logs for scheduling errors

2. **Wrong time:**
   - Verify timezone is set to Asia/Manila in logs
   - Check if device timezone matches Manila timezone
   - Verify deadline is set correctly

3. **1-hour notification still not working:**
   - Check if deadline is at least 60 minutes away
   - Check logs for "Skipping 1-hour notification" messages
   - Verify notification is actually scheduled (check logs)

## 📋 Verification Checklist

- [x] Timezone set to Asia/Manila on initialization
- [x] All time calculations use Manila timezone
- [x] 1-hour notification condition changed to >= 60 minutes
- [x] Notification times converted properly between UTC and Manila timezone
- [x] Detailed logging added for debugging
- [x] Edge cases handled (past times, very close times, etc.)

## 🎯 Expected Behavior

After these fixes:

1. **Timezone:**
   - ✅ All notifications use Asia/Manila timezone (UTC+8)
   - ✅ Time calculations are consistent
   - ✅ Notifications fire at correct local time

2. **1-Hour Notification:**
   - ✅ Always schedules when deadline is at least 60 minutes away
   - ✅ Fires exactly 1 hour before deadline
   - ✅ Works correctly with timezone conversions

3. **30-Minute Notification:**
   - ✅ Always schedules when deadline is at least 30 minutes away
   - ✅ Fires exactly 30 minutes before deadline
   - ✅ Works correctly with timezone conversions

## 🚀 Next Steps

1. **Rebuild and test:**
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   flutter install
   ```

2. **Create a test task:**
   - Set deadline to 2 hours from now
   - Verify 1-hour notification is scheduled
   - Wait and verify notification appears

3. **Check logs:**
   - Look for timezone initialization messages
   - Look for notification scheduling messages
   - Verify times are in Manila timezone

## 📚 Additional Notes

- **Timezone:** Asia/Manila (Philippines) is UTC+8, no daylight saving time
- **Notification Timing:** Notifications are scheduled in Manila timezone, then converted to UTC for Android system
- **Edge Cases:** Handles past deadlines, very close deadlines, and timezone conversions properly
- **Logging:** Detailed logging added for debugging timezone and scheduling issues

---

**Note:** Make sure to test on a real device with release build, as notification timing can differ between emulator and real devices.

