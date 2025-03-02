import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late Future<Map<String, dynamic>> orderDetails;
  Map<String, String> driverNames = {}; // Cache driver names

  final Color accentColor = const Color(0xFF3498DB);
  bool isRefreshing = false;
  late var orderPK = 0;

  Future<Map<String, dynamic>> fetchOrderDetails() async {
    final url =
        'http://taskmaster.outlfy.com/api/delivery-details/${widget.orderId}';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      orderPK = data["orderPK"];
      if (data["deliveryBoy"] != null) {
        await fetchDriverName(data["deliveryBoy"]);
      }
      return data;
    } else {
      throw Exception('Failed to load order details');
    }
  }

  Future<void> refreshOrderDetails() async {
    setState(() {
      isRefreshing = true;
    });

    try {
      orderDetails = fetchOrderDetails();
      await orderDetails;
    } finally {
      if (mounted) {
        setState(() {
          isRefreshing = false;
        });
      }
    }
  }

  Future<void> fetchDriverName(String driverId) async {
    final url = 'http://taskmaster.outlfy.com/api/driver-details/$driverId';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final driverData = jsonDecode(response.body);
      setState(() {
        driverNames[driverId] = driverData["name"] ?? "Unknown Driver";
      });
    } else {
      setState(() {
        driverNames[driverId] = "Unknown Driver";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    orderDetails = fetchOrderDetails();
  }

  String formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return "N/A";

    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
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
        title: Text(
          'Order #$orderPK',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isRefreshing ? null : refreshOrderDetails,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: orderDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              isRefreshing) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: refreshOrderDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData) {
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

          final data = snapshot.data!;
          final bool isAccepted = data["deliveryStatus"] == "accepted";
          final String deliveryBoyId = data["deliveryBoy"] ?? "";
          final String deliveryBoyName = deliveryBoyId.isNotEmpty
              ? (driverNames[deliveryBoyId] ?? "Fetching...")
              : "Not Assigned";
          final String statusText = data["deliveryStatus"] ?? "pending";

          // Calculate total items and quantity
          int totalItems = data["items"]?.length ?? 0;
          int totalQuantity = 0;
          if (data["items"] != null) {
            for (var item in data["items"]) {
              totalQuantity += (item["quantity"] as num).toInt();
            }
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
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
                ),

                // Delivery details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Driver info
                      if (isAccepted) ...[
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                  formatDateTime(
                                      data["timeline"]?["acceptedAt"]),
                                  Icons.access_time,
                                ),
                                if (data["timeline"]?["pickedUpAt"] !=
                                    null) ...[
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    'Picked Up At',
                                    formatDateTime(
                                        data["timeline"]?["pickedUpAt"]),
                                    Icons.inventory,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Order items
                      _buildSectionHeader('Order Items'),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              for (var i = 0;
                                  i < (data["items"]?.length ?? 0);
                                  i++) ...[
                                _buildOrderItem(data["items"][i], i),
                                if (i < (data["items"]?.length ?? 0) - 1)
                                  const Divider(height: 24),
                              ],
                              const Divider(height: 24),
                              _buildTotalRow('Items Total',
                                  '₹${data["subTotal"] ?? data["totalAmount"]}'),
                              const SizedBox(height: 8),
                              if (data["deliveryCharge"] != null) ...[
                                _buildTotalRow('Delivery Fee',
                                    '₹${data["deliveryCharge"]}'),
                                const SizedBox(height: 8),
                              ],
                              if (data["tax"] != null) ...[
                                _buildTotalRow('Tax', '₹${data["tax"]}'),
                                const SizedBox(height: 8),
                              ],
                              if (data["discount"] != null) ...[
                                _buildTotalRow(
                                    'Discount', '-₹${data["discount"]}'),
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
                      ),

                      // Address information if available
                      if (data["deliveryAddress"] != null) ...[
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
                                    data["deliveryAddress"] ??
                                        "Address not provided",
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

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
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

  Widget _buildOrderItem(Map<String, dynamic> item, int index) {
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'picked':
        return Colors.orange;
      case 'delivered':
        return Colors.green[700]!;
      default:
        return Colors.amber; // pending or others
    }
  }
}
