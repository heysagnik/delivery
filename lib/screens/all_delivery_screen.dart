import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/driver_provider.dart';

class AllDeliveryScreen extends StatefulWidget {
  const AllDeliveryScreen({super.key});

  @override
  State<AllDeliveryScreen> createState() => _AllDeliveryScreenState();
}

class _AllDeliveryScreenState extends State<AllDeliveryScreen> {
  Future<List<Map<String, dynamic>>>? deliveries;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  void _loadDeliveries() {
    deliveries = Provider.of<DriverProvider>(context, listen: false)
        .fetchAllDeliveries();
  }

  Map<String, dynamic> _calculateStats(
      List<Map<String, dynamic>> deliveryList) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int todayDeliveries = 0;
    int totalDeliveryTimeMinutes = 0;
    int completedDeliveriesWithTime = 0;

    for (var delivery in deliveryList) {
      final deliveredAtStr = delivery['timeline']?['deliveredAt'];
      if (deliveredAtStr != null) {
        try {
          final deliveredAt = DateTime.parse(deliveredAtStr);
          final deliveredDate =
              DateTime(deliveredAt.year, deliveredAt.month, deliveredAt.day);
          if (deliveredDate.isAtSameMomentAs(today)) todayDeliveries++;

          final acceptedAtStr = delivery['timeline']?['acceptedAt'];
          if (acceptedAtStr != null &&
              delivery['deliveryStatus'] == 'delivered') {
            final acceptedAt = DateTime.parse(acceptedAtStr);
            totalDeliveryTimeMinutes +=
                deliveredAt.difference(acceptedAt).inMinutes;
            completedDeliveriesWithTime++;
          }
        } catch (_) {}
      }
    }
    final avgDeliveryTime = completedDeliveriesWithTime > 0
        ? (totalDeliveryTimeMinutes / completedDeliveriesWithTime)
            .toStringAsFixed(1)
        : '0';

    return {
      'todayDeliveries': todayDeliveries,
      'totalDeliveries': deliveryList.length,
      'avgDeliveryTime': avgDeliveryTime,
    };
  }

  
  Map<String, List<Map<String, dynamic>>> _groupDeliveriesByDate(
      List<Map<String, dynamic>> deliveryList) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (var delivery in deliveryList) {
      final deliveredAtStr = delivery['timeline']?['deliveredAt'];
      if (deliveredAtStr != null) {
        try {
          final deliveredAt = DateTime.parse(deliveredAtStr);
          final dateStr = DateFormat('yyyy-MM-dd').format(deliveredAt);
          grouped.putIfAbsent(dateStr, () => []);

          final acceptedAtStr = delivery['timeline']?['acceptedAt'];
          if (acceptedAtStr != null) {
            final acceptedAt = DateTime.parse(acceptedAtStr);
            delivery['deliveryTimeMinutes'] =
                deliveredAt.difference(acceptedAt).inMinutes;
          } else {
            delivery['deliveryTimeMinutes'] = null;
          }
          grouped[dateStr]!.add(delivery);
        } catch (_) {}
      }
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final sortedMap = <String, List<Map<String, dynamic>>>{};
    for (var key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }
    return sortedMap;
  }

  // Formats a date string to a readable value.
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      if (date.year == today.year &&
          date.month == today.month &&
          date.day == today.day) {
        return 'Today';
      } else if (date.year == yesterday.year &&
          date.month == yesterday.month &&
          date.day == yesterday.day) {
        return 'Yesterday';
      } else {
        return DateFormat('MMM dd, yyyy').format(date);
      }
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Delivery History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadDeliveries();
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: () async {
          setState(() {
            _loadDeliveries();
          });
          await deliveries;
          return;
        },
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: deliveries,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading delivery history...',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _loadDeliveries()),
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
            }

            final deliveryList = snapshot.data ?? [];
            if (deliveryList.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delivery_dining, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No deliveries found',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Completed deliveries will appear here',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            final stats = _calculateStats(deliveryList);
            final groupedDeliveries = _groupDeliveriesByDate(deliveryList);

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: DeliveryStatisticsCard(stats: stats),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text(
                          'Delivery History',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text('${deliveryList.length} deliveries',
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
               
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final dateKey = groupedDeliveries.keys.elementAt(index);
                      final deliveriesForDate = groupedDeliveries[dateKey]!;
                      return DeliveryDateGroup(
                        dateLabel: _formatDate(dateKey),
                        deliveries: deliveriesForDate,
                      );
                    },
                    childCount: groupedDeliveries.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            );
          },
        ),
      ),
    );
  }
}


class DeliveryStatisticsCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  const DeliveryStatisticsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delivery Statistics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      title: 'Today',
                      value: '${stats['todayDeliveries']}',
                      icon: Icons.today,
                      iconColor: Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      title: 'Total',
                      value: '${stats['totalDeliveries']}',
                      icon: Icons.inventory_2,
                      iconColor: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      title: 'Avg. Time',
                      value: '${stats['avgDeliveryTime']} min',
                      icon: Icons.timer,
                      iconColor: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class DeliveryDateGroup extends StatelessWidget {
  final String dateLabel;
  final List<Map<String, dynamic>> deliveries;
  const DeliveryDateGroup(
      {super.key, required this.dateLabel, required this.deliveries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            dateLabel,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50)),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: deliveries.length,
          itemBuilder: (context, idx) =>
              DeliveryItemCard(delivery: deliveries[idx]),
        ),
      ],
    );
  }
}


class DeliveryItemCard extends StatelessWidget {
  final Map<String, dynamic> delivery;
  const DeliveryItemCard({super.key, required this.delivery});

  String _formatTime(String deliveredAtStr) {
    try {
      final deliveredAt = DateTime.parse(deliveredAtStr);
      return DateFormat('h:mm a').format(deliveredAt);
    } catch (_) {
      return 'Unknown time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveredAtStr = delivery['timeline']?['deliveredAt'] ?? 'Unknown';
    final formattedTime = _formatTime(deliveredAtStr);
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ID: #${delivery['orderPK'] ?? 'Unknown ID'}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(formattedTime,
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: delivery['deliveryStatus'] == 'delivered'
                        ? Colors.green[50]
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    delivery['deliveryStatus'] ?? 'Unknown',
                    style: TextStyle(
                      color: delivery['deliveryStatus'] == 'delivered'
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                _DeliveryInfoItem(
                  icon: Icons.timer,
                  title: 'Delivered in',
                  value: delivery['deliveryTimeMinutes'] != null
                      ? '${delivery['deliveryTimeMinutes']} min'
                      : 'N/A',
                  iconColor: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  const _StatItem(
      {required this.title,
      required this.value,
      required this.icon,
      required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}


class _DeliveryInfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;
  const _DeliveryInfoItem(
      {required this.icon,
      required this.title,
      required this.value,
      required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
