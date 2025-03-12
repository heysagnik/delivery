import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model2.dart';
import '../providers/order_provider.dart';
import '../widgets/pendingDelivery_widgets.dart';
import 'order_detail.dart';

class PendingDeliveries extends StatefulWidget {
  const PendingDeliveries({super.key});

  @override
  State<PendingDeliveries> createState() => _PendingDeliveriesState();
}

class _PendingDeliveriesState extends State<PendingDeliveries> {
  Future<List<Order2>>? pendingOrder;
  final Color acceptColor = const Color(0xFF2ECC71);
  final Color pendingColor = const Color(0xFFE74C3C);

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  Future<void> _refreshOrders() async {
    setState(() {
      pendingOrder = Provider.of<OrderProvider>(context, listen: false)
          .pendingOrderByDriver();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Pending Orders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrders,
        child: FutureBuilder<List<Order2>>(
          future: pendingOrder,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading orders...',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: pendingColor, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: pendingColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _refreshOrders,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refreshOrders,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.green, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'No pending deliveries found.',
                        style: TextStyle(color: Colors.grey[700], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final order = snapshot.data![index];
                return OrderCard(
                  order: order,
                  acceptColor: acceptColor,
                  pendingColor: pendingColor,
                  onViewDetails: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OrderDetailsPage(orderId: order.id),
                      ),
                    ).then((_) => _refreshOrders());
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
