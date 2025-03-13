import 'package:delivery/models/driver_model.dart';
import 'package:delivery/providers/driver_provider.dart';
import 'package:delivery/utils.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/profile_widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<Driver>? driverDetails;
  bool isLoading = false;

  Future<void> _refreshDriverDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      final newDriver =
          await Provider.of<DriverProvider>(context, listen: false)
              .fetchDriverDetails();

      setState(() {
        driverDetails = Future.value(newDriver); // ✅ Now updates the UI
      });
    } catch (error) {
      showSnackBar(context, 'Error refreshing driver details: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      // Clear SharedPreferences data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        // Navigate to login screen and remove all previous routes
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (error) {
      showSnackBar(context, 'Error logging out: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      setState(() {
        _refreshDriverDetails();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   backgroundColor: Colors.white,
      //   title: const Text(
      //     'Driver Details',
      //     style: TextStyle(
      //       fontWeight: FontWeight.bold,
      //     ),
      //   ),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(PhosphorIconsBold.signOut, color: Colors.red),
      //       onPressed: _logout,
      //       tooltip: 'Logout',
      //     ),
      //     SizedBox(width: 16),
      //   ],
      // ),
      body: RefreshIndicator(
        onRefresh: _refreshDriverDetails,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : FutureBuilder<Driver>(
                future: driverDetails,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Loading driver details...',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _refreshDriverDetails,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C3E50),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData) {
                    return const Center(
                      child: Text('No driver details available'),
                    );
                  }

                  final driver = snapshot.data!;
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: DriverProfileHeader(driver: driver),
                  );
                },
              ),
      ),
    );
  }
}
