import 'dart:convert';
import 'package:delivery/providers/driver_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/order_provider.dart';

class AssignOrder extends StatefulWidget {
  final String orderId;

  const AssignOrder({super.key, required this.orderId});

  @override
  State<AssignOrder> createState() => _AssignOrderState();
}

class _AssignOrderState extends State<AssignOrder> {
  List<Map<String, dynamic>> drivers = [];
  String? selectedDriverId;
  bool isLoading = false;

  final Color primaryColor = const Color(0xFF2C3E50);
  final Color accentColor = const Color(0xFF3498DB);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    fetchDrivers();
  }

  Future<void> fetchDrivers() async {
    setState(() => isLoading = true);
    final fetchedDrivers =
    await Provider.of<DriverProvider>(context, listen: false)
        .fetchAvailableDrivers();
    setState(() {
      drivers = fetchedDrivers;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Assign Order'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a Driver:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : drivers.isEmpty
                  ? const Center(
                child: Text(
                  "No drivers available",
                  style: TextStyle(fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: drivers.length,
                itemBuilder: (context, index) {
                  final driver = drivers[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.person,
                          color: Colors.black54),
                      title: Text(
                        driver["name"] ?? "Unknown",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('ID: ${driver["_id"] ?? "N/A"}'),
                      trailing: Radio<String>(
                        value: driver["_id"],
                        groupValue: selectedDriverId,
                        onChanged: (value) {
                          setState(() {
                            selectedDriverId = value;
                          });
                        },
                        activeColor: accentColor,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: isLoading || selectedDriverId == null
                    ? null
                    : () async {
                  setState(() => isLoading = true);
                  try {
                    await Provider.of<OrderProvider>(context, listen: false)
                        .assignOrder(selectedDriverId!, widget.orderId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Order Assigned Successfully")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to assign order: $e")),
                    );
                  } finally {
                    setState(() => isLoading = false);
                  }
                },
                icon: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.check_circle),
                label: Text(isLoading ? 'Assigning...' : 'Assign Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
