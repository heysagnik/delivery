import 'dart:convert';
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
import '../providers/order_provider.dart';
import '../models/order_model.dart';
import '../screens/order_alert_screen.dart';

// Channel and notification-related constants for scalability
class NotificationConstants {
  static const String highImportanceChannelId = 'high_importance_channel';
  static const String highImportanceChannelName =
      'High Importance Notifications';
  static const String highImportanceChannelDescription =
      'Used for important notifications.';

  static const String newOrderChannelId = 'new_order_channel';
  static const String newOrderChannelName = 'New Order Alerts';
  static const String newOrderChannelDescription =
      'Used for new order notifications.';

  static const String orderAlertSound = 'order_alert';
  static final Int64List newOrderVibrationPattern =
  Int64List.fromList([0, 500, 200, 500, 200, 500]);

  // Use this key to store pending order data in SharedPreferences
  static const String pendingOrderKey = 'pending_order_data';
  static const String pendingOrderTimeKey = 'pending_order_time';
  static const int orderExpirationTimeMinutes =
  5; // Orders expire after 5 minutes
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // Process new order notifications
  if (message.data['type'] == 'new_order' &&
      message.data.containsKey('order_data')) {
    // Store the order data in SharedPreferences so it can be retrieved when the app launches
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        NotificationConstants.pendingOrderKey, message.data['order_data']);
    await prefs.setInt(NotificationConstants.pendingOrderTimeKey,
        DateTime
            .now()
            .millisecondsSinceEpoch);

    // Initialize notification service to handle notifications
    await NotificationService.instance.initialize();

