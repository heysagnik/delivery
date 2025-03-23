import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';
import '../widgets/availableDelivery_widgets.dart';
import 'order_alert_screen.dart';

class AvailableDeliveries extends StatefulWidget {
  const AvailableDeliveries({super.key});

  @override
  State<AvailableDeliveries> createState() => _AvailableDeliveriesState();
}

class _AvailableDeliveriesState extends State<AvailableDeliveries> {
  late Future<List<Order>> availableOrders;
  final Color acceptColor = const Color(0xFF25B462);
  final Color pendingColor = const Color(0xFFE74C3C);

  @override
  void initState() {
    super.initState();
    _refreshOrders();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false)
          .addListener(_checkForNewOrders);
    });
  }

  @override
  void dispose() {
    // Remove the listener
    Provider.of<OrderProvider>(context, listen: false)
        .removeListener(_checkForNewOrders);
    super.dispose();
  }

  void _checkForNewOrders() {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final latestOrder = orderProvider.latestNewOrder;

    if (latestOrder != null) {
      // Show fullscreen alert
      _showOrderAlert(latestOrder);
      // Clear latest order to prevent showing it again
      orderProvider.clearLatestNewOrder();
    }
  }

  void _showOrderAlert(Order order) {
    var orderProvider = Provider.of<OrderProvider>(context, listen: false);

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => OrderAlertScreen(
          order: order,
          onAccept: () async {
            await orderProvider.assignOrder(order.id);
            await orderProvider.pendingOrderByDriver();
            Navigator.of(context).pop();
            Navigator.pushReplacementNamed(context, '/appScreen');
          },
          onDecline: () {
            Navigator.of(context).pop(); // Just close the alert
            _refreshOrders(); // Refresh to see other available orders
          },
          timeoutSeconds: 30,
        ),
      ),
    );
  }

  Future<void> _refreshOrders() async {
    setState(() {
      availableOrders = Provider.of<OrderProvider>(context, listen: false)
          .getAvailableDeliveries();
    });
  }

  @override
  Widget build(BuildContext context) {
    var orderProvider = Provider.of<OrderProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Available Orders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrders,
            tooltip: 'Refresh Orders',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrders,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: FutureBuilder<List<Order>>(
              future: availableOrders,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator();
                } else if (snapshot.hasError) {
                  return ErrorMessage(
                    message: snapshot.error.toString(),
                    onRetry: () {
                      setState(() {
                        availableOrders =
                            orderProvider.getAvailableDeliveries();
                      });
                    },
                    pendingColor: pendingColor,
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const EmptyDataWidget();
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final order = snapshot.data![index];
                    return OrderCard(
                      order: order,
                      acceptColor: acceptColor,
                      pendingColor: pendingColor,
                      onAccept: () async {
                        await Provider.of<OrderProvider>(context, listen: false)
                            .assignOrder(order.id);
                        await Provider.of<OrderProvider>(context, listen: false)
                            .pendingOrderByDriver();
                        Navigator.pushReplacementNamed(context, '/appScreen');
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
