import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/order_model.dart';

class OrderAlertScreen extends StatefulWidget {
  final Order order;
  final Function onAccept;
  final Function onDecline;
  final int timeoutSeconds;

  const OrderAlertScreen({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onDecline,
    this.timeoutSeconds = 30,
  });

  @override
  _OrderAlertScreenState createState() => _OrderAlertScreenState();
}

class _OrderAlertScreenState extends State<OrderAlertScreen> {
  late Timer _timer;
  int _remainingSeconds = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    // Set screen to stay on and immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Vibrate phone
    HapticFeedback.heavyImpact();

    // Play alert sound
    _playAlertSound();

    // Initialize countdown timer
    _remainingSeconds = widget.timeoutSeconds;
    _startTimer();
  }

  void _playAlertSound() async {
    await _audioPlayer.play(AssetSource('sounds/new_order_alert.mp3'));
    _audioPlayer.setReleaseMode(ReleaseMode.loop); // Loop the sound
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _handleTimeout();
        }
      });
    });
  }

  void _handleTimeout() {
    _timer.cancel();
    widget.onDecline();
  }

  @override
  void dispose() {
    _timer.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final Color acceptColor = const Color(0xFF25B462);
    final Color pendingColor = const Color(0xFFE74C3C);

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.9),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header with timer
              Container(
                padding: const EdgeInsets.all(16),
                color: pendingColor,
                width: double.infinity,
                child: Column(
                  children: [
                    const Text(
                      'NEW ORDER!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Expires in $_remainingSeconds seconds',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

              // Order details
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order ID
                        Text(
                          'Order #${order.id}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),

                        // Drop Location
                        const Text(
                          'DROP',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          order.shippingAddress1,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 12),

                        // Payment
                        const Text(
                          'PAYMENT',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${order.totalAmount.toString()}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Decline button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _timer.cancel();
                          _audioPlayer.stop();
                          widget.onDecline();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: pendingColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: pendingColor),
                          ),
                        ),
                        child: const Text(
                          'DECLINE',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Accept button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _timer.cancel();
                          _audioPlayer.stop();
                          widget.onAccept();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: acceptColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'ACCEPT',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