    // Show a silent notification that will be used to trigger the full-screen intent
    await NotificationService.instance.showSilentNotification();
  }
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool _alertCurrentlyShowing = false;

  // Global navigator key to access context from anywhere
  static GlobalKey<NavigatorState>? navigatorKey;

  AudioPlayer? _audioPlayer;
  Timer? _backgroundAudioTimer;

  /// Initializes the notification service
  Future<void> initialize({BuildContext? context}) async {
    try {
      debugPrint("Initializing NotificationService...");
      if (!_isInitialized) {
        await Firebase.initializeApp();
        await _fetchAndSaveFCMToken();
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);
        await requestPermission();
        await _initLocalNotifications();
        await setupMessageHandlers();
        _audioPlayer = AudioPlayer();
        _isInitialized = true;
      }

      // Check for pending order notifications on app startup with a slight delay
      // to ensure context is available
      Future.delayed(const Duration(milliseconds: 500), () {
        _checkPendingOrders();
      });
    } catch (e, stackTrace) {
      debugPrint('NotificationService initialization error: $e\n$stackTrace');
    }
  }

  /// Fetches and stores FCM token in SharedPreferences
  Future<void> _fetchAndSaveFCMToken() async {
    try {
      final token = await messaging.getToken();
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcmToken', token);
        debugPrint('FCM Token saved: $token');
      }
    } catch (e) {
      debugPrint('Error fetching FCM Token: $e');
    }
  }

  /// Requests notification permissions with high priority
  Future<void> requestPermission() async {
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        carPlay: true,
        criticalAlert: true,
        // Important for sound even in Do Not Disturb mode
        provisional: false,
        announcement: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted full notification permissions');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('User granted provisional notification permissions');
      } else {
        debugPrint('User declined notification permissions');
      }
    } catch (e) {
      debugPrint('Permission request error: $e');
    }
  }

  /// Initializes local notifications with extracted configuration
  Future<void> _initLocalNotifications() async {
    // Create the Android channels
    await _createAndroidNotificationChannels();

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      // Important: This handles when notifications launch the app
      onDidReceiveBackgroundNotificationResponse:
      _handleBackgroundNotificationResponse,
    );

    debugPrint("Local notifications initialized.");
  }

  /// Helper method to create Android notification channels
  Future<void> _createAndroidNotificationChannels() async {
    const channel = AndroidNotificationChannel(
      NotificationConstants.highImportanceChannelId,
      NotificationConstants.highImportanceChannelName,
      description: NotificationConstants.highImportanceChannelDescription,
      importance: Importance.high,
    );

    var orderChannel = AndroidNotificationChannel(
      NotificationConstants.newOrderChannelId,
      NotificationConstants.newOrderChannelName,
      description: NotificationConstants.newOrderChannelDescription,
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(
          NotificationConstants.orderAlertSound),
      enableVibration: true,
      vibrationPattern: NotificationConstants.newOrderVibrationPattern,
    );

    final androidImpl =
    _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(channel);
      await androidImpl.createNotificationChannel(orderChannel);
    }
  }

  /// Display a silent notification that triggers the full-screen intent
  Future<void> showSilentNotification() async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        NotificationConstants.newOrderChannelId,
        NotificationConstants.newOrderChannelName,
        channelDescription: NotificationConstants.newOrderChannelDescription,
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.call,
        visibility: NotificationVisibility.public,
        playSound: false,
        // The sound will be handled separately by the app
        autoCancel: false,
        ongoing: true,
      );

      const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

      await _localNotifications.show(
        0, // Using a fixed ID for order notifications
        'New Order Available',
        'Tap to view details',
        platformChannelSpecifics,
        payload: 'order_notification',
      );
    } catch (e) {
      debugPrint('Error showing silent notification: $e');
    }
  }

  /// Sets up Firebase message handlers for foreground and opened notifications
  Future<void> setupMessageHandlers() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint("Foreground notification: ${message.notification?.title}");
      if (message.data['type'] == 'new_order') {
        _handleNewOrderNotification(message);
      }
    });

    // Handle when app is opened from a background notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint("Notification clicked, app opened.");
      if (message.data['type'] == 'new_order') {
        _handleNewOrderNotification(message);
      }
    });
  }

  /// Handles new order notifications
  void _handleNewOrderNotification(RemoteMessage message) async {
    try {
      if (message.data.containsKey('order_data')) {
        // Store order data in shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            NotificationConstants.pendingOrderKey, message.data['order_data']);
        await prefs.setInt(NotificationConstants.pendingOrderTimeKey,
            DateTime
                .now()
                .millisecondsSinceEpoch);

        final orderData = json.decode(message.data['order_data']);
        final Order newOrder = Order.fromJson(orderData);

        // Show the alert screen directly if we have context
        if (navigatorKey?.currentContext != null && !_alertCurrentlyShowing) {
          _showOrderAlert(navigatorKey!.currentContext!, newOrder);
        } else {
          // Otherwise show a silent notification that will trigger the alert
          showSilentNotification();
        }
      }
    } catch (e) {
      debugPrint('Error handling new order notification: $e');
    }
  }

  /// Check for pending orders stored in SharedPreferences
  Future<void> _checkPendingOrders() async {
    try {
      if (_alertCurrentlyShowing) return;

      final prefs = await SharedPreferences.getInstance();
      final pendingOrderData =
      prefs.getString(NotificationConstants.pendingOrderKey);
      final orderTime =
          prefs.getInt(NotificationConstants.pendingOrderTimeKey) ?? 0;

      // Check if order is still valid (not expired)
      final currentTime = DateTime
          .now()
          .millisecondsSinceEpoch;
      final orderAge =
          (currentTime - orderTime) ~/ (1000 * 60); // Convert to minutes

      if (pendingOrderData != null &&
          pendingOrderData.isNotEmpty &&
          orderAge < NotificationConstants.orderExpirationTimeMinutes) {
        if (navigatorKey?.currentContext != null) {
          final orderData = json.decode(pendingOrderData);
          final Order newOrder = Order.fromJson(orderData);

          _showOrderAlert(navigatorKey!.currentContext!, newOrder);

          // Clear the pending order after showing the alert
          await prefs.remove(NotificationConstants.pendingOrderKey);
          await prefs.remove(NotificationConstants.pendingOrderTimeKey);
        }
      } else if (pendingOrderData != null) {
        // Clean up expired orders
        await prefs.remove(NotificationConstants.pendingOrderKey);
        await prefs.remove(NotificationConstants.pendingOrderTimeKey);
      }
    } catch (e) {
      debugPrint('Error checking pending orders: $e');
    }
  }

  /// Displays the fullscreen order alert dialog
  void _showOrderAlert(BuildContext context, Order order) {
    debugPrint('📱 Showing order alert for Order #${order.orderPK}');

    if (_alertCurrentlyShowing) {
      debugPrint('⚠️ Alert already showing, ignoring request');
      return;
    }

    _alertCurrentlyShowing = true;
    _playAlertSound();
    HapticFeedback.vibrate();

    // Cancel any existing notification
    _localNotifications.cancel(0);

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) =>
            OrderAlertScreen(
              order: order,
              onAccept: () async {
                debugPrint('✅ Order #${order.id} ACCEPTED');

                // First clean up resources
                _stopAlertSound();
                _localNotifications.cancel(0);
                _alertCurrentlyShowing = false;

                try {
                  // Get order provider
                  final orderProvider =
                  Provider.of<OrderProvider>(context, listen: false);

                  // Log current state
                  debugPrint('📋 Assigning order ID: ${order.id}');

                  // Assign order to current driver
                  await orderProvider.assignOrder(order.id);
                  debugPrint('✓ Order assigned successfully');

                  // Fetch pending orders
                  await orderProvider.pendingOrderByDriver();
                  debugPrint('✓ Pending orders fetched');

                  // Navigate to app screen - USING REPLACEMENT
                  if (context.mounted) {
                    debugPrint('🔄 Navigating to app screen');
                    Navigator.pushReplacementNamed(context, '/appScreen');
                  }
                } catch (e) {
                  debugPrint('❌ Error during order acceptance: $e');
                  // Still need to clean up the UI even if the order assignment fails
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              onDecline: () {
                debugPrint('❌ Order #${order.id} DECLINED');
                _stopAlertSound();
                _localNotifications.cancel(0);
                _alertCurrentlyShowing = false;

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
        // Load and play the audio
        await _audioPlayer!.play(AssetSource('assets/sound/alarm2.mp3'));
        _audioPlayer!.setReleaseMode(ReleaseMode.loop);

        // Ensure sound continues playing
        _backgroundAudioTimer?.cancel();
        _backgroundAudioTimer =
            Timer.periodic(const Duration(seconds: 3), (timer) {
              // Check if the audio is still playing
              _audioPlayer!.play(AssetSource('assets/sound/alarm2.mp3'));
            });
      }
    } catch (e) {
      debugPrint('Error playing alert sound: $e');
    }
  }

  /// Stops the alert sound
  void _stopAlertSound() {
    try {
      _audioPlayer?.stop();
      _backgroundAudioTimer?.cancel();
      _backgroundAudioTimer = null;
    } catch (e) {
      debugPrint('Error stopping alert sound: $e');
    }
  }

  /// Static method to handle notification responses in the background
  @pragma('vm:entry-point')
  static void _handleBackgroundNotificationResponse(
      NotificationResponse response) async {
    await NotificationService.instance.initialize();
    await NotificationService.instance._checkPendingOrders();
  }

  /// Handle notification response when app is open
  void _handleNotificationResponse(NotificationResponse response) async {
    debugPrint("Notification response received: ${response.payload}");
    await _checkPendingOrders();
  }

  /// Call this when your app starts to ensure notifications are handled
  Future<void> checkForNotifications() async {
    // Check if app was launched from a notification
    final details = await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.getNotificationAppLaunchDetails();

    if (details?.didNotificationLaunchApp ?? false) {
      debugPrint("App was launched from a notification");
      await _checkPendingOrders();
    }
  }
}
