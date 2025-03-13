import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../providers/driver_provider.dart';

class AllDeliveryScreen extends StatefulWidget {
  const AllDeliveryScreen({super.key});

  @override
  State<AllDeliveryScreen> createState() => _AllDeliveryScreenState();
}

class _AllDeliveryScreenState extends State<AllDeliveryScreen>
    with SingleTickerProviderStateMixin {
  Future<List<Map<String, dynamic>>>? deliveries;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  late AnimationController _animationController;
  String? _filterStatus;

  final List<String> _statusFilters = ["All", "Delivered", "Rejected"];

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadDeliveries() {
    deliveries = Provider.of<DriverProvider>(context, listen: false)
        .fetchAllDoneDeliveries();
  }

  Map<String, dynamic> _calculateStats(
      List<Map<String, dynamic>> deliveryList) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int todayDeliveries = 0;
    int totalDeliveryTimeMinutes = 0;
    int completedDeliveriesWithTime = 0;
    double totalEarnings = 0;

    for (var delivery in deliveryList) {
      final deliveredAtStr = delivery['timeline']?['deliveredAt'] ??
          delivery['timeline']?['rejectedAt'];
      if (deliveredAtStr != null) {
        try {
          final deliveredAt = DateTime.parse(deliveredAtStr);
          final deliveredDate =
              DateTime(deliveredAt.year, deliveredAt.month, deliveredAt.day);
          if (deliveredDate.isAtSameMomentAs(today)) todayDeliveries++;

          // Calculate earnings (assuming there's a field for this or using a fixed amount)
          totalEarnings += delivery['deliveryFee'] ?? 0.0;

          final acceptedAtStr = delivery['timeline']?['acceptedAt'];
          if (acceptedAtStr != null) {
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
      'totalEarnings': totalEarnings.toStringAsFixed(0),
    };
  }

  Map<String, List<Map<String, dynamic>>> _groupDeliveriesByDate(
      List<Map<String, dynamic>> deliveryList) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    // Filter deliveries if a status filter is set
    final filteredList = _filterStatus == null || _filterStatus == "All"
        ? deliveryList
        : deliveryList
            .where((d) =>
                (d['deliveryStatus'] ?? "").toLowerCase() ==
                _filterStatus!.toLowerCase())
            .toList();

    for (var delivery in filteredList) {
      final deliveredAtStr = delivery['timeline']?['deliveredAt'] ??
          delivery['timeline']?['rejectedAt'];
      if (deliveredAtStr != null) {
        try {
          final deliveredAt = DateTime.parse(deliveredAtStr);
          final dateStr = DateFormat('yyyy-MM-dd').format(deliveredAt);
          grouped.putIfAbsent(dateStr, () => []);

          final acceptedAtStr = delivery['timeline']?['acceptedAt'] ??
              delivery['timeline']?['rejectedAt'];
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: RefreshIndicator(
        key: _refreshKey,
        color: Theme.of(context).primaryColor,
        backgroundColor: Colors.white,
        onRefresh: () async {
          setState(() {
            _loadDeliveries();
          });
          await deliveries;
        },
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: deliveries,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error);
            }

            final deliveryList = snapshot.data ?? [];
            if (deliveryList.isEmpty) {
              return _buildEmptyState();
            }

            final stats = _calculateStats(deliveryList);
            final groupedDeliveries = _groupDeliveriesByDate(deliveryList);

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _animationController,
                    child: DeliveryStatisticsCard(stats: stats),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        const Text(
                          'Delivery History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${groupedDeliveries.values.fold<int>(0, (sum, list) => sum + list.length)} deliveries',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),

                // Status Filter Tabs
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _statusFilters.map((status) {
                          final isSelected = _filterStatus == status ||
                              (_filterStatus == null && status == "All");
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(status),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _filterStatus =
                                      status == "All" ? null : status;
                                });
                              },
                              backgroundColor: Colors.grey[100],
                              selectedColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[700],
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              checkmarkColor: Theme.of(context).primaryColor,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                if (groupedDeliveries.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          Icon(Icons.filter_list,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No ${_filterStatus?.toLowerCase() ?? ''} deliveries found',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final dateKey = groupedDeliveries.keys.elementAt(index);
                        final deliveriesForDate = groupedDeliveries[dateKey]!;

                        return FadeTransition(
                          opacity: _animationController,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(
                                0.4 + (index * 0.1).clamp(0.0, 0.5),
                                1.0,
                                curve: Curves.easeOutQuart,
                              ),
                            )),
                            child: DeliveryDateGroup(
                              dateLabel: _formatDate(dateKey),
                              deliveries: deliveriesForDate,
                            ),
                          ),
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 60,
            width: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading delivery history...',
            style: TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Please wait while we retrieve your delivery records',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, color: Colors.red, size: 56),
          ),
          const SizedBox(height: 20),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'We couldn\'t load your delivery history.\nError: ${error.toString()}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() => _loadDeliveries()),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delivery_dining,
              size: 72,
              color: Theme.of(context).primaryColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No deliveries yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'When you complete deliveries, they will appear here',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: BorderSide(color: Theme.of(context).primaryColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade100),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.insights,
                        color: Theme.of(context).primaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Delivery Performance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const Spacer(),
                    // Info button that could show more details in the future
                    IconButton(
                      icon: const Icon(Icons.info_outline,
                          size: 20, color: Colors.grey),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Detailed statistics coming soon')),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                // Divider with gradient
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.5),
                        Colors.grey.shade200,
                      ],
                    ),
                  ),
                ),

                // Statistics Row
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.6,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _StatItem(
                      title: 'Today\'s Deliveries',
                      value: '${stats['todayDeliveries']}',
                      icon: Icons.today,
                      iconColor: Colors.blue,
                      backgroundColor: Colors.blue.shade50,
                    ),
                    _StatItem(
                      title: 'Total Deliveries',
                      value: '${stats['totalDeliveries']}',
                      icon: Icons.inventory_2,
                      iconColor: Colors.green,
                      backgroundColor: Colors.green.shade50,
                    ),
                    _StatItem(
                      title: 'Avg. Delivery Time',
                      value: '${stats['avgDeliveryTime']} min',
                      icon: Icons.timer,
                      iconColor: Colors.orange,
                      backgroundColor: Colors.orange.shade50,
                    ),
                    _StatItem(
                      title: 'Total Earnings',
                      value: '₹${stats['totalEarnings']}',
                      icon: Icons.payments,
                      iconColor: Colors.purple,
                      backgroundColor: Colors.purple.shade50,
                    ),
                  ],
                ),
              ],
            ),
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
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C3E50),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${deliveries.length} orders',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
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
    final deliveredAtStr = delivery['timeline']?['deliveredAt'] ??
        delivery['timeline']?['rejectedAt'] ??
        'Unknown';
    final formattedTime = _formatTime(deliveredAtStr);
    final isDelivered =
        (delivery['deliveryStatus'] ?? '').toLowerCase() == 'delivered';

    final amount = delivery['totalAmount'] ?? '0.00';
    final deliveryFee = delivery['deliveryFee'] ?? '0.00';
    final deliveryAddress = delivery['shippingAddress1'] ?? 'Unknown address';
    final customerName = delivery['customerName'] ?? 'Customer';

    // Try to get a formatted date from the timestamps
    String orderDate = 'Recent order';
    try {
      final dateTime = DateTime.parse(deliveredAtStr);
      orderDate = DateFormat('MMM d').format(dateTime);
    } catch (_) {}

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDelivered
              ? Colors.green.withOpacity(0.2)
              : Colors.orange.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: () {
              _showOrderDetailsModal(context);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Header with Status Bar
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDelivered
                          ? [Colors.green.shade50, Colors.white]
                          : [Colors.orange.shade50, Colors.white],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDelivered
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDelivered
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Icon(
                            isDelivered
                                ? Icons.check_circle
                                : Icons.cancel_outlined,
                            color: isDelivered ? Colors.green : Colors.orange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Order #${delivery['orderPK'] ?? 'Unknown'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: Color(0xFF2C3E50),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDelivered
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isDelivered
                                            ? Colors.green.withOpacity(0.3)
                                            : Colors.orange.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      isDelivered ? 'Delivered' : 'Rejected',
                                      style: TextStyle(
                                        color: isDelivered
                                            ? Colors.green.shade700
                                            : Colors.orange.shade800,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(Icons.access_time,
                                      size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 5),
                                  Text(
                                    orderDate,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    ' • $formattedTime',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Order Details
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Delivery info row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _DeliveryInfoTile(
                              icon: Icons.timer,
                              title: 'Time',
                              value: delivery['deliveryTimeMinutes'] != null
                                  ? '${delivery['deliveryTimeMinutes']} min'
                                  : 'N/A',
                              iconBgColor: Colors.blue.shade50,
                              iconColor: Colors.blue.shade600,
                            ),
                          ),
                          Expanded(
                            child: _DeliveryInfoTile(
                              icon: Icons.account_circle_outlined,
                              title: 'Customer',
                              value: customerName.length > 15
                                  ? '${customerName.substring(0, 15)}...'
                                  : customerName,
                              iconBgColor: Colors.teal.shade50,
                              iconColor: Colors.teal.shade600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Payment & address row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _DeliveryInfoTile(
                              icon: Icons.payments,
                              title: 'Payment',
                              value: '₹$amount',
                              subtitle: '₹$deliveryFee fee',
                              iconBgColor: Colors.purple.shade50,
                              iconColor: Colors.purple.shade600,
                            ),
                          ),
                          Expanded(
                            child: _DeliveryInfoTile(
                              icon: Icons.location_on,
                              title: 'Address',
                              value: deliveryAddress.length > 22
                                  ? '${deliveryAddress.substring(0, 22)}...'
                                  : deliveryAddress,
                              iconBgColor: Colors.red.shade50,
                              iconColor: Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.visibility, size: 16),
                              label: const Text('View Details'),
                              onPressed: () => _showOrderDetailsModal(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context).primaryColor,
                                side: BorderSide(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.5)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOrderDetailsModal(BuildContext context) {
    // For now just show a snackbar, but this could be expanded to show a detailed modal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Order details coming soon for #${delivery['orderPK']}')),
    );
  }
}

class _DeliveryInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final Color iconColor;
  final Color iconBgColor;

  const _DeliveryInfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF2C3E50),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    height: 1.2,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Could show more detailed stats in the future
            final message = 'Detailed $title statistics coming soon';
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(message)));
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 18),
                    ),
                    const Spacer(),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
