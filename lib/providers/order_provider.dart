import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../models/order_model.dart';

class OrderProvider extends ChangeNotifier {

  Future<List<Order>> getPendingDeliveries() async {
    final url = 'http://taskmaster.outlfy.com/api/pending-deliveries';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch pending deliveries');
    }
  }

  Future<void> assignOrder(String selectedDriverId,String orderId) async {

    final url = 'http://taskmaster.outlfy.com/api/assign-driver';
    final body = jsonEncode({
      "deliveryId": orderId,
      "driverId": selectedDriverId,
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception('Failed to assign order');
      }
    } catch (error) {
      throw Exception('Error assigning order: $error');
    }
  }
}