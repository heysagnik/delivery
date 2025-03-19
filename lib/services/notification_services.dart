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
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.instance.initialize();
  if (message.data['type'] == 'new_order') {
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

  AudioPlayer? _audioPlayer;

  /// Initializes the notification service
  Future<void> initialize({BuildContext? context}) async {
    try {
      debugPrint("Initializing NotificationService...");
      await Firebase.initializeApp();
      await _fetchAndSaveFCMToken();
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
      await requestPermission();
      await _initLocalNotifications();
      await setupMessageHandlers();
      await _checkNotificationLaunch();
      _audioPlayer = AudioPlayer();
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

  /// Requests notification permissions
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

  /// Initializes local notifications with extracted configuration
  Future<void> _initLocalNotifications() async {
    if (_isInitialized) return;

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
      onDidReceiveNotificationResponse: handleNotificationAction,
    );

    _isInitialized = true;
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

  /// Displays a local notification with structured configuration
  Future<void> showNotification(RemoteMessage message) async {
    final notification = message.notification;
    final isNewOrder = message.data['type'] == 'new_order';

    final title = notification?.title ??
        (isNewOrder ? 'New Order Available!' : 'New Notification');
    final body =
        notification?.body ?? (isNewOrder ? 'Tap to view order details' : '');

    // Use a dedicated variable for the notification ID
    final notificationId = isNewOrder
        ? 0
        : (notification?.hashCode ??
            DateTime.now().millisecondsSinceEpoch.hashCode);

    try {
      await _localNotifications.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            isNewOrder
                ? NotificationConstants.newOrderChannelId
                : NotificationConstants.highImportanceChannelId,
            isNewOrder
                ? NotificationConstants.newOrderChannelName
                : NotificationConstants.highImportanceChannelName,
            channelDescription: isNewOrder
                ? NotificationConstants.newOrderChannelDescription
                : NotificationConstants.highImportanceChannelDescription,
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            visibility: NotificationVisibility.public,
            autoCancel: false,
            ongoing: isNewOrder,
            sound: RawResourceAndroidNotificationSound(
                NotificationConstants.orderAlertSound), // Use custom sound
            vibrationPattern: NotificationConstants.newOrderVibrationPattern,
            category:
                AndroidNotificationCategory.alarm, // Set category to alarm
            fullScreenIntent: true, // Enable fullScreenIntent
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.critical,
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

  /// Sets up Firebase message handlers for foreground and opened notifications
  Future<void> setupMessageHandlers() async {
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint("Foreground notification: ${message.notification?.title}");
      if (message.data['type'] == 'new_order') {
        _handleNewOrderNotification(message);
      } else {
        showNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint("Notification clicked, app opened.");
      if (message.data['type'] == 'new_order') {
        _handleNewOrderNotification(message);
      } else {
        handleNotificationAction(NotificationResponse(
          payload: message.data['driverId']?.toString() ?? '',
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
        ));
      }
    });
  }

  /// Handles new order notifications
  void _handleNewOrderNotification(RemoteMessage message) async {
    try {
      if (message.data.containsKey('order_data')) {
        final orderData = json.decode(message.data['order_data']);
        final Order newOrder = Order.fromJson(orderData);
        if (navigatorKey?.currentContext != null) {
          _showOrderAlert(navigatorKey!.currentContext!, newOrder);
        } else {
          showNotification(message);
        }
      } else {
        showNotification(message);
      }
    } catch (e) {
      debugPrint('Error handling new order notification: $e');
      showNotification(message);
    }
  }

  /// Displays the fullscreen order alert dialog
  void _showOrderAlert(BuildContext context, Order order) {
    _playAlertSound();
    HapticFeedback.heavyImpact();

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => OrderAlertScreen(
          order: order,
          onAccept: () async {
            _stopAlertSound();
            _localNotifications.cancel(0); // Cancel notification
            final orderProvider =
                Provider.of<OrderProvider>(context, listen: false);
            await orderProvider.assignOrder(order.id);
            await orderProvider.pendingOrderByDriver();
            Navigator.of(context).pop();
            Navigator.pushReplacementNamed(context, '/availableDelivery');
          },
          onDecline: () {
            _stopAlertSound();
            _localNotifications.cancel(0); // Cancel notification
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

  /// Checks for notification launch details when the app starts
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
          final orderData = json.decode(payload);
          if (orderData != null && navigatorKey?.currentContext != null) {
            await Future.delayed(const Duration(milliseconds: 500));
            final Order newOrder = Order.fromJson(orderData);
            _showOrderAlert(navigatorKey!.currentContext!, newOrder);
          }
        } catch (e) {
          debugPrint('Error processing launch payload: $e');
        }
      }
    }
  }

  /// Handles user notification actions
  void handleNotificationAction(NotificationResponse response) {
    debugPrint("Notification action payload: ${response.payload}");
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final orderData = json.decode(response.payload!);
        if (orderData != null && navigatorKey?.currentContext != null) {
          final Order newOrder = Order.fromJson(orderData);
          _showOrderAlert(navigatorKey!.currentContext!, newOrder);
        }
      } catch (e) {
        debugPrint('Error in notification action: $e');
      }
    }
  }
}
