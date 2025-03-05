import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/driver_provider.dart';

class AllDeliveryScreen extends StatefulWidget {
  const AllDeliveryScreen({super.key});

  @override
  State<AllDeliveryScreen> createState() => _AllDeliveryScreenState();
}

class _AllDeliveryScreenState extends State<AllDeliveryScreen> {
  Future<List<Map<String, dynamic>>>? deliveries;

  @override
  void initState() {
    super.initState();
    deliveries = Provider.of<DriverProvider>(context, listen: false)
        .fetchAllDeliveries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Delivery History'),
        backgroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: deliveries,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final deliveryList = snapshot.data ?? [];

          if (deliveryList.isEmpty) {
            return const Center(child: Text('No deliveries found'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Total Deliveries completed: ${deliveryList.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                // Fixing ListView height issue
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: deliveryList.length,
                  itemBuilder: (context, index) {
                    final delivery = deliveryList[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          'OrderPK: ${delivery['orderPK'] ?? 'Unknown OrderPK'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Delivered at: ${delivery['timeline']?['deliveredAt'] ?? 'Unknown date'}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: delivery['deliveryStatus'] == 'delivered'
                                ? Colors.green[50]
                                : Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            delivery['deliveryStatus'] ?? 'Unknown',
                            style: TextStyle(
                              color: delivery['deliveryStatus'] == 'delivered'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
