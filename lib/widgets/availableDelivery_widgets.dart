import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/order_model.dart';

/// --------------------------------------------------------------
/// Section: Loading, Error & Empty Widgets
/// --------------------------------------------------------------
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

/// --------------------------------------------------------------
/// Section: Order Countdown Timer
/// --------------------------------------------------------------
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
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Icon(Icons.timer, color: timeColor, size: 24),
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
    );
  }
}

/// --------------------------------------------------------------
/// Section: Order Items List
/// --------------------------------------------------------------
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
                Text('${item.quantity}',
                    style: TextStyle(color: Colors.grey[700])),
                const SizedBox(width: 8),
                Text('₹ ${item.price}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// --------------------------------------------------------------
/// Section: Order Card Widget
/// --------------------------------------------------------------
class OrderCard extends StatefulWidget {
  final Order order;
  final Color acceptColor;
  final Color pendingColor;
  final Future<void> Function() onAccept;

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
  bool _isButtonClicked = false;

  // Formats the date string for display.
  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime.toLocal());
    } catch (_) {
      return dateTimeString;
    }
  }

  // Handles the order acceptance action and prevents multiple clicks.
  Future<void> _handleAccept() async {
    if (_isButtonClicked) return;
    setState(() {
      _isButtonClicked = true;
    });
    await widget.onAccept();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Order ID and Delivery Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Order #${widget.order.orderPK}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Chip(
                  label: Text(
                    widget.order.deliveryStatus,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: widget.pendingColor,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Countdown Timer Section
            OrderCountdownTimer(
                createdAt: DateTime.parse(widget.order.createdAt)),
            const Divider(height: 24),
            // Order Details: Creation time and Shipping Address
            IntrinsicHeight(
              child: Row(
                children: [
                  // Created On Information
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12)),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 20,
                                  color: Theme.of(context).primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Created On:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).primaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDateTime(widget.order.createdAt),
                            style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: double.infinity,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  // Shipping Address Information
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12)),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(Icons.location_on,
                                  size: 20,
                                  color: Theme.of(context).primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Shipping Address:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).primaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${widget.order.shippingName}\n${widget.order.shippingAddress1}\n${widget.order.shippingPhone}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Total Amount Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.payments_rounded,
                          color: Theme.of(context).primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Total Amount:',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Text(
                    '₹${widget.order.totalAmount}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Items List Section
            Row(
              children: [
                Icon(Icons.shopping_bag_outlined,
                    color: Theme.of(context).primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Items:',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor),
                ),
                const Spacer(),
                Text(
                  '${widget.order.items.length} items',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OrderItemList(items: widget.order.items),
            const SizedBox(height: 20),
            // Accept Order Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isButtonClicked ? null : _handleAccept,
                icon: const Icon(Icons.delivery_dining, color: Colors.white),
                label:
                    Text(_isButtonClicked ? 'Processing...' : 'Accept Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.acceptColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  disabledBackgroundColor: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
