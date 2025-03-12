import 'package:flutter/material.dart';
import 'dart:async';
import '../models/order_model2.dart';

class OrderCard extends StatelessWidget {
  final Order2 order;
  final Color acceptColor;
  final Color pendingColor;
  final VoidCallback onViewDetails;

  const OrderCard({
    super.key,
    required this.order,
    required this.acceptColor,
    required this.pendingColor,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      // Reduced external margins for a more compact layout
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      elevation: 6,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Padding(
          // Reduced internal padding remains here for content spacing
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OrderHeader(order: order, acceptColor: acceptColor),
              const SizedBox(height: 14),
              OrderAmount(totalAmount: order.totalAmount),
              const SizedBox(height: 14),
              OrderItemsSection(order: order),
              const SizedBox(height: 14),
              ShippingAddressSection(order: order),
              const SizedBox(height: 14),
              OrderElapsedTimer(acceptedAt: order.timeline.acceptedAt),
              const SizedBox(height: 14),
              ActionButton(onViewDetails: onViewDetails),
            ],
          ),
        ),
      ),
    );
  }
}

// Header widget displays the order number, status, and elapsed-time badge.
class OrderHeader extends StatelessWidget {
  final Order2 order;
  final Color acceptColor;
  const OrderHeader({
    super.key,
    required this.order,
    required this.acceptColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
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
                Icons.delivery_dining,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.orderPK}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: acceptColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.deliveryStatus,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        Positioned(
          right: 0,
          top: 0,
          child: ElapsedTimeBadge(acceptedAt: order.timeline.acceptedAt),
        ),
      ],
    );
  }
}

// OrderAmount widget displays the total amount in a highlighted container.
class OrderAmount extends StatelessWidget {
  final num totalAmount;
  const OrderAmount({super.key, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              const SizedBox(width: 6),
              Text(
                'Total Amount:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            '₹$totalAmount',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// OrderItemsSection groups the header row for items and the list of items.
class OrderItemsSection extends StatelessWidget {
  final Order2 order;
  const OrderItemsSection({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.shopping_bag_outlined,
                color: Theme.of(context).primaryColor, size: 18),
            const SizedBox(width: 6),
            Text(
              'Items:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const Spacer(),
            Text(
              '${order.items.length} items',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ItemsList(items: order.items),
      ],
    );
  }
}

class ShippingAddressSection extends StatelessWidget {
  final Order2 order;
  const ShippingAddressSection({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with shipping icon and title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      color: Theme.of(context).primaryColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Shipping Address:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              // "Created On" section with date
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      color: Theme.of(context).primaryColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Created: ${_formatDate(order.timeline.acceptedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Address text
          Text(
            order.shippingAddress1,
            style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Helper method to format the date
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }
}

// ActionButton widget displays the full-width button.
class ActionButton extends StatelessWidget {
  final VoidCallback onViewDetails;
  const ActionButton({super.key, required this.onViewDetails});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onViewDetails,
        icon: const Icon(Icons.visibility_outlined,
            color: Colors.white, size: 18),
        label: const Text('View Order Details'),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

// ItemsList widget remains unchanged.
class ItemsList extends StatelessWidget {
  final List<Item2> items;
  const ItemsList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: items.length > 3 ? 3 : items.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    '${item.quantity}x',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹ ${item.price}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------- Timer Widgets ---------------- //

class ElapsedTimeBadge extends StatefulWidget {
  final String acceptedAt;
  const ElapsedTimeBadge({super.key, required this.acceptedAt});

  @override
  State<ElapsedTimeBadge> createState() => _ElapsedTimeBadgeState();
}

class _ElapsedTimeBadgeState extends State<ElapsedTimeBadge> {
  late Timer _timer;
  late Duration _elapsed;
  late DateTime _acceptedTime;

  @override
  void initState() {
    super.initState();
    _acceptedTime = DateTime.tryParse(widget.acceptedAt) ?? DateTime.now();
    _elapsed = DateTime.now().difference(_acceptedTime);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(_acceptedTime);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String getCompactTime() {
    if (_elapsed.inHours > 0) {
      return "${_elapsed.inHours}h ${_elapsed.inMinutes.remainder(60)}m";
    } else {
      return "${_elapsed.inMinutes}m ${_elapsed.inSeconds.remainder(60)}s";
    }
  }

  Color getTimeColor() {
    if (_elapsed.inMinutes < 15) return Colors.green;
    if (_elapsed.inMinutes < 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: getTimeColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: getTimeColor().withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded, size: 16, color: getTimeColor()),
          const SizedBox(width: 4),
          Text(
            getCompactTime(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: getTimeColor(),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderElapsedTimer extends StatefulWidget {
  final String acceptedAt;
  const OrderElapsedTimer({super.key, required this.acceptedAt});

  @override
  State<OrderElapsedTimer> createState() => _OrderElapsedTimerState();
}

class _OrderElapsedTimerState extends State<OrderElapsedTimer> {
  late Timer _timer;
  late Duration _elapsed;
  late DateTime _acceptedTime;
  final Duration _expectedDeliveryTime = const Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    _acceptedTime = DateTime.tryParse(widget.acceptedAt) ?? DateTime.now();
    _elapsed = DateTime.now().difference(_acceptedTime);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(_acceptedTime);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  double getProgressValue() {
    return (_elapsed.inSeconds / _expectedDeliveryTime.inSeconds)
        .clamp(0.0, 1.0);
  }

  Color getProgressColor() {
    double progress = getProgressValue();
    if (progress < 0.6) return Colors.green;
    if (progress < 0.9) return Colors.orange;
    return Colors.red;
  }

  String getDeliveryStatusText() {
    double progress = getProgressValue();
    if (progress >= 1.0) {
      return "Delivery running late!";
    } else if (progress > 0.8) {
      return "Approaching delivery time";
    } else {
      return "Delivery in progress";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.timer, color: getProgressColor(), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Time Elapsed:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              Text(
                formatDuration(_elapsed),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: getProgressColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: getProgressValue(),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(getProgressColor()),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getDeliveryStatusText(),
                style: TextStyle(
                  fontSize: 12,
                  color: getProgressColor(),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Est. ${formatDuration(_expectedDeliveryTime)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
