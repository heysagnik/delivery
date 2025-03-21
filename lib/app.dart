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
import 'package:shared_preferences/shared_preferences.dart';

class AppScreen extends StatefulWidget {
  const AppScreen({super.key});

  @override
  _AppScreenState createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  // Initialize isLive to false
  bool isLive = false;
  int _selectedIndex = 0;

  final List<Widget> _pages = <Widget>[
    PendingDeliveries(),
    AvailableDeliveries(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadOnlineStatus();

    Provider.of<NotificationProvider>(context, listen: false)
        .subscribeNotification();

    Provider.of<OrderProvider>(context, listen: false).pendingOrderByDriver();
  }

  Future<void> _loadOnlineStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isLive = prefs.getBool('isLive') ?? false;
    });

    // Update driver provider with saved status
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    await driverProvider.updateOnlineStatus(isLive);
  }

  Future<void> _saveOnlineStatus(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLive', value);
    setState(() {
      isLive = value;
    });

    // Update driver provider with new status
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    driverProvider.updateOnlineStatus(value);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leadingWidth: 130,
        leading: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: LiteRollingSwitch(
            value: isLive,
            textOn: 'ONLINE',
            textOff: 'OFFLINE',
            colorOn: Colors.green.shade600,
            colorOff: Colors.grey.shade600,
            iconOn: Icons.check,
            iconOff: Icons.close,
            textSize: 12.0,
            onTap: () {},
            onDoubleTap: () {},
            onSwipe: () {},
            onChanged: (bool state) {
              _saveOnlineStatus(state);
            },
            width: 110,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsFill.bell, size: 24),
            onPressed: () {
              // Notification functionality
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: IndexedStack(
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
  }
}
