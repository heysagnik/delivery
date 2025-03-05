import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  Future<String?> getSelectedDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('id');
  }

  Future<List<Order>> getAvailableDeliveries() async {
    try {
      final url = 'https://taskmaster.outlfy.com/api/pending-deliveries';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Order.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch available deliveries');
      }
    } catch (error) {
      print('Error fetching available deliveries: $error');
      throw Exception('Error fetching available deliveries');
    }
  }

  Future<void> assignOrder(String orderId) async {
    try {
      final url = 'https://taskmaster.outlfy.com/api/assign-driver';
      var selectedDriver = await getSelectedDriverId();
      final body = jsonEncode({
        "deliveryId": orderId,
        "driverId": selectedDriver,
      });
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode == 200) {
        print('Order assigned successfully');
        notifyListeners();
        return;
      } else {
        throw Exception('Failed to assign order');
      }
    } catch (error) {
      print('Error assigning order: $error');
      throw Exception('Error assigning order: $error');
    }
  }

  Future<List<Order>> pendingOrderByDriver() async {
    var selectedDriver = await getSelectedDriverId();
    try {
      final url =
          'https://taskmaster.outlfy.com/api/pending-deliveries/$selectedDriver';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print('Pending orders fetched successfully');
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Order.fromJson(json)).toList();
      } else {
        throw Exception('Failed to complete order');
      }
    } catch (error, st) {
      print(st);
      throw Exception('Error completing order: $error');
    }
  }

  Future<Order> fetchOrderDetails(String orderId) async {
    try {
      final url = 'https://taskmaster.outlfy.com/api/delivery-details/$orderId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print('Order details fetched successfully');
        final Map<String, dynamic> jsonMap = jsonDecode(response.body);
        return Order.fromJson(jsonMap);
      } else {
        throw Exception('Failed to load order details');
      }
    } catch (error) {
      print('Error fetching order details: $error');
      throw Exception('Error fetching order details');
    }
  }

  Future<void> changeOrderStatus(int orderPK, String status) async {
    try {
      final url = 'https://taskmaster.outlfy.com/api/update-status';
      final body = jsonEncode({
        "status": status,
        "deliveryId": orderPK,
      });

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode == 200) {
        print('Order status updated successfully to $status');
        notifyListeners();
        return;
      } else {
        throw Exception('Failed to update order status');
      }
    } catch (error) {
      throw Exception('Error updating order status: $error');
    }
  }
}
