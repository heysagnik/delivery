import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import '../providers/order_provider.dart';
import '../models/order_model.dart';
import '../screens/order_alert_screen.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp();
  await NotificationService.instance.initialize();

  // We can't show fullscreen alerts from background handler,
  // so we'll show a regular notification that the user can tap
  if (message.data.containsKey('type') && message.data['type'] == 'new_order') {
    await NotificationService.instance.showNotification(message);
  }
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Global navigator key to access context from anywhere
  static GlobalKey<NavigatorState>? navigatorKey;

  // Audio player for alert sound
  AudioPlayer? _audioPlayer;

  /// Initializes notification service
  Future<void> initialize({BuildContext? context}) async {
    try {
      debugPrint("Initializing NotificationService...");

      // Ensure Firebase is initialized before any operations
      await Firebase.initializeApp();
      await _fetchAndSaveFCMToken();

      // Configure Firebase messaging
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      await requestPermission();
      await initLocalNotifications();
      await setupMessageHandlers();
      await _checkNotificationLaunch();

      // Initialize audio player for alerts
      _audioPlayer = AudioPlayer();
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
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('User granted provisional notification permissions');
      } else {
        debugPrint(
            'User declined or has not accepted notification permissions');
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

    // Create special channel for order alerts with custom sound
    var orderChannel = AndroidNotificationChannel(
      'new_order_channel',
      'New Order Alerts',
      description: 'Used for new order notifications.',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('order_alert'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
    );

    // Initialize Android implementation
    final androidImplementation =
    _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Create notification channels
      await androidImplementation.createNotificationChannel(channel);
      await androidImplementation.createNotificationChannel(orderChannel);
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

    // Determine if it's a new order notification
    final isNewOrder =
        message.data.containsKey('type') && message.data['type'] == 'new_order';

    // Use title and body from notification object, or provide defaults for order alerts
    final title = notification?.title ??
        (isNewOrder ? 'New Order Available!' : 'New Notification');
    final body =
        notification?.body ?? (isNewOrder ? 'Tap to view order details' : '');

    try {
      await _localNotifications.show(
        notification?.hashCode ??
            DateTime
                .now()
                .millisecondsSinceEpoch
                .hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            isNewOrder ? 'new_order_channel' : 'high_importance_channel',
            isNewOrder ? 'New Order Alerts' : 'High Importance Notifications',
            channelDescription: isNewOrder
                ? 'Used for new order notifications.'
                : 'Used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            visibility: NotificationVisibility.public,
            autoCancel: true,
            // Special configurations for order notifications
            sound: isNewOrder
                ? const RawResourceAndroidNotificationSound('order_alert')
                : null,
            vibrationPattern: isNewOrder
                ? Int64List.fromList([0, 500, 200, 500, 200, 500])
                : null,
            fullScreenIntent: isNewOrder,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: isNewOrder
            ? message.data['order_data'] ?? ''
            : message.data['driverId']?.toString() ?? '',
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

      // Check if it's a new order notification
      if (message.data.containsKey('type') &&
          message.data['type'] == 'new_order') {
        _handleNewOrderNotification(message);
      } else {
        // Regular notification for other types
        showNotification(message);
      }
    });

    // App opened from notification handler
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint("Notification clicked, app opened.");

      // Check if it's a new order notification
      if (message.data.containsKey('type') &&
          message.data['type'] == 'new_order') {
        _handleNewOrderNotification(message);
      } else {
        // Handle normal notification tap
        handleNotificationAction(NotificationResponse(
          payload: message.data['driverId'],
          notificationResponseType:
          NotificationResponseType.selectedNotificationAction,
        ));
      }
    });
  }

  /// Handles new order notifications with fullscreen alert
  void _handleNewOrderNotification(RemoteMessage message) async {
    try {
      // Parse order data from message
      if (message.data.containsKey('order_data')) {
        final orderData = json.decode(message.data['order_data']);
        final Order newOrder = Order.fromJson(orderData);

        // Show fullscreen alert if app is in foreground and we have a navigator context
        if (navigatorKey?.currentContext != null) {
          _showOrderAlert(navigatorKey!.currentContext!, newOrder);
        } else {
          // Fallback to regular notification if no context available
          showNotification(message);
        }
      } else {
        // Fallback if message doesn't contain order data
        showNotification(message);
      }
    } catch (e) {
      debugPrint('Error handling new order notification: $e');
      showNotification(message);
    }
  }

  /// Shows the fullscreen order alert dialog
  void _showOrderAlert(BuildContext context, Order order) {
    // Play alert sound
    _playAlertSound();

    // Trigger vibration
    HapticFeedback.heavyImpact();

    // Show fullscreen alert
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) =>
            OrderAlertScreen(
              order: order,
              onAccept: () async {
                // Stop alert sound
                _stopAlertSound();

                // Get the order provider
                final orderProvider =
                Provider.of<OrderProvider>(context, listen: false);

                // Accept the order
                await orderProvider.assignOrder(order.id);
                await orderProvider.pendingOrderByDriver();

                // Close the alert
                Navigator.of(context).pop();

                // Navigate to the appropriate screen
                Navigator.pushReplacementNamed(context, '/availableDelivery');
              },
              onDecline: () {
                // Stop alert sound
                _stopAlertSound();

                // Just close the alert
                Navigator.of(context).pop();
              },
              timeoutSeconds: 30,
            ),
      ),
    );
  }

  /// Plays the alert sound in a loop
  void _playAlertSound() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.play(AssetSource('assets/sound/alarm2.mp3'));
        _audioPlayer!.setReleaseMode(ReleaseMode.loop);
      }
    } catch (e) {
      debugPrint('Error playing alert sound: $e');
    }
  }

  /// Stops the alert sound
  void _stopAlertSound() {
    try {
      _audioPlayer?.stop();
    } catch (e) {
      debugPrint('Error stopping alert sound: $e');
    }
  }

  /// Handles notification when app was launched from a notification
  Future<void> _checkNotificationLaunch() async {
    final details = await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.getNotificationAppLaunchDetails();

    if (details?.didNotificationLaunchApp ?? false) {
      debugPrint("App launched via notification.");

      final payload = details?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        try {
          // Check if it's an order notification payload (which would be JSON)
          final orderData = json.decode(payload);
          if (orderData != null && navigatorKey?.currentContext != null) {
            // Delay a bit to ensure app is fully initialized
            await Future.delayed(const Duration(milliseconds: 500));
            final Order newOrder = Order.fromJson(orderData);
            _showOrderAlert(navigatorKey!.currentContext!, newOrder);
          }
        } catch (e) {
          // Not an order payload or invalid JSON
          debugPrint('Payload is not an order notification: $e');
        }
      }
    }
  }

  /// Handles user actions on notification (if any)
  void handleNotificationAction(NotificationResponse response) {
    debugPrint("User tapped on notification with payload: ${response.payload}");
    final payload = response.payload;

    if (payload != null && payload.isNotEmpty) {
      try {
        // Check if it's an order notification payload
        final orderData = json.decode(payload);
        if (orderData != null && navigatorKey?.currentContext != null) {
          final Order newOrder = Order.fromJson(orderData);
          _showOrderAlert(navigatorKey!.currentContext!, newOrder);
        }
      } catch (e) {
        // Not an order payload or invalid JSON
        debugPrint('Payload is not an order notification: $e');
      }
    }
  }
}
