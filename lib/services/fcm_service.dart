import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

/// Firebase Cloud Messaging Service
/// Handles FCM initialization, token management, and message handling
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;
  bool _initialized = false;

  /// Initialize FCM service
  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('🔥 FCM Service already initialized');
      return;
    }

    debugPrint('🔥 Initializing FCM Service...');

    try {
      // Request notification permissions (Android 13+)
      await _requestNotificationPermissions();

      // Configure notification settings
      await _configureNotificationSettings();

      // Get FCM token
      await getFCMToken();

      // Set up foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Set up message opened handler (when user taps notification)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

      // Check if app was opened from a notification
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🔥 App opened from notification: ${initialMessage.messageId}');
        _handleMessageOpened(initialMessage);
      }

      // Set up token refresh handler
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔥 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        // TODO: Update token on your backend server
      });

      _initialized = true;
      debugPrint('✅ FCM Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing FCM Service: $e');
      rethrow;
    }
  }

  /// Request notification permissions
  Future<void> _requestNotificationPermissions() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), request POST_NOTIFICATIONS permission
      if (await Permission.notification.isDenied) {
        debugPrint('🔥 Requesting notification permission...');
        final status = await Permission.notification.request();
        if (status.isGranted) {
          debugPrint('✅ Notification permission granted');
        } else if (status.isPermanentlyDenied) {
          debugPrint('⚠️ Notification permission permanently denied');
          debugPrint('   User needs to enable notifications in app settings');
        } else {
          debugPrint('⚠️ Notification permission denied');
        }
      } else {
        debugPrint('✅ Notification permission already granted');
      }

      // Also request exact alarm permission for scheduled notifications
      if (await Permission.scheduleExactAlarm.isDenied) {
        debugPrint('🔥 Requesting exact alarm permission...');
        final status = await Permission.scheduleExactAlarm.request();
        if (status.isGranted) {
          debugPrint('✅ Exact alarm permission granted');
        } else {
          debugPrint('⚠️ Exact alarm permission denied');
        }
      }
    } else if (Platform.isIOS) {
      // Request iOS notification permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('🔥 iOS notification permission status: ${settings.authorizationStatus}');
    }
  }

  /// Configure notification settings
  Future<void> _configureNotificationSettings() async {
    // Set notification handler for foreground messages
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications for Android
    if (Platform.isAndroid) {
      final FlutterLocalNotificationsPlugin localNotifications =
          FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      await localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('🔥 Local notification tapped: ${details.id}');
        },
      );

      // Create high importance notification channel for FCM
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
      );

      await localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('🔥 FCM Token: $_fcmToken');
      
      if (_fcmToken == null) {
        debugPrint('⚠️ FCM Token is null. Make sure:');
        debugPrint('   1. Google Services plugin is applied in build.gradle');
        debugPrint('   2. google-services.json is in android/app/');
        debugPrint('   3. SHA-1 and SHA-256 keys are added to Firebase Console');
      }
      
      return _fcmToken;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Handle foreground messages (when app is in foreground)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔥 FCM Foreground Message received: ${message.messageId}');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');

    // Show local notification for foreground messages
    await _showLocalNotification(message);
  }

  /// Show local notification for FCM messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final FlutterLocalNotificationsPlugin localNotifications =
        FlutterLocalNotificationsPlugin();

    // Build notification details
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
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

    // Show notification
    await localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      notificationDetails,
    );
  }

  /// Handle message opened (when user taps notification)
  void _handleMessageOpened(RemoteMessage message) {
    debugPrint('🔥 FCM Message opened: ${message.messageId}');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');

    // TODO: Navigate to specific screen based on message data
    // Example:
    // if (message.data['type'] == 'task') {
    //   Navigator.pushNamed(context, '/task', arguments: message.data['taskId']);
    // }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  /// Get current FCM token
  String? get token => _fcmToken;
}

