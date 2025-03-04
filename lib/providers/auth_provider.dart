import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _mobile;
  String? _hash;
  bool _isSignedIn = false;

  String? get token => _token;
  String? get hash => _hash;
  String? get mobile => _mobile;
  bool get isSignedIn => _isSignedIn;

  final String baseUrl = "https://daykart.com/api/driver";
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Check if user is signed in
  Future<bool> checkIfSignedIn() async {
    final values = await _secureStorage.readAll();
    _token = values['token'];
    _hash = values['hash'];
    _mobile = values['mobile'];

    _isSignedIn = _token != null;
    notifyListeners();
    debugPrint('Sign-in status checked. isSignedIn: $_isSignedIn');
    return _isSignedIn;
  }

  // Initialize authentication state
  Future<void> initializeAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final values = await _secureStorage.readAll();

    _token = values['token'];
    _hash = values['hash'];
    _mobile = values['mobile'];
    _isSignedIn = prefs.getBool('isSignedIn') ?? false;

    notifyListeners();
  }

  // Login Request
  Future<void> login(String phoneNumber) async {
    final loginUrl = '$baseUrl/login/sendotp';
    _mobile = phoneNumber;

    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': phoneNumber}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _secureStorage.write(key: 'hash', value: data['hash']);
        await _secureStorage.write(key: 'mobile', value: data['mobile']);
        notifyListeners();
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      throw Exception('Login error');
    }
  }

  // Function to verify OTP
  Future<void> verifyOTP(String otp) async {
    final verifyUrl = '$baseUrl/login/verifyotp';

    // Await values from secure storage
    final String? hash = await _secureStorage.read(key: 'hash');
    final String? mobile = await _secureStorage.read(key: 'mobile');

    if (mobile == null || hash == null) {
      throw Exception('Missing required authentication data');
    }

    try {
      final response = await http.post(
        Uri.parse(verifyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile': mobile,
          'otp': otp,
          'hash': hash,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        _token = data['token'];
        await _secureStorage.write(key: 'token', value: _token);

        final prefs = await SharedPreferences.getInstance();
        _isSignedIn = true;
        await prefs.setBool('isSignedIn', true);

        if (data.containsKey('_id')) {
          await prefs.setString('id', data['_id']);
        }

        notifyListeners();
      } else {
        throw Exception('OTP verification failed: ${data['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      debugPrint('OTP verification error: $e');
      throw Exception('OTP verification failed');
    }
  }

}
