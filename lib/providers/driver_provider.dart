import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DriverProvider extends ChangeNotifier {
  bool _isLive = false;

  bool get isLive => _isLive;

  DriverProvider() {
    _loadOnlineStatus();
  }

  Future<String?> setSelectedDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('id');
  }

  Future<void> _loadOnlineStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isLive = prefs.getBool('isLive') ?? false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> fetchDriverDetails() async {
    try {
      final driverId = await setSelectedDriverId();
      final url = 'http://taskmaster.outlfy.com/api/driver-details/$driverId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load driver details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAvailableDrivers() async {
    const url = 'http://taskmaster.outlfy.com/api/drivers';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load drivers. Status Code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Error fetching drivers: $error');
      return []; // Return an empty list in case of an error
    }
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    _isLive = isOnline;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLive', isOnline); // Save state locally

    const apiUrl = "https://daykart.com/api/driver/islivetoggle";
    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"isLive": isOnline}),
      );

      if (response.statusCode == 200) {
        _isLive = isOnline; // Update local state
        notifyListeners(); // Notify UI to update
        debugPrint("Status updated successfully: isLive = $isLive");
      } else {
        debugPrint("Failed to update status: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }
}
