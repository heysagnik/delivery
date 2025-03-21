import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils.dart';

class VerifyButton extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onVerify;

  const VerifyButton({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: isLoading
          ? CircularProgressIndicator(color: Theme.of(context).primaryColor)
          : ElevatedButton(
              onPressed: () async {
                if (controller.text.isEmpty) {
                  showSnackBar(context, 'Please enter OTP sent to your number');
                } else if (controller.text.length != 4) {
                  showSnackBar(context, 'Please enter a valid 4-digit OTP');
                } else {
                  onVerify();
                  try {
                    await Provider.of<AuthProvider>(context, listen: false)
                        .verifyOTP(controller.text);
                    Navigator.pushReplacementNamed(context, '/appScreen');
                    showSnackBar(context, 'OTP verified successfully');
                  } catch (e) {
                    showSnackBar(context, e.toString());
                  } finally {
                    onVerify();
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
                'Verify OTP',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
    );
  }
}

class ResendOTP extends StatefulWidget {
  final int resendSeconds;
  final VoidCallback onResend;

  const ResendOTP(
      {super.key, required this.resendSeconds, required this.onResend});

  @override
  State<ResendOTP> createState() => _ResendOTPState();
}

class _ResendOTPState extends State<ResendOTP> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Didn't receive the code? ",
            style: TextStyle(color: Colors.grey)),
        GestureDetector(
          onTap: widget.resendSeconds > 0
              ? null
              : () async {
                  try {
                    String phoneNumber =
                        Provider.of<AuthProvider>(context, listen: false)
                                .mobile ??
                            "";
                    await Provider.of<AuthProvider>(context, listen: false)
                        .login(phoneNumber);
                    showSnackBar(context, 'OTP resent successfully');
                    setState(() {
                      widget.onResend();
                    });
                  } catch (e) {
                    showSnackBar(context, e.toString());
                  }
                },
          child: Text(
            widget.resendSeconds > 0
                ? "Resend in ${widget.resendSeconds} s"
                : "Resend",
            style: TextStyle(
              color: widget.resendSeconds > 0
                  ? Colors.grey
                  : Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class OTPInputField extends StatelessWidget {
  final TextEditingController controller;

  const OTPInputField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Pinput(
      length: 4,
      controller: controller,
      showCursor: true,
      defaultPinTheme: PinTheme(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).primaryColor),
        ),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
    );
  }
}
