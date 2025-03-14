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
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = FlutterSecureStorage();
  await storage.deleteAll();
  await Firebase.initializeApp();
  await NotificationService.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
    bool isLoggedIn = await _authProvider.checkIfSignedIn();
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
