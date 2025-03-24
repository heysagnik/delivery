import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';
import '../screens/order_alert_screen.dart';

/// ////////////////////////////////////////////////
/// Notification Constants
/// ////////////////////////////////////////////////
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

  static const String pendingOrderKey = 'pending_order_data';
  static const String pendingOrderTimeKey = 'pending_order_time';
  static const int orderExpirationTimeMinutes =
      5; // Orders expire after 5 minutes
}

/// ////////////////////////////////////////////////
/// Background Messaging Handler
/// ////////////////////////////////////////////////
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.data['type'] == 'new_order' &&
      message.data.containsKey('order_data')) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        NotificationConstants.pendingOrderKey, message.data['order_data']);
    await prefs.setInt(NotificationConstants.pendingOrderTimeKey,
        DateTime.now().millisecondsSinceEpoch);

    await NotificationService.instance.initialize();
    await NotificationService.instance.showSilentNotification();
  }
}

/// ////////////////////////////////////////////////
/// Notification Service
/// ////////////////////////////////////////////////
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _alertCurrentlyShowing = false;
  AudioPlayer? _audioPlayer;
  Timer? _backgroundAudioTimer;

  /// Global navigator key to access context anywhere
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Initialization sequence
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
      // Delay checking for pending orders to ensure context availability.
      Future.delayed(const Duration(milliseconds: 500), _checkPendingOrders);
    } catch (e, stackTrace) {
      debugPrint('NotificationService initialization error: $e\n$stackTrace');
    }
  }

  /// Fetch and store the FCM token
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

  /// Request notification permissions
  Future<void> requestPermission() async {
    try {
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
        debugPrint('User declined notification permissions');
      }
    } catch (e) {
      debugPrint('Permission request error: $e');
    }
  }

  /// Initialize local notifications and create channels
  Future<void> _initLocalNotifications() async {
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
      onDidReceiveBackgroundNotificationResponse:
          _handleBackgroundNotificationResponse,
    );
    debugPrint("Local notifications initialized.");
  }

  /// Create Android notification channels
  Future<void> _createAndroidNotificationChannels() async {
    const highChannel = AndroidNotificationChannel(
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
      await androidImpl.createNotificationChannel(highChannel);
      await androidImpl.createNotificationChannel(orderChannel);
    }
  }

  /// Display a silent notification to trigger full-screen intent
  Future<void> showSilentNotification() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        NotificationConstants.newOrderChannelId,
        NotificationConstants.newOrderChannelName,
        channelDescription: NotificationConstants.newOrderChannelDescription,
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.call,
        visibility: NotificationVisibility.public,
        playSound: false,
        autoCancel: false,
        ongoing: true,
      );
      const details = NotificationDetails(android: androidDetails);
      await _localNotifications.show(
        0,
        'New Order Available',
        'Tap to view details',
        details,
        payload: 'order_notification',
      );
    } catch (e) {
      debugPrint('Error showing silent notification: $e');
    }
  }

  /// Set up Firebase messaging handlers
  Future<void> setupMessageHandlers() async {
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint("Foreground notification: ${message.notification?.title}");
      debugPrint("Notification data: ${message.data}");
      if (message.data['type'] == 'new_order') {
        _handleNewOrderNotification(message);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint("Notification clicked, app opened.");
      if (message.data['type'] == 'new_order') {
        _handleNewOrderNotification(message);
      }
    });
  }

  /// Handle new order notifications
  void _handleNewOrderNotification(RemoteMessage message) async {
    try {
      if (message.data.containsKey('order_data')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            NotificationConstants.pendingOrderKey, message.data['order_data']);
        await prefs.setInt(NotificationConstants.pendingOrderTimeKey,
            DateTime.now().millisecondsSinceEpoch);

        final orderData = json.decode(message.data['order_data']);
        final Order newOrder = Order.fromJson(orderData);
        debugPrint(message.data['order_data']);
        debugPrint('New order received: ${newOrder.toString()}');

        if (navigatorKey?.currentContext != null && !_alertCurrentlyShowing) {
          _showOrderAlert(navigatorKey!.currentContext!, newOrder);
        } else {
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

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final orderAge = (currentTime - orderTime) ~/ (1000 * 60);

      if (pendingOrderData != null &&
          pendingOrderData.isNotEmpty &&
          orderAge < NotificationConstants.orderExpirationTimeMinutes) {
        if (navigatorKey?.currentContext != null) {
          final orderData = json.decode(pendingOrderData);
          final Order newOrder = Order.fromJson(orderData);

          _showOrderAlert(navigatorKey!.currentContext!, newOrder);

          await prefs.remove(NotificationConstants.pendingOrderKey);
          await prefs.remove(NotificationConstants.pendingOrderTimeKey);
        }
      } else if (pendingOrderData != null) {
        await prefs.remove(NotificationConstants.pendingOrderKey);
        await prefs.remove(NotificationConstants.pendingOrderTimeKey);
      }
    } catch (e) {
      debugPrint('Error checking pending orders: $e');
    }
  }

  /// Display the fullscreen order alert dialog
  void _showOrderAlert(BuildContext context, Order order) {
    debugPrint('📱 Showing order alert for Order #${order.orderPK}');

    if (_alertCurrentlyShowing) {
      debugPrint('⚠️ Alert already showing, ignoring request');
      return;
    }

    _alertCurrentlyShowing = true;
    _playAlertSound();
    HapticFeedback.vibrate();

    _localNotifications.cancel(0);

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => OrderAlertScreen(
          order: order,
          onAccept: () async {
            debugPrint('✅ Order #${order.id} ACCEPTED');

            _stopAlertSound();
            _localNotifications.cancel(0);
            _alertCurrentlyShowing = false;

            try {
              var orderProvider =
                  Provider.of<OrderProvider>(context, listen: false);

              debugPrint('📋 Assigning order ID: ${order.id}');

              await orderProvider.assignOrder(order.id);
              debugPrint('✓ Order assigned successfully');

              await orderProvider.pendingOrderByDriver();
              debugPrint('✓ Pending orders fetched');

              if (context.mounted) {
                debugPrint('🔄 Navigating to app screen');
                Navigator.pushReplacementNamed(context, '/appScreen');
              }
            } catch (e) {
              debugPrint('❌ Error during order acceptance: $e');
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

  /// Play the alert sound in a loop
  void _playAlertSound() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.play(AssetSource('assets/sound/alarm2.mp3'));
        _audioPlayer!.setReleaseMode(ReleaseMode.loop);

        _backgroundAudioTimer?.cancel();
        _backgroundAudioTimer =
            Timer.periodic(const Duration(seconds: 3), (timer) {
          _audioPlayer!.play(AssetSource('assets/sound/alarm2.mp3'));
        });
      }
    } catch (e) {
      debugPrint('Error playing alert sound: $e');
    }
  }

  /// Stop the alert sound
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

  /// Check for notifications when app starts
  Future<void> checkForNotifications() async {
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
