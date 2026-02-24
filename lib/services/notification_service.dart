import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'dart:async';
import 'dart:io';

/// Notification Service
/// Handles scheduling and canceling local notifications for task deadlines
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  static const MethodChannel _channel = MethodChannel('notification_permissions');

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('Notification service already initialized');
      return;
    }

    debugPrint('Initializing notification service...');

    // Initialize timezone data
    tz_data.initializeTimeZones();
    
    // Set timezone to Asia/Manila (Philippines)
    try {
      final location = tz.getLocation('Asia/Manila');
      tz.setLocalLocation(location);
      debugPrint('✅ Timezone set to Asia/Manila (Philippines)');
      debugPrint('   Current time in Manila: ${tz.TZDateTime.now(location)}');
    } catch (e) {
      debugPrint('⚠️ Warning: Could not set timezone to Asia/Manila: $e');
      debugPrint('   Using device local timezone instead');
      debugPrint('   Current local time: ${tz.TZDateTime.now(tz.local)}');
    }
    
    debugPrint('Timezone data initialized');

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Initialize plugin
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    debugPrint('Notification plugin initialized: $initialized');

    // Request permissions and create channel for Android
    await _requestPermissions();
    
    // Request battery optimization exemption for Android
    if (Platform.isAndroid) {
      await requestBatteryOptimizationExemption();
    }

    // Check permissions status
    final hasPermissions = await arePermissionsGranted();
    debugPrint('Notification permissions status: $hasPermissions');
    
    if (!hasPermissions && Platform.isAndroid) {
      debugPrint('⚠️ WARNING: Notification permissions not granted!');
      debugPrint('   For real devices: Go to Settings > Apps > Your App > Notifications > Enable');
      debugPrint('   The app will request permissions when scheduling notifications.');
    }

    _initialized = true;
    debugPrint('Notification service initialization complete');
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        // Request notification permission (Android 13+)
        final granted = await androidImplementation
            .requestNotificationsPermission();
        debugPrint('Notification permission granted: $granted');

        // Create notification channel (required for Android 8.0+)
        // Use maximum importance for real devices to ensure notifications are shown
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'task_reminders',
            'Task Reminders',
            description: 'Notifications for task deadlines',
            importance: Importance.max, // Changed from high to max for better visibility on real devices
            playSound: true,
            enableVibration: true,
            enableLights: true,
            showBadge: true,
          ),
        );
        debugPrint('✅ Notification channel created successfully with MAX importance');
        
        // Request exact alarm permission for Android 12+ (if not already granted)
        if (Platform.isAndroid) {
          try {
            // Check if exact alarm permission is available
            final canScheduleExactAlarms = await androidImplementation
                .canScheduleExactNotifications();
            debugPrint('Can schedule exact alarms: $canScheduleExactAlarms');
            
            if (canScheduleExactAlarms == false) {
              debugPrint('⚠️ Exact alarm permission not granted. Requesting permission...');
              // Request exact alarm permission
              try {
                await androidImplementation.requestExactAlarmsPermission();
                debugPrint('✅ Requested exact alarm permission');
              } catch (e) {
                debugPrint('⚠️ Could not request exact alarm permission: $e');
                debugPrint('   User needs to grant "Schedule exact alarms" permission in app settings.');
              }
            } else {
              debugPrint('✅ Exact alarm permission already granted');
            }
          } catch (e) {
            debugPrint('Could not check exact alarm permission: $e');
          }
        }
      }
    }
  }

  /// Request battery optimization exemption
  /// This is critical for notifications to work on real devices
  Future<void> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return;
    
    try {
      final result = await _channel.invokeMethod<bool>('requestBatteryOptimizationExemption');
      if (result == true) {
        debugPrint('✅ Battery optimization exemption granted');
      } else {
        debugPrint('⚠️ Battery optimization exemption not granted. Notifications may not work when app is closed.');
        debugPrint('   User should disable battery optimization for this app in system settings.');
      }
    } catch (e) {
      debugPrint('⚠️ Could not request battery optimization exemption: $e');
      debugPrint('   This is normal if the method channel is not implemented.');
    }
  }

  /// Check if notification permissions are granted
  Future<bool> arePermissionsGranted() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        final granted = await androidImplementation.areNotificationsEnabled();
        debugPrint('Notifications enabled: $granted');
        return granted ?? false;
      }
    }
    return true; // iOS/other platforms
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap if needed
    debugPrint('Notification tapped: ${response.id}');
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // Check both old key (for migration) and new key
    final oldValue = prefs.getBool('notifications');
    final newValue = prefs.getBool('notifications_enabled');
    
    // If old key exists, migrate to new key
    if (oldValue != null && newValue == null) {
      await prefs.setBool('notifications_enabled', oldValue);
      await prefs.remove('notifications');
      return oldValue;
    }
    
    return newValue ?? true;
  }

  /// Set notifications enabled/disabled
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
  }

  /// Schedule notifications for a task (1 hour and 30 minutes before deadline)
  /// This will work from anywhere - dashboard, home, or any screen
  /// Notifications are scheduled in the system and will fire even if app is closed
  Future<void> scheduleTaskNotifications({
    required int taskId,
    required String taskTitle,
    required DateTime deadline,
  }) async {
    // Check if notifications are enabled
    if (!await areNotificationsEnabled()) {
      debugPrint('🔔 Notifications are disabled in settings');
      return;
    }

    // Get Manila timezone for accurate scheduling
    final manilaLocation = tz.getLocation('Asia/Manila');
    final nowManila = tz.TZDateTime.now(manilaLocation);
    final deadlineManila = tz.TZDateTime.from(deadline, manilaLocation);

    // Don't schedule if deadline is in the past (check in Manila timezone)
    if (deadlineManila.isBefore(nowManila)) {
      debugPrint('🔔 Deadline is in the past (Manila time), skipping notification scheduling for task "$taskTitle"');
      debugPrint('   Deadline: ${deadlineManila.toString()}');
      debugPrint('   Now: ${nowManila.toString()}');
      return;
    }
    
    // Calculate notification times in Manila timezone
    final oneHourBefore = deadlineManila.subtract(const Duration(hours: 1));
    final thirtyMinutesBefore = deadlineManila.subtract(const Duration(minutes: 30));
    final timeUntilDeadline = deadlineManila.difference(nowManila);
    final timeUntilOneHour = oneHourBefore.difference(nowManila);
    final timeUntilThirtyMin = thirtyMinutesBefore.difference(nowManila);

    debugPrint('🔔 Scheduling notifications for task "$taskTitle"');
    debugPrint('   Task ID: $taskId');
    debugPrint('   Deadline (UTC): ${deadline.toString()}');
    debugPrint('   Deadline (Manila): ${deadlineManila.toString()}');
    debugPrint('   Current time (Manila): ${nowManila.toString()}');
    debugPrint('   Time until deadline: ${timeUntilDeadline.inMinutes} minutes (${timeUntilDeadline.inHours} hours)');
    debugPrint('   Time until 1-hour notification: ${timeUntilOneHour.inMinutes} minutes');
    debugPrint('   Time until 30-minute notification: ${timeUntilThirtyMin.inMinutes} minutes');

    // Schedule 1 hour before notification
    // IMPORTANT: Schedule if deadline is MORE than 1 hour away (not just 30 minutes)
    // This ensures the 1-hour notification always fires when there's at least 1 hour until deadline
    if (timeUntilDeadline.inMinutes >= 60) {
      final minutesUntilNotification = timeUntilOneHour.inMinutes;
      
      // If the 1-hour-before time is in the past (more than 1 minute ago), skip it
      if (minutesUntilNotification < -1) {
        debugPrint(
          '⏭️ Skipping 1-hour notification: notification time is ${minutesUntilNotification.abs()} minutes in the past',
        );
      }
      // If the 1-hour-before time is exactly now or very close (within 1 minute),
      // show the notification immediately
      else if (minutesUntilNotification <= 1 && minutesUntilNotification >= -1) {
        debugPrint(
          '🔔 1-hour notification time is now (or very close), showing immediately',
        );
        await showImmediateNotification(
          title: 'Task Reminder',
          body: 'You have 1 hour left to complete "$taskTitle"',
        );
      }
      // If the 1-hour-before time is very close (1-5 minutes), schedule it for a few minutes from now
      else if (minutesUntilNotification > 1 && minutesUntilNotification < 5) {
        final notificationTime = nowManila.add(const Duration(minutes: 2));
        debugPrint(
          '⚠️ 1-hour notification time is very close ($minutesUntilNotification minutes), scheduling for 2 minutes from now to ensure delivery',
        );
        
        await _scheduleNotification(
          id: taskId * 10 + 1, // Unique ID for 1-hour notification
          title: 'Task Reminder',
          body: 'You have 1 hour left to complete "$taskTitle"',
          scheduledDate: notificationTime.toUtc(),
        );
      }
      // Normal case: schedule for exactly 1 hour before (if it's in the future)
      else if (oneHourBefore.isAfter(nowManila)) {
        debugPrint(
          '🔔 Scheduling 1-hour notification for: ${oneHourBefore.toString()} (Manila time)',
        );
        debugPrint('   (${timeUntilOneHour.inMinutes} minutes from now)');
        
        await _scheduleNotification(
          id: taskId * 10 + 1, // Unique ID for 1-hour notification
          title: 'Task Reminder',
          body: 'You have 1 hour left to complete "$taskTitle"',
          scheduledDate: oneHourBefore.toUtc(),
        );
      } else {
        debugPrint(
          '⏭️ Skipping 1-hour notification: notification time is in the past',
        );
      }
    } else {
      debugPrint(
        '⏭️ Skipping 1-hour notification: deadline is only ${timeUntilDeadline.inMinutes} minutes away (need at least 60 minutes)',
      );
    }

    // Schedule 30 minutes before notification
    // Schedule if deadline is 30 minutes or more away
    if (timeUntilDeadline.inMinutes >= 30) {
      final minutesUntilNotification = timeUntilThirtyMin.inMinutes;
      
      // If the 30-minute-before time is in the past (more than 1 minute ago), skip it
      if (minutesUntilNotification < -1) {
        debugPrint(
          '⏭️ Skipping 30-minute notification: notification time is ${minutesUntilNotification.abs()} minutes in the past',
        );
      }
      // If the 30-minute-before time is exactly now or very close (within 1 minute),
      // show the notification immediately
      else if (minutesUntilNotification <= 1 && minutesUntilNotification >= -1) {
        debugPrint(
          '🔔 30-minute notification time is now (or very close), showing immediately',
        );
        await showImmediateNotification(
          title: 'Task Reminder',
          body: 'You have 30 minutes left to complete "$taskTitle"',
        );
      }
      // If the 30-minute-before time is very close (1-5 minutes), schedule it for a few minutes from now
      else if (minutesUntilNotification > 1 && minutesUntilNotification < 5) {
        final notificationTime = nowManila.add(const Duration(minutes: 2));
        debugPrint(
          '⚠️ 30-minute notification time is very close ($minutesUntilNotification minutes), scheduling for 2 minutes from now to ensure delivery',
        );
        
        await _scheduleNotification(
          id: taskId * 10 + 2, // Unique ID for 30-minute notification
          title: 'Task Reminder',
          body: 'You have 30 minutes left to complete "$taskTitle"',
          scheduledDate: notificationTime.toUtc(),
        );
      }
      // Normal case: schedule for exactly 30 minutes before (if it's in the future)
      else if (thirtyMinutesBefore.isAfter(nowManila)) {
        debugPrint(
          '🔔 Scheduling 30-minute notification for: ${thirtyMinutesBefore.toString()} (Manila time)',
        );
        debugPrint('   (${timeUntilThirtyMin.inMinutes} minutes from now)');
        
        await _scheduleNotification(
          id: taskId * 10 + 2, // Unique ID for 30-minute notification
          title: 'Task Reminder',
          body: 'You have 30 minutes left to complete "$taskTitle"',
          scheduledDate: thirtyMinutesBefore.toUtc(),
        );
      } else {
        debugPrint(
          '❌ Cannot schedule 30-minute notification: notification time is in the past',
        );
      }
    } else {
      debugPrint(
        '⏭️ Skipping 30-minute notification: deadline is only ${timeUntilDeadline.inMinutes} minutes away (need at least 30 minutes)',
      );
    }

    debugPrint('✅ Notification scheduling complete for task "$taskTitle"');
  }

  /// Schedule a single notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Ensure service is initialized
    if (!_initialized) {
      debugPrint('Notification service not initialized, initializing now...');
      await initialize();
    }

    // Check permissions and request if needed (especially for real devices)
    bool hasPermissions = await arePermissionsGranted();
    if (!hasPermissions && Platform.isAndroid) {
      debugPrint('⚠️ Notification permissions not granted, requesting...');
      await _requestPermissions();
      hasPermissions = await arePermissionsGranted();
      
      if (!hasPermissions) {
        debugPrint('❌ WARNING: Notification permissions still not granted after request!');
        debugPrint('   For real devices: Go to Settings > Apps > Your App > Notifications > Enable');
        debugPrint('   Notifications may not work until permissions are granted.');
        // Don't return - try to schedule anyway, some devices allow scheduling without explicit permission
      }
    }

    final now = DateTime.now();
    final duration = scheduledDate.difference(now);

    debugPrint('Attempting to schedule notification:');
    debugPrint('  ID: $id');
    debugPrint('  Title: $title');
    debugPrint('  Scheduled for: ${scheduledDate.toString()}');
    debugPrint('  Current time: ${now.toString()}');
    debugPrint(
      '  Time until: ${duration.inMinutes} minutes (${duration.inSeconds} seconds)',
    );

    // If the scheduled time is in the past, don't schedule
    if (duration.isNegative) {
      debugPrint(
        'ERROR: Cannot schedule notification in the past: $scheduledDate',
      );
      return;
    }

    // For very short durations (less than 1 minute), use immediate notification
    if (duration.inSeconds < 60) {
      debugPrint(
        'Notification is less than 1 minute away, showing immediately',
      );
      await showImmediateNotification(title: title, body: body);
      return;
    }

    // Android notification details
    // Use max importance and high priority for better visibility on real devices
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Notifications for task deadlines',
          importance: Importance.max, // Changed from high to max for real devices
          priority: Priority.max, // Changed from high to max for real devices
          showWhen: true,
          enableVibration: true,
          playSound: true,
          enableLights: true,
          ongoing: false,
          autoCancel: true,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.reminder, // Helps with Do Not Disturb mode
        );

    // iOS notification details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Convert DateTime to TZDateTime using Asia/Manila timezone
    final manilaLocation = tz.getLocation('Asia/Manila');
    final scheduledTZ = tz.TZDateTime.from(scheduledDate, manilaLocation);
    debugPrint('TZDateTime (Manila): ${scheduledTZ.toString()}');
    debugPrint('   Scheduled time in Manila: ${scheduledTZ.toString()}');
    debugPrint('   Current time in Manila: ${tz.TZDateTime.now(manilaLocation).toString()}');

    try {
      // Check if exact alarms are allowed
      bool useExactAlarm = false;
      if (Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidImplementation != null) {
          try {
            final canScheduleExact = await androidImplementation.canScheduleExactNotifications();
            useExactAlarm = canScheduleExact ?? false;
            if (!useExactAlarm) {
              debugPrint('⚠️ Exact alarms not available, using inexact scheduling');
              debugPrint('   This is normal for devices without exact alarm permission.');
            } else {
              debugPrint('✅ Exact alarms available');
            }
          } catch (e) {
            debugPrint('⚠️ Could not check exact alarm permission: $e');
            useExactAlarm = false;
          }
        }
      }
      
      // Try to schedule with exact alarm first (Android 12+)
      // Use inexactAllowWhileIdle as default for better compatibility
      final scheduleMode = useExactAlarm 
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
      
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTZ,
        notificationDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint(
        '✅ Scheduled ${useExactAlarm ? "exact" : "inexact"} notification $id for ${scheduledDate.toString()} (in ${duration.inMinutes} minutes)',
      );
    } catch (e) {
      // If exact alarm permission is not granted, fall back to inexact scheduling
      if (e.toString().contains('exact_alarm_not_permitted') ||
          e.toString().contains('SCHEDULE_EXACT_ALARM')) {
        debugPrint(
          '⚠️ Exact alarm permission not granted, using inexact scheduling: $e',
        );

        try {
          // Fall back to inexact scheduling (doesn't require permission)
          await _notificationsPlugin.zonedSchedule(
            id,
            title,
            body,
            scheduledTZ,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );

          debugPrint(
            '✅ Scheduled inexact notification $id for ${scheduledDate.toString()} (in ${duration.inMinutes} minutes)',
          );
        } catch (fallbackError) {
          debugPrint(
            '❌ Failed to schedule notification (both exact and inexact): $fallbackError',
          );

          // As a last resort, try showing immediately for testing
          debugPrint(
            'Attempting to show notification immediately as fallback...',
          );
          try {
            await showImmediateNotification(title: title, body: body);
          } catch (immediateError) {
            debugPrint(
              '❌ Failed to show immediate notification: $immediateError',
            );
          }
        }
      } else {
        debugPrint('❌ Error scheduling notification: $e');
        // Try immediate notification as fallback
        try {
          await showImmediateNotification(title: title, body: body);
          debugPrint('Showed notification immediately as fallback');
        } catch (immediateError) {
          debugPrint(
            '❌ Failed to show immediate notification: $immediateError',
          );
        }
      }
    }
  }

  /// Cancel all notifications for a task
  Future<void> cancelTaskNotifications(int taskId) async {
    // Cancel all notifications (1 hour and 30 minutes)
    await _notificationsPlugin.cancel(taskId * 10 + 1); // 1-hour notification
    await _notificationsPlugin.cancel(taskId * 10 + 2); // 30-minute notification
    debugPrint('🗑️ Cancelled all notifications for task $taskId');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Show immediate notification (for testing)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Notifications for task deadlines',
          importance: Importance.max, // Changed from high to max for real devices
          priority: Priority.max, // Changed from high to max for real devices
          category: AndroidNotificationCategory.reminder,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      notificationDetails,
    );
  }
}
