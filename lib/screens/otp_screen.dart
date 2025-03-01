import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:async';

import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  bool _isLoading = false;
  int resendSeconds = 30;
  final TextEditingController otpController = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    resendSeconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSeconds > 0) {
        setState(() {
          resendSeconds--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    otpController.dispose();
    _timer?.cancel();
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
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App logo
                  Icon(
                    PhosphorIconsFill.password,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 24),

                  // Title text
                  const Text(
                    'OTP Verification',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description text
                  Text(
                    'We have sent a verification code to given number',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // OTP input fields
                  Pinput(
                    length: 4,
                    controller: otpController,
                    showCursor: true,
                    defaultPinTheme: PinTheme(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Theme.of(context).primaryColor),
                      ),
                      textStyle: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Verify button
                  Center(
                    child: _isLoading
                        ? CircularProgressIndicator(
                            color: Theme.of(context).primaryColor)
                        : ElevatedButton(
                            onPressed: () async {
                              if (otpController.text.isEmpty) {
                                showSnackBar(context,
                                    'Please enter OTP sent to your number');
                              } else if (otpController.text.length != 4) {
                                showSnackBar(context,
                                    'Please enter a valid 4-digit OTP');
                              } else {
                                setState(() {
                                  _isLoading = true;
                                });
                                try {
                                  await Provider.of<AuthProvider>(context,
                                          listen: false)
                                      .verifyOTP(otpController.text);
                                  Navigator.pushReplacementNamed(
                                      context, '/appScreen');
                                  showSnackBar(
                                      context, 'OTP verified successfully');
                                } catch (e) {
                                  showSnackBar(context, e.toString());
                                } finally {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Send OTP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Resend OTP option
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Didn't receive the code? ",
                        style: TextStyle(color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: () async {
                          String phoneNumber =
                              Provider.of<AuthProvider>(context, listen: false)
                                      .mobile ??
                                  "";
                          try {
                            await Provider.of<AuthProvider>(context,
                                    listen: false)
                                .login(phoneNumber);
                            showSnackBar(context, 'OTP resent successfully');
                            _startResendTimer();
                          } catch (e) {
                            showSnackBar(context, e.toString());
                          }
                        },
                        child: Text(
                          resendSeconds > 0
                              ? "Resend in $resendSeconds s"
                              : "Resend",
                          style: TextStyle(
                            color: resendSeconds > 0
                                ? Colors.grey
                                : Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
