import 'package:delivery/app.dart';
import 'package:delivery/providers/auth_provider.dart';
import 'package:delivery/providers/driver_provider.dart';
import 'package:delivery/providers/notification_provider.dart';
import 'package:delivery/providers/order_provider.dart';
import 'package:delivery/screens/available_deliveries_screen.dart';
import 'package:delivery/screens/login_screen.dart';
import 'package:delivery/screens/otp_screen.dart';
import 'package:delivery/screens/pending_deliveries_screen.dart';
import 'package:delivery/screens/profile_screen.dart';
import 'package:delivery/services/notification_services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final navigatorKey = GlobalKey<NavigatorState>();
  NotificationService.navigatorKey = navigatorKey;
  // await NotificationService.instance.initialize();
  runApp(
    MyApp(navigatorKey: navigatorKey),
  );
}

class MyApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({super.key, required this.navigatorKey});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize notification service
    await NotificationService.instance.initialize();
    // Check for notifications that might have launched the app
    await NotificationService.instance.checkForNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        navigatorKey: widget.navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Driver-DayKart',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        // Handle navigation based on login state
        routes: {
          '/login': (context) => const LoginScreen(),
          '/OTP': (context) => const OTPScreen(),
          '/appScreen': (context) => const AppScreen(),
          '/pendingDelivery': (context) => const PendingDeliveries(),
          '/availableDelivery': (context) => const AvailableDeliveries(),
          '/profile': (context) => const ProfilePage(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChecking = true;
  late AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    await _authProvider.checkIfSignedIn();
    if (mounted) {
      _authProvider.initializeAuthState();
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _authProvider.isSignedIn ? const AppScreen() : const LoginScreen();
  }
}
