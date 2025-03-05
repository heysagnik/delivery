import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../widgets/otp_screen_widgets.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  bool _isLoading = false;
  int resendSeconds = 30;
  final TextEditingController otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() => resendSeconds = 30);
    Future.delayed(const Duration(seconds: 1), () {
      if(!mounted) return;
      if (resendSeconds > 0) {
        setState(() => resendSeconds--);
        _startResendTimer();
      }
    });
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(PhosphorIconsFill.password,
                      size: 80, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 24),
                  const Text('OTP Verification',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('We have sent a verification code to your number',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 48),
                  OTPInputField(controller: otpController),
                  const SizedBox(height: 32),
                  VerifyButton(
                      controller: otpController,
                      isLoading: _isLoading,
                      onVerify: () => setState(() => _isLoading = !_isLoading)),
                  const SizedBox(height: 24),
                  ResendOTP(
                      resendSeconds: resendSeconds,
                      onResend: _startResendTimer),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
