import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/order_model.dart';
import '../models/order_model2.dart';

class OrderProvider extends ChangeNotifier {
  final String baseUrl = 'https://api.daykart.outlfy.com';
  //final String baseUrl = 'http://172.25.214.96:3001';
  final List<Order2> _pendingDeliveries = [];
  List<Order2> get pendingDeliveries => _pendingDeliveries;
  Order? _latestNewOrder;

  // Getter for the latest new order
  Order? get latestNewOrder => _latestNewOrder;

  // Method to set the latest new order received via FCM
  void setLatestNewOrder(Order order) {
    _latestNewOrder = order;
    notifyListeners();
  }

  // Clear latest new order after it's been handled
  void clearLatestNewOrder() {
    _latestNewOrder = null;
    notifyListeners();
  }

  Future<String?> getSelectedDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('id');
  }

  Future<List<Order>> getAvailableDeliveries() async {
    try {
      final url = '$baseUrl/api/pending-deliveries';
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
      final url = '$baseUrl/api/assign-driver';
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

  Future<List<Order2>> pendingOrderByDriver() async {
    var selectedDriver = await getSelectedDriverId();
    try {
      final url = '$baseUrl/api/pending-deliveries/$selectedDriver';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        debugPrint('Pending orders fetched successfully');
        final List<dynamic> jsonList = jsonDecode(response.body);

        return jsonList.map((json) => Order2.fromJson(json)).toList();
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
      final url = '$baseUrl/api/delivery-details/$orderId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print('Order details fetched successfully');
        final Map<String, dynamic> jsonMap = jsonDecode(response.body);
        print(jsonMap);
        return Order.fromJson(jsonMap);
      } else {
        throw Exception('Failed to load order details');
      }
    } catch (error) {
      print('Error fetching order details: $error');
      throw Exception('Error fetching order details');
    }
  }

  Future<void> changeOrderStatus(int orderPK, String status,
      {String? paymentMethod, String? reason}) async {
    try {
      final url = '$baseUrl/api/update-status';
      final body = jsonEncode({
        "status": status,
        "deliveryId": orderPK,
        if (paymentMethod != null) "paymentMethod": paymentMethod,
        if (reason != null) "reason": reason,
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
