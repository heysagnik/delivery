import 'package:delivery/providers/order_provider.dart';
import 'package:delivery/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  Future<Map<String, dynamic>>? _orderDetails;
  final Map<String, String> _driverNames = {};
  bool _isRefreshing = false;
  late int orderPK = 0;

  // Order status constants
  static const STATUS_PICKED = "picked";
  static const STATUS_REACHED = "reached";
  static const STATUS_DELIVERED = "delivered";

  // Date format constant
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
      });
      _orderDetails = Future.value(order.toJson());
    } catch (e) {
      _orderDetails = Future.error(e);
    }
  }

  Future<void> _refreshOrderDetails() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await _loadOrderDetails();
    if (mounted) setState(() => _isRefreshing = false);
  }

  Future<void> _updateOrderStatus(String status) async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.changeOrderStatus(orderPK, status);

      // Refresh order details to get the updated status
      await _loadOrderDetails();

      if (status == STATUS_DELIVERED) {
        // If order is delivered, navigate back
        if (mounted) {
          showSnackBar(context, 'Order delivered successfully');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error updating order status: $e');
        setState(() => _isRefreshing = false);
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
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

  static const Map<String, Color> statusColors = {
    'pending': Colors.amber,
    'accepted': Colors.green,
    'picked': Colors.orange,
    'reached': Colors.deepPurple,
    'delivered': Colors.greenAccent,
    'completed': Colors.blue,
    'cancelled': Colors.red,
  };

  Color _getStatusColor(String status) {
    return statusColors[status.toLowerCase()] ?? Colors.amber;
  }

  Widget _getActionButton(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return _buildActionButton(
            'Pickup Order',
            Icons.directions_bike,
            Colors.orange,
                () => _updateOrderStatus(STATUS_PICKED)
        );
      case 'picked':
        return _buildActionButton(
            'Reached Customer',
            Icons.location_on,
            Colors.deepPurple,
                () => _updateOrderStatus(STATUS_REACHED)
        );
      case 'reached':
        return _buildActionButton(
            'Delivered Order',
            Icons.check_circle,
            Colors.green,
                () => _updateOrderStatus(STATUS_DELIVERED)
        );
      default:
        return const SizedBox.shrink(); // No button for other statuses
    }
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ElevatedButton.icon(
          onPressed: _isRefreshing ? null : onPressed,
          icon: Icon(icon, size: 20, color: Colors.white),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color accentColor = const Color(0xFF3498DB);

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
        child: FutureBuilder<Map<String, dynamic>>(
          future: _orderDetails,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                _isRefreshing) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _buildErrorView(primaryColor, snapshot.error.toString());
            }

            if (!snapshot.hasData) {
              return _buildNoDataView();
            }

            final String statusText = snapshot.data!["deliveryStatus"] ?? "pending";

            return Column(
              children: [
                Expanded(
                  child: _buildOrderDetails(
                      snapshot.data!,
                      primaryColor,
                      accentColor
                  ),
                ),
                _getActionButton(statusText),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorView(Color primaryColor, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error: $error',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshOrderDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No order details available',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(
      Map<String, dynamic> data, Color primaryColor, Color accentColor) {
    final String statusText = data["deliveryStatus"] ?? "pending";
    final bool isAccepted = statusText == "accepted" ||
        statusText == "picked" ||
        statusText == "reached";

    final Map<String, dynamic> statusTimestamps =
        data["statusTimestamps"] ?? {};

    final String deliveryBoyId = data["deliveryBoy"] ?? "";
    final String deliveryBoyName = deliveryBoyId.isNotEmpty
        ? (_driverNames[deliveryBoyId] ?? "Fetching...")
        : "Not Assigned";

    // Calculate total items and quantity
    final List<dynamic> items = data["items"] ?? [];
    final int totalItems = items.length;
    final int totalQuantity =
    items.fold(0, (sum, item) => sum + (item["quantity"] as num).toInt());

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderSection(
              data, statusText, totalItems, totalQuantity, primaryColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isAccepted)
                  _buildDeliverySection(
                      data, deliveryBoyName, accentColor, primaryColor, statusText),
                _buildSectionHeader('Order Items'),
                _buildOrderItemsCard(data, accentColor),
                if (data["deliveryAddress"] != null)
                  _buildAddressSection(data["deliveryAddress"], accentColor),
                const SizedBox(height: 30),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(Map<String, dynamic> data, String statusText,
      int totalItems, int totalQuantity, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(statusText).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getStatusColor(statusText),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  statusText.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(statusText),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Order summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${data["totalAmount"] ?? "0"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalItems items • $totalQuantity quantity',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data["paymentMode"] ?? "Cash",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Payment Mode',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySection(Map<String, dynamic> data,
      String deliveryBoyName, Color accentColor, Color primaryColor, String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Delivery Information'),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.delivery_dining,
                        color: accentColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deliveryBoyName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Delivery Partner',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.phone),
                        color: primaryColor,
                        onPressed: () {
                          // Call driver functionality
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  'Accepted At',
                  _formatDateTime(data["timeline"]?["acceptedAt"]),
                  Icons.access_time,
                ),
                if (data["timeline"]?["pickedUpAt"] != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Picked Up At',
                    _formatDateTime(data["timeline"]?["pickedUpAt"]),
                    Icons.inventory,
                  ),
                ],
                if (status == STATUS_REACHED && data["timeline"]?["reachedAt"] != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Reached Customer At',
                    _formatDateTime(data["timeline"]?["reachedAt"]),
                    Icons.location_on,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildOrderItemsCard(Map<String, dynamic> data, Color accentColor) {
    final items = data["items"] ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              _buildOrderItem(items[i], i, accentColor),
              if (i < items.length - 1) const Divider(height: 24),
            ],
            const Divider(height: 24),
            _buildTotalRow(
                'Items Total', '₹${data["subTotal"] ?? data["totalAmount"]}'),
            const SizedBox(height: 8),
            if (data["deliveryCharge"] != null) ...[
              _buildTotalRow('Delivery Fee', '₹${data["deliveryCharge"]}'),
              const SizedBox(height: 8),
            ],
            if (data["tax"] != null) ...[
              _buildTotalRow('Tax', '₹${data["tax"]}'),
              const SizedBox(height: 8),
            ],
            if (data["discount"] != null) ...[
              _buildTotalRow('Discount', '-₹${data["discount"]}'),
              const SizedBox(height: 8),
            ],
            const Divider(),
            const SizedBox(height: 8),
            _buildTotalRow(
              'Grand Total',
              '₹${data["totalAmount"]}',
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection(String address, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildSectionHeader('Delivery Address'),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItem(
      Map<String, dynamic> item, int index, Color accentColor) {
    final price = item["price"] ?? 0;
    final quantity = item["quantity"] ?? 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item["name"] ?? "Unknown Item",
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'quantity: $quantity',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Text(
          '₹$price',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, String amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
            color: isBold ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}