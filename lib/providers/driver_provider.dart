import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DriverProvider extends ChangeNotifier {
  Future<List<Map<String, dynamic>>> fetchAvailableDrivers() async {
    final url = 'http://taskmaster.outlfy.com/api/drivers';
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
}
