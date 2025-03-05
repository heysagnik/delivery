import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/login_widgets.dart';
import '../providers/auth_provider.dart';
import '../utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppLogo(),
                  const SizedBox(height: 24),
                  const WelcomeText(),
                  const SizedBox(height: 48),
                  PhoneInputField(controller: _phoneController),
                  const SizedBox(height: 24),
                  LoginButton(
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_phoneController.text.isEmpty) {
      showSnackBar(context, 'Please enter your mobile number');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .login(_phoneController.text);
      Navigator.pushReplacementNamed(context, '/OTP');
    } catch (e) {
      showSnackBar(context, 'Login failed. Try again later');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}