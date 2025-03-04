import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../providers/notification_provider.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp();
  await NotificationService.instance.initialize();
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  BuildContext? _context;

  /// Sets the context for provider access
  void setContext(BuildContext context) {
    _context = context;
  }

  /// Initializes notification service
  Future<void> initialize({BuildContext? context}) async {
    try {
      debugPrint("Initializing NotificationService...");

      // Ensure Firebase is initialized before any operations
      await Firebase.initializeApp();

      // Set context if provided
      if (context != null) {
        _context = context;
      }

      await _fetchAndSaveFCMToken();

      // Configure Firebase messaging
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      await requestPermission();
      await initLocalNotifications();
      await setupMessageHandlers();
      await _checkNotificationLaunch();

      // Safely access provider
      if (_context != null) {
        try {
          Provider.of<NotificationProvider>(_context!, listen: false)
              .subscribeNotification();
        } catch (e) {
          debugPrint('Error accessing NotificationProvider: $e');
        }
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  /// Fetches and stores FCM Token in SharedPreferences
  Future<void> _fetchAndSaveFCMToken() async {
    try {
      final token = await messaging.getToken();
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcmToken', token);
        debugPrint('FCM Token saved successfully: $token');
      }
    } catch (e) {
      debugPrint('Error fetching FCM Token: $e');
    }
  }

  /// Requests notification permissions with comprehensive settings
  Future<void> requestPermission() async {
    try {
      // Request Firebase messaging permissions
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        carPlay: true,
        criticalAlert: true,
        provisional: false,
        announcement: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted full notification permissions');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User granted provisional notification permissions');
      } else {
        debugPrint('User declined or has not accepted notification permissions');
      }
    } catch (e) {
      debugPrint('Permission request error: $e');
    }
  }

  /// Initializes local notifications with enhanced configuration
  Future<void> initLocalNotifications() async {
    if (_isInitialized) return;

    // Android Notification Channel with high importance
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Used for important notifications.',
      importance: Importance.high,
    );

    // Initialize Android implementation
    final androidImplementation =
    _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Create notification channel
      await androidImplementation.createNotificationChannel(channel);
    }

    // Initialization settings with sound and alert configurations
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    // Initialize notifications with a callback to handle taps
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: handleNotificationAction,
    );

    _isInitialized = true;
    debugPrint("Local notifications initialized with enhanced settings.");
  }

  /// Displays local notification with enhanced configuration
  Future<void> showNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;
    if (notification == null || android == null) return;

    try {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'Used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: const Color.fromARGB(255, 122, 90, 248),
            visibility: NotificationVisibility.public,
            autoCancel: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['driverId']?.toString() ?? '',
      );
    } catch (e) {
      debugPrint('Error displaying notification: $e');
    }
  }

  /// Sets up Firebase message handlers for foreground & opened messages
  Future<void> setupMessageHandlers() async {
    // Foreground message handler
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
          "Foreground notification received: ${message.notification?.title}");
      showNotification(message);
    });

    // App opened from notification handler
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint("Notification clicked, app opened.");
      handleNotificationAction(NotificationResponse(
        payload: message.data['driverId'],
        notificationResponseType:
        NotificationResponseType.selectedNotificationAction,
      ));
    });
  }

  /// Handles notification when app was launched from a notification
  Future<void> _checkNotificationLaunch() async {
    final details = await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.getNotificationAppLaunchDetails();

    if (details?.didNotificationLaunchApp ?? false) {
      debugPrint("App launched via notification.");
      // TODO: Handle initial notification launch
    }
  }

  /// Handles user actions on notification (if any)
  void handleNotificationAction(NotificationResponse response) {
    debugPrint("User tapped on notification with payload: ${response.payload}");
    // TODO: Implement navigation or action based on payload
  }
}