import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/order_model.dart';

// Color constants used throughout the widget
class _OrderAlertColors {
  static const Color alertRed = Color(0xFFE74C3C);
  static const Color successGreen = Color(0xFF25B462);
  static const Color warningYellow = Color(0xFFF39C12);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBorder = Color(0xFFEEEEEE);
}

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

  // Animation controllers
  AnimationController? _animationController;
  Animation<double>? _animation;
  Animation<double>? _pulseAnimation;

  // UI state variables
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    // Initialize countdown timer
    _remainingSeconds = widget.timeoutSeconds;

    // Set immersive mode to grab full attention
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)
        .then((_) => _setupScreen());
  }

  void _setupScreen() {
    // Initialize multiple animations
    _setupAnimations();

    // Trigger haptic feedback for immediate attention
    HapticFeedback.heavyImpact();

    // Play alert sound with error handling
    _playAlertSound();

    // Start countdown timer
    _startTimer();

    // Ensure the widget rebuilds with the animations
    if (mounted) {
      setState(() {});
    }
  }

  void _setupAnimations() {
    // Main button animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Scale animation for the accept button
    _animation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeInOut,
      ),
    );

    // Pulse animation for the timer
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeInOut,
      ),
    );

    _animationController!.repeat(reverse: true);
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

            // Add vibration for last 5 seconds to create urgency
            if (_remainingSeconds <= 5) {
              HapticFeedback.lightImpact();
            }
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

  Future<void> _handleAction(Function action) async {
    // Prevent multiple taps
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // Stop timer, audio and animations
    _timer.cancel();
    await _stopAudioAndAnimation();

    // Execute the callback
    action();

    // Restore system UI before popping
    await _restoreSystemUi();

    // Pop the screen only if context is still valid
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  void _handleAccept() async {
    await _handleAction(widget.onAccept);
  }

  void _handleDecline() async {
    await _handleAction(widget.onDecline);
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
    final order = widget.order;
    final double progressValue = _remainingSeconds / widget.timeoutSeconds;
    final Size screenSize = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _OrderAlertColors.alertRed,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(progressValue),
              Expanded(
                child: _buildOrderDetails(order, screenSize),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double progressValue) {
    // Determine timer color based on remaining time
    Color timerColor = Colors.white;
    double fontSize = 18;

    if (_remainingSeconds <= 10) {
      timerColor = _remainingSeconds <= 5
          ? Colors.white
          : _OrderAlertColors.warningYellow;
      fontSize = _remainingSeconds <= 5 ? 22 : 20;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
      color: _OrderAlertColors.alertRed,
      width: double.infinity,
      child: Column(
        children: [
          // Gradient title for visual appeal
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, Colors.amber],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const Text(
              'NEW ORDER!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Enhanced countdown timer with animation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pulseAnimation != null && _remainingSeconds <= 5
                  ? ScaleTransition(
                      scale: _pulseAnimation!,
                      child: _buildTimerCircle(
                          progressValue, timerColor, fontSize),
                    )
                  : _buildTimerCircle(progressValue, timerColor, fontSize),
              const SizedBox(width: 12),
              const Text(
                'seconds remaining',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCircle(double progressValue, Color color, double fontSize) {
    final isUrgent = _remainingSeconds <= 5;

    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress indicator
          CircularProgressIndicator(
            value: progressValue,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              isUrgent ? Colors.white : color,
            ),
            strokeWidth: 4,
          ),

          // Timer text
          Text(
            '$_remainingSeconds',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isUrgent ? 22 : fontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(Order order, Size screenSize) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.04,
        vertical: screenSize.height * 0.02,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderHeader(order),
            const Divider(height: 30),
            _buildLocationSection(order),
            const SizedBox(height: 24),
            _buildPaymentSection(order),
            const SizedBox(height: 24),
            // _buildAdditionalDetails(order),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader(Order order) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _OrderAlertColors.successGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.receipt_outlined,
            color: _OrderAlertColors.successGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${order.orderPK}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _OrderAlertColors.textPrimary,
                ),
              ),
              Text(
                'Items: ${order.items.length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: _OrderAlertColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.pin_drop,
                color: _OrderAlertColors.textSecondary, size: 20),
            SizedBox(width: 8),
            Text(
              'DROP LOCATION',
              style: TextStyle(
                color: _OrderAlertColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _OrderAlertColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.shippingAddress1,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.3,
                  color: _OrderAlertColors.textPrimary,
                ),
              ),
              if (order.shippingName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    order.shippingName,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.3,
                      color: _OrderAlertColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.payments_outlined,
                color: _OrderAlertColors.textSecondary, size: 20),
            SizedBox(width: 8),
            Text(
              'PAYMENT',
              style: TextStyle(
                color: _OrderAlertColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '₹${order.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _OrderAlertColors.successGreen,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _OrderAlertColors.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                order.paymentMode,
                style: const TextStyle(
                  color: _OrderAlertColors.successGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Widget _buildAdditionalDetails(Order order) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Row(
  //         children: [
  //           Icon(Icons.info_outline,
  //               color: _OrderAlertColors.textSecondary, size: 20),
  //           SizedBox(width: 8),
  //           Text(
  //             'DELIVERY DETAILS',
  //             style: TextStyle(
  //               color: _OrderAlertColors.textSecondary,
  //               fontWeight: FontWeight.bold,
  //               fontSize: 14,
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 12),
  //     ],
  //   );
  // }

  // Widget _buildDetailRow(String label, String value) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       Text(
  //         label,
  //         style: const TextStyle(
  //           color: _OrderAlertColors.textSecondary,
  //           fontSize: 14,
  //         ),
  //       ),
  //       Text(
  //         value,
  //         style: const TextStyle(
  //           fontWeight: FontWeight.w600,
  //           fontSize: 14,
  //           color: _OrderAlertColors.textPrimary,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Row(
        children: [
          Expanded(
            child: _buildDeclineButton(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _animation != null
                ? ScaleTransition(
                    scale: _animation!,
                    child: _buildAcceptButton(),
                  )
                : _buildAcceptButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeclineButton() {
    return ElevatedButton(
      onPressed: _isProcessing ? null : _handleDecline,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _OrderAlertColors.alertRed,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade600,
        padding: const EdgeInsets.symmetric(vertical: 18),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
              color: _isProcessing
                  ? Colors.grey.shade400
                  : _OrderAlertColors.alertRed,
              width: 2),
        ),
      ),
      child: _isProcessing
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _OrderAlertColors.textSecondary,
                ),
              ),
            )
          : const Text(
              'DECLINE',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
    );
  }

  Widget _buildAcceptButton() {
    return ElevatedButton(
      onPressed: _isProcessing ? null : _handleAccept,
      style: ElevatedButton.styleFrom(
        backgroundColor: _OrderAlertColors.successGreen,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        elevation: 4,
        shadowColor: _OrderAlertColors.successGreen.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: _isProcessing
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
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
