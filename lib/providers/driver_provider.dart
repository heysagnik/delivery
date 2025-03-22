import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/driver_model.dart';

class DriverProvider extends ChangeNotifier {
  bool _isLive = false;

  bool get isLive => _isLive;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getSelectedDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('id');
  }

  // Future<void> _loadOnlineStatus() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   _isLive = prefs.getBool('isLive') ?? false;
  //   notifyListeners();
  // }

  Future<Driver> fetchDriverDetails() async {
    try {
      final token = await getToken();
      final url = 'https://daykart.com/api/driver/profile';
      final response = await http.get(headers: {
        "Content-Type": "application/json",
        "Authorization": "$token" ?? '',
      }, Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print(jsonData);

        if (jsonData['success'] == true) {
          return Driver.fromJson(jsonData['data']);
        }
        else {
          throw Exception('Failed to load driver details');
        }
      } else {
        throw Exception(
            'Failed to load driver details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    _isLive = isOnline;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLive', isOnline); // Save state locally
    final token = await getToken();
    const apiUrl = "https://daykart.com/api/driver/islivetoggle";
    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "$token" ?? '',
          "Content-Type": "application/json",
        },
        body: jsonEncode({"isLive": isOnline}),
      );

      final responseData = jsonDecode(response.body); // ✅ Proper JSON parsing
      if (responseData['success'] == true) {
        _isLive = isOnline; // Update local state
        notifyListeners(); // Notify UI to update
        print("Status updated successfully: isLive = $isLive");
        fetchDriverDetails();
      } else {
        debugPrint("Failed to update status: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllDoneDeliveries() async {
    try {
      final url = 'http://taskmaster.outlfy.com/api/delivered-deliveries';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);

        return jsonData.map((e) => e as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load deliveries: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
