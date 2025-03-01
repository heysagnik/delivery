import 'package:delivery/screens/gigs.dart';
import 'package:delivery/screens/home.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AppScreen extends StatefulWidget {
  const AppScreen({super.key});

  @override
  _AppScreenState createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  int _selectedIndex = 0;
  final _controller = ValueNotifier<bool>(false);

  // Separated tab pages for scalability
  final List<Widget> _pages = <Widget>[
    HomePage(),
    GigsPage(),
    Center(child: Text('Tab 3 Content')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white12,
        leadingWidth: 110,
        leading: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: AdvancedSwitch(
              inactiveChild: Text(
                "OFFLINE",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              activeChild: Text(
                "ONLINE",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              controller: _controller,
              borderRadius: BorderRadius.circular(20),
              activeColor: Colors.green.shade600,
              inactiveColor: Colors.grey.shade600,
              width: 90,
              height: 35,
              enabled: true,
              disabledOpacity: 0.5,
            )),
        // actions: [
        //   IconButton(
        //     icon: Icon(PhosphorIconsBold.bellRinging),
        //     onPressed: () {
        //       // Notification functionality
        //     },
        //   ),
        //   IconButton(
        //     icon: Icon(PhosphorIconsBold.lifebuoy),
        //     onPressed: () {
        //       // Help functionality
        //     },
        //   )
        // ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        elevation: 8,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 0
                ? PhosphorIconsFill.house
                : PhosphorIconsRegular.house),
            label: 'Pending Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 1
                ? PhosphorIconsFill.basket
                : PhosphorIconsRegular.basket),
            label: 'Available Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 2
                ? PhosphorIconsBold.person
                : PhosphorIconsRegular.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
