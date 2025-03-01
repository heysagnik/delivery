import 'package:delivery/app.dart';
import 'package:delivery/providers/auth_provider.dart';
import 'package:delivery/screens/login_screen.dart';
import 'package:delivery/screens/otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
      setState(() => _isChecking = false);
      _authProvider.initializeAuthState();
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
