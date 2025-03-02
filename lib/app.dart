import 'package:delivery/providers/driver_provider.dart';
import 'package:delivery/screens/profile_screen.dart';
import 'package:delivery/screens/available_delivery_screen.dart';
import 'package:delivery/screens/pending_deliveries_screen.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

class AppScreen extends StatefulWidget {
  const AppScreen({super.key});

  @override
  _AppScreenState createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  int _selectedIndex = 0;
  late final ValueNotifier<bool> _controller;

  final List<Widget> _pages = <Widget>[
    PendingDeliveries(),
    AvailableDeliveries(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();

    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    _controller =
        ValueNotifier<bool>(driverProvider.isLive); // Set initial value

    _controller.addListener(() {
      driverProvider.updateOnlineStatus(_controller.value);
    });
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
        leadingWidth: 110,
        leading: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: AdvancedSwitch(
            inactiveChild: const Text(
              "OFFLINE",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            activeChild: const Text(
              "ONLINE",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            controller: _controller,
            borderRadius: BorderRadius.circular(20),
            activeColor: Colors.green.shade600,
            inactiveColor: Colors.grey.shade600,
            width: 90,
            height: 35,
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
                ? PhosphorIconsBold.list
                : PhosphorIconsRegular.list),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
