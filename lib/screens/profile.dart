import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header
              Container(
                margin: const EdgeInsets.symmetric(vertical: 24),
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'DELIVERY PARTNER ID',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade900,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        // Profile photo
                        Container(
                          width: 80,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            image: const DecorationImage(
                              image: NetworkImage(
                                  'https://randomuser.me/api/portraits/men/32.jpg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Personal details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'JOHN DOE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ID: DP-${DateTime.now().year}-12345',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Phone: +1 234 567 8900',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Partner Since: JAN 2023',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green.shade700),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                PhosphorIconsBold.sealCheck,
                                size: 18,
                                color: Colors.green.shade800,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'VERIFIED',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          PhosphorIconsRegular.identificationBadge,
                          size: 40,
                          //color: Colors.indigo.shade900,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 14),
              _buildSettingsGroup([
                _buildMenuItem(
                  icon: PhosphorIconsRegular.wallet,
                  title: 'Earnings',
                  subtitle: 'Payment history and balance',
                  //iconColor: Colors.green.shade600,
                  showBadge: true,
                ),
                _buildMenuItem(
                  icon: PhosphorIconsRegular.translate,
                  title: 'Language',
                  subtitle: 'English (US)',
                  //iconColor: Colors.blue.shade600,
                ),
                _buildMenuItem(
                  icon: PhosphorIconsRegular.info,
                  title: 'About Us',
                  subtitle: 'Terms, privacy, and app info',
                  //iconColor: Colors.purple.shade600,
                ),
                _buildMenuItem(
                  icon: PhosphorIconsRegular.headset,
                  title: 'Support',
                  subtitle: 'Contact customer service',
                  //iconColor: Colors.orange.shade600,
                ),
              ]),

              const SizedBox(height: 48),

              // Version info
              Center(
                child: Column(
                  children: [
                    Text(
                      'Version 0.0.1',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '© 2025 DayKart',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    bool showBadge = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (iconColor ?? Colors.black).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: iconColor ?? Colors.black,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),

                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Badge (if needed)
                if (showBadge)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                // Arrow
                Icon(
                  PhosphorIconsRegular.caretRight,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (title != "Support")
          Divider(
              indent: 78,
              endIndent: 20,
              height: 1,
              thickness: 0.5,
              color: Colors.grey.shade200),
      ],
    );
  }
}
