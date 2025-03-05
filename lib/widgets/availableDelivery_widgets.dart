import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/order_model.dart';

/// A loading indicator widget.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Theme.of(context).primaryColor),
          const SizedBox(height: 16),
          Text(
            'Loading orders...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget for showing an error message.
class ErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Color pendingColor;
  const ErrorMessage({
    super.key,
    required this.message,
    required this.onRetry,
    required this.pendingColor,
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: pendingColor, size: 48),
          const SizedBox(height: 16),
          Text(
            'Error: $message',
            style: TextStyle(color: pendingColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget for showing empty data.
class EmptyDataWidget extends StatelessWidget {
  const EmptyDataWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
          const SizedBox(height: 16),
          Text(
            'No pending deliveries found.',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// A separate widget to display the countdown timer.
/// It calculates the remaining time based on the order's createdAt time plus 2 minutes.
/// Once the countdown finishes, the widget hides itself.
class OrderCountdownTimer extends StatefulWidget {
  final DateTime createdAt;
  const OrderCountdownTimer({super.key, required this.createdAt});
  @override
  State<OrderCountdownTimer> createState() => _OrderCountdownTimerState();
}

class _OrderCountdownTimerState extends State<OrderCountdownTimer>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late int _remainingSeconds;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isTimerActive = true;

  @override
  void initState() {
    super.initState();
    final expiryTime = widget.createdAt.add(const Duration(minutes: 2));
    final now = DateTime.now();
    if (now.isAfter(expiryTime)) {
      _remainingSeconds = 0;
      _isTimerActive = false;
    } else {
      _remainingSeconds = expiryTime.difference(now).inSeconds;
      if (_remainingSeconds > 120) _remainingSeconds = 120;
    }

    _animationController = AnimationController(
      vsync: this,
      duration:
          Duration(seconds: _remainingSeconds > 0 ? _remainingSeconds : 1),
    );
    _animation = Tween<double>(
      begin: _remainingSeconds > 0 ? _remainingSeconds / 120 : 0,
      end: 0.0,
    ).animate(_animationController);

    if (_remainingSeconds > 0) {
      _animationController.forward();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _timer.cancel();
            _isTimerActive = false;
          }
        });
      });
    }
  }

  @override
  void dispose() {
    if (_remainingSeconds > 0) _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  String get timeDisplay {
    final minutes = (_remainingSeconds / 60).floor();
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color get timeColor {
    if (_remainingSeconds > 60) return Colors.green;
    if (_remainingSeconds > 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isTimerActive) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: timeColor.withOpacity(0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              Icons.timer,
              color: timeColor,
              size: 24,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Time Remaining:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeDisplay,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: timeColor,
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: 40,
              height: 40,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: _animation.value,
                        strokeWidth: 4,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(timeColor),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A widget to display a list of order items.
class OrderItemList extends StatelessWidget {
  final List<Item> items;
  const OrderItemList({super.key, required this.items});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  '${item.quantity}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹ ${item.price}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// The OrderCard widget now uses the separated [OrderCountdownTimer] and [OrderItemList]
/// for better scalability.
class OrderCard extends StatefulWidget {
  final Order order;
  final Color acceptColor;
  final Color pendingColor;
  final VoidCallback onAccept;
  const OrderCard({
    super.key,
    required this.order,
    required this.acceptColor,
    required this.pendingColor,
    required this.onAccept,
  });
  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  // Helper method to format date.
  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime.toLocal());
    } catch (e) {
      return dateTimeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row (Order ID and Delivery Status)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    'Order #${widget.order.orderPK}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                Chip(
                  label: Text(
                    widget.order.deliveryStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: widget.pendingColor,
                ),
              ],
            ),

            // Countdown Timer Section (modularized)
            OrderCountdownTimer(
              createdAt: DateTime.parse(widget.order.createdAt),
            ),

            const Divider(height: 24),

            // Created On Timeline
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Created On:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatDateTime(widget.order.createdAt),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Total Amount Row
            Row(
              children: [
                const Icon(Icons.payments, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Total Amount:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹${widget.order.totalAmount}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Items List (modularized)
            Text(
              'Items:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            OrderItemList(items: widget.order.items),
            const SizedBox(height: 16),

            // Accept Button (always enabled)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: widget.onAccept,
                  icon: const Icon(Icons.delivery_dining, color: Colors.white),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.acceptColor,
                    foregroundColor: Colors.white,
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
