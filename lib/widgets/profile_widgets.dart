import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/driver_model.dart';
import '../screens/all_done_delivery_screen.dart';

class DriverProfileHeader extends StatelessWidget {
  final Driver driver;

  const DriverProfileHeader({super.key, required this.driver});

  Future<void> _logout(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.of(context).pop();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (error) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileHeaderSection(driver: driver),
        const SizedBox(height: 20),
        ActionButtonsRow(),
        const SizedBox(height: 24),
        const SectionLabel(label: 'Status'),
        StatusCardsRow(driver: driver),
        const SizedBox(height: 20),
        const SectionLabel(label: 'Settings'),
        SettingsSection(onLogout: () => _logout(context)),
        const SizedBox(height: 30),
      ],
    );
  }
}

///--------------------------------------------------------------
/// Profile header section including image and basic info.
///--------------------------------------------------------------
class _ProfileHeaderSection extends StatelessWidget {
  final Driver driver;

  const _ProfileHeaderSection({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ProfileImage(isActive: driver.isActive),
          const SizedBox(width: 16),
          ProfileInfo(
              name: driver.name,
              mobile: driver.mobile,
              isActive: driver.isActive),
        ],
      ),
    );
  }
}

///--------------------------------------------------------------
/// Displays the driver image with status indicator.
///--------------------------------------------------------------
class ProfileImage extends StatelessWidget {
  final bool isActive;

  const ProfileImage({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey[100],
          child: const Icon(Icons.person, color: Color(0xFF555555), size: 40),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            height: 18,
            width: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.green : Colors.red,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

///--------------------------------------------------------------
/// Displays the driver basic info.
///--------------------------------------------------------------
class ProfileInfo extends StatelessWidget {
  final String name;
  final String mobile;
  final bool isActive;

  const ProfileInfo({
    super.key,
    required this.name,
    required this.mobile,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isNotEmpty ? name : 'Driver',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mobile.isNotEmpty ? mobile : 'No phone',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: isActive ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

///--------------------------------------------------------------
/// Row for minimal action buttons
///--------------------------------------------------------------
class ActionButtonsRow extends StatelessWidget {
  const ActionButtonsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          _MinimalActionButton(
            icon: Icons.local_shipping_outlined,
            label: 'My Deliveries',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AllDeliveryScreen()),
              );
            },
          ),
          // Additional buttons can be added here.
        ],
      ),
    );
  }
}

///--------------------------------------------------------------
/// Minimal action button widget.
///--------------------------------------------------------------
class _MinimalActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _MinimalActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

///--------------------------------------------------------------
/// Section label widget.
///--------------------------------------------------------------
class SectionLabel extends StatelessWidget {
  final String label;

  const SectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
    );
  }
}

///--------------------------------------------------------------
/// Status cards row: shows online status and delivery status.
///--------------------------------------------------------------
class StatusCardsRow extends StatelessWidget {
  final Driver driver;

  const StatusCardsRow({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatusCard(
            icon: Icons.access_time_outlined,
            label: 'Online Status',
            status: driver.isLive ? 'Live' : 'Offline',
            statusColor: driver.isLive ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatusCard(
            icon: Icons.directions_run_outlined,
            label: 'Delivery Status',
            status: driver.isReady ? 'Ready' : 'Busy',
            statusColor: driver.isReady ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }
}

///--------------------------------------------------------------
/// Status card widget.
///--------------------------------------------------------------
class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String status;
  final Color statusColor;

  const _StatusCard({
    required this.icon,
    required this.label,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                status,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: statusColor),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withOpacity(0.7),
                  boxShadow: [
                    BoxShadow(
                        color: statusColor.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1)
                  ],
                ),
              )
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 6),
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [statusColor, statusColor.withOpacity(0.3)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

///--------------------------------------------------------------
/// Settings section widget.
///--------------------------------------------------------------
class SettingsSection extends StatelessWidget {
  final VoidCallback onLogout;

  const SettingsSection({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        children: [
          _SettingsItem(
            icon: Icons.notifications_none_outlined,
            title: 'Notifications',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Notification Settings Coming Soon')),
              );
            },
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _SettingsItem(
            icon: Icons.help_outline_outlined,
            title: 'Help & Support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help Center Coming Soon')),
              );
            },
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _SettingsItem(
            icon: Icons.logout_outlined,
            title: 'Sign Out',
            textColor: Colors.red[700],
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

///--------------------------------------------------------------
/// Individual settings item widget.
///--------------------------------------------------------------
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? textColor;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: textColor ?? Colors.grey[700]),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? Colors.grey[800]),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
