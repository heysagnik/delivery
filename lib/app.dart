import 'package:delivery/providers/driver_provider.dart';
import 'package:delivery/providers/notification_provider.dart';
import 'package:delivery/providers/order_provider.dart';
import 'package:delivery/screens/profile_screen.dart';
import 'package:delivery/screens/available_deliveries_screen.dart';
import 'package:delivery/screens/pending_deliveries_screen.dart';
import 'package:lite_rolling_switch/lite_rolling_switch.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

class AppScreen extends StatefulWidget {
  const AppScreen({super.key});

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  bool _isLive = false;
  int _selectedIndex = 0;
  bool _isLoading = true;

  final List<Widget> _pages = <Widget>[
    PendingDeliveries(),
    AvailableDeliveries(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAppStatus();
  }

  Future<void> _initializeAppStatus() async {
    try {
      final driverProvider = Provider.of<DriverProvider>(context, listen: false);

      // Fetch driver details which will update the isLive status
      await driverProvider.fetchDriverDetails();

      // Get the current status from the provider
      setState(() {
        _isLive = driverProvider.isLive;
        _isLoading = false;
      });

      // Initialize other providers
      Provider.of<NotificationProvider>(context, listen: false)
          .subscribeNotification();
      Provider.of<OrderProvider>(context, listen: false).pendingOrderByDriver();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load driver status: $e')),
      );
    }
  }

  void _updateOnlineStatus(bool newStatus) {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);

    // Call the provider method to update online status
    driverProvider.updateOnlineStatus(newStatus);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverProvider>(
      builder: (context, driverProvider, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            leadingWidth: 130,
            leading: _isLoading
                ? Center(child: CircularProgressIndicator())
                : Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: LiteRollingSwitch(
                value: driverProvider.isLive,
                textOn: 'ONLINE',
                textOff: 'OFFLINE',
                colorOn: Colors.green.shade600,
                colorOff: Colors.grey.shade600,
                iconOn: Icons.check,
                iconOff: Icons.close,
                textSize: 12.0,
                onChanged: _updateOnlineStatus,
                width: 110, onTap: () {},
                onDoubleTap: () {},
                onSwipe: () {},
              ),
            ),
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator())
              : IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Colors.white,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            elevation: 8,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 0
                    ? PhosphorIconsFill.timer
                    : PhosphorIconsRegular.timer),
                label: 'Pending',
              ),
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 1
                    ? PhosphorIconsFill.basket
                    : PhosphorIconsRegular.basket),
                label: 'Available',
              ),
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 2
                    ? PhosphorIconsBold.userCircle
                    : PhosphorIconsRegular.userCircle),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}