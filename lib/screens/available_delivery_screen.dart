import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';
import '../widgets/availableDelivery_widgets.dart';

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
    availableOrders = Provider.of<OrderProvider>(context, listen: false)
        .getAvailableDeliveries();
  }

  @override
  Widget build(BuildContext context) {
    var orderProvider = Provider.of<OrderProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Available Orders',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Expanded(
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
                            Provider.of<OrderProvider>(context, listen: false)
                                .assignOrder(order.id);
                            Provider.of<OrderProvider>(context, listen: false)
                                .pendingOrderByDriver();
                            Navigator.pushReplacementNamed(context, '/appScreen');
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
