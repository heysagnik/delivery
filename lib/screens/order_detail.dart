import 'package:delivery/providers/order_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/order_model.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  Future<Order>? _orderDetails;
  bool _isRefreshing = false;
  late int orderPK = 0;

  static const _dateFormat = 'MMM dd, yyyy • hh:mm a';

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    try {
      final order = await orderProvider.fetchOrderDetails(widget.orderId);
      setState(() {
        orderPK = order.orderPK;
        _orderDetails = Future.value(order);
      });
    } catch (e) {
      setState(() {
        _orderDetails = Future.error(e);
      });
    }
  }

  Future<void> _refreshOrderDetails() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await _loadOrderDetails();
    if (mounted) setState(() => _isRefreshing = false);
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return "N/A";
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat(_dateFormat).format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Order #$orderPK',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrderDetails,
        child: FutureBuilder<Order>(
          future: _orderDetails,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || _isRefreshing) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('No order details available'));
            }

            final Order order = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order ID: ${order.id}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('Delivery Status: ${order.deliveryStatus}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Total Amount: ₹${order.totalAmount}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Payment Mode: ${order.paymentMode}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),
                  Text('Delivery Partner: ${order.deliveryBoy.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('Shipping Address: ${order.shippingAddress1}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Accepted At: ${_formatDateTime(order.timeline.acceptedAt)}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),
                  const Text('Order Items:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ...order.items.map((item) => ListTile(
                    title: Text(item.name),
                    subtitle: Text('Qty: ${item.quantity} - Price: ₹${item.price}'),
                  )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
