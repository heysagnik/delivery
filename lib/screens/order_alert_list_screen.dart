import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/order_model.dart';

class OrderAlertListScreen extends StatefulWidget {
  final List<Order> orders;
  final Function(Order) onAccept;
  final Function(Order) onDecline;
  final int timeoutSeconds;

  const OrderAlertListScreen({
    super.key,
    required this.orders,
    required this.onAccept,
    required this.onDecline,
    this.timeoutSeconds = 30,
  });

  @override
  State<OrderAlertListScreen> createState() => _OrderAlertListScreenState();
}

class _OrderAlertListScreenState extends State<OrderAlertListScreen>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  int _remainingSeconds = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  AnimationController? _animationController;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.timeoutSeconds;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)
        .then((_) => _setupScreen());
  }

  void _setupScreen() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
    _animationController!.repeat(reverse: true);
    HapticFeedback.heavyImpact();
    _playAlertSound();
    _startTimer();
  }

  void _playAlertSound() async {
    try {
      await _audioPlayer.play(AssetSource('sound/alarm2.mp3'));
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
            // If time runs out, decline all orders.
            for (var order in widget.orders) {
              widget.onDecline(order);
            }
            _stopAudioAndAnimation();
            _restoreSystemUi();
            Navigator.of(context).pop();
          }
        });
      }
    });
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
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (e) {
      debugPrint('Error restoring system UI: $e');
    }
  }

  @override
  void dispose() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    _audioPlayer.dispose();
    _animationController?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color pendingColor = const Color(0xFFE74C3C);
    final Color acceptColor = const Color(0xFF25B462);

    return Scaffold(
      backgroundColor: pendingColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with timer
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              color: pendingColor,
              width: double.infinity,
              child: Column(
                children: [
                  const Text(
                    'NEW ORDERS!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: Stack(
                          children: [
                            CircularProgressIndicator(
                              value: _remainingSeconds / widget.timeoutSeconds,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
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
            // List of orders
            Expanded(
              child: ListView.builder(
                itemCount: widget.orders.length,
                itemBuilder: (context, index) {
                  final order = widget.orders[index];
                  return _buildOrderCard(order, acceptColor, pendingColor);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order, Color acceptColor, Color pendingColor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              children: [
                const Icon(Icons.receipt_outlined, color: Colors.grey),
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
            const Divider(height: 20),
            // Drop Location
            const Text(
              'DROP LOCATION',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                order.shippingAddress1,
                style: const TextStyle(fontSize: 16, height: 1.3),
              ),
            ),
            const SizedBox(height: 12),
            // Payment
            const Text(
              'PAYMENT',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
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
            const SizedBox(height: 12),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onDecline(order);
                      setState(() {
                        widget.orders.remove(order);
                        if (widget.orders.isEmpty) {
                          _stopAudioAndAnimation();
                          _restoreSystemUi();
                          Navigator.of(context).pop();
                        }
                      });
                    },
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
                Expanded(
                  child: ScaleTransition(
                    scale: _animation!,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onAccept(order);
                        setState(() {
                          widget.orders.remove(order);
                          if (widget.orders.isEmpty) {
                            _stopAudioAndAnimation();
                            _restoreSystemUi();
                            Navigator.of(context).pop();
                          }
                        });
                      },
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
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
