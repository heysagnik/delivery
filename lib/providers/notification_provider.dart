import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider with ChangeNotifier {
  String baseUrl='https://api.daykart.outlfy.com';
  Future<String?> getSelectedDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('id');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcmToken');
  }

  Future<void> subscribeNotification() async {
    try {
    final Uri url = Uri.parse('$baseUrl/api/driver/subscribe');
    final String? token = await getToken();
    final String? id = await getSelectedDriverId();

    if (token == null || id == null) {
      debugPrint('Error: Missing fcmToken or driverId');
      return;
    }
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "fcmToken": token,
          'driverId': id,
        }),
      );

      debugPrint("Response Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        debugPrint('Notification sent successfully');
      } else {
        debugPrint('Failed to send notification: ${responseBody['message'] ?? response.body}');
      }
    } catch (error) {
      debugPrint('Error sending notification: $error');
    }
  }
}
