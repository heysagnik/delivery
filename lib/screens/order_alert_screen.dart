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
  State<OrderAlertScreen> createState() => _OrderAlertScreenState();
}

class _OrderAlertScreenState extends State<OrderAlertScreen>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  int _remainingSeconds = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Initialize controllers without 'late'
  AnimationController? _animationController;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();

    // Initialize countdown timer
    _remainingSeconds = widget.timeoutSeconds;

    // Set immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)
        .then((_) => _setupScreen());
  }

  void _setupScreen() {
    // Initialize animation controller after the widget is mounted
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeInOut,
      ),
    );

    _animationController!.repeat(reverse: true);

    // Trigger haptic feedback
    HapticFeedback.heavyImpact();

    // Play sound
    _playAlertSound();

    // Start timer
    _startTimer();

    // Ensure the widget rebuilds with the animations
    if (mounted) {
      setState(() {});
    }
  }

  void _playAlertSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/new_order_alert.mp3'));
      _audioPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _handleTimeout();
          }
        });
      }
    });
  }

  void _handleTimeout() {
    _timer.cancel();
    _handleDecline();
  }

  void _handleAccept() async {
    // First stop any ongoing processes
    _timer.cancel();
    await _stopAudioAndAnimation();

    // Execute the callback
    widget.onAccept();

    // Restore system UI before popping
    await _restoreSystemUi();

    // Pop the screen only if context is still valid
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  void _handleDecline() async {
    // First stop any ongoing processes
    _timer.cancel();
    await _stopAudioAndAnimation();

    // Execute the callback
    widget.onDecline();

    // Restore system UI before popping
    await _restoreSystemUi();

    // Pop the screen only if context is still valid
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _stopAudioAndAnimation() async {
    try {
      await _audioPlayer.stop();
      _animationController?.stop();
    } catch (e) {
      debugPrint('Error stopping audio/animation: $e');
    }
  }

  Future<void> _restoreSystemUi() async {
    try {
      // Restore normal UI mode
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (e) {
      debugPrint('Error restoring system UI: $e');
    }
  }

  @override
  void dispose() {
    // Make sure to cancel timer
    if (_timer.isActive) {
      _timer.cancel();
    }

    // Dispose audio player
    _audioPlayer.dispose();

    // Dispose animation controller if initialized
    _animationController?.dispose();

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final Color acceptColor = const Color(0xFF25B462);
    final Color pendingColor = const Color(0xFFE74C3C);
    final double progressValue = _remainingSeconds / widget.timeoutSeconds;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: pendingColor,
        body: SafeArea(
          child: Column(
            children: [
              // Header with timer
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Circular progress bar with time remaining
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: Stack(
                            children: [
                              CircularProgressIndicator(
                                value: progressValue,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 4,
                              ),
                              Center(
                                child: Text(
                                  '$_remainingSeconds',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'seconds remaining',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Order details
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order ID with icon
                        Row(
                          children: [
                            const Icon(Icons.receipt_outlined,
                                color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Order #${order.id}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30),

                        // Drop Location
                        const Row(
                          children: [
                            Icon(Icons.pin_drop, color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'DROP LOCATION',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Text(
                            order.shippingAddress1,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Payment
                        const Row(
                          children: [
                            Icon(Icons.payments_outlined,
                                color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'PAYMENT',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Text(
                            '₹${order.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF25B462),
                            ),
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
                        onPressed: _handleDecline,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: pendingColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: pendingColor, width: 2),
                          ),
                        ),
                        child: const Text(
                          'DECLINE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Accept button with animation
                    Expanded(
                      child: _animation != null
                          ? ScaleTransition(
                              scale: _animation!,
                              child: _buildAcceptButton(acceptColor),
                            )
                          : _buildAcceptButton(acceptColor),
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

  Widget _buildAcceptButton(Color acceptColor) {
    return ElevatedButton(
      onPressed: _handleAccept,
      style: ElevatedButton.styleFrom(
        backgroundColor: acceptColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 4,
        shadowColor: acceptColor.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'ACCEPT',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
