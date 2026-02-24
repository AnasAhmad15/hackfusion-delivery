import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/core/services/order_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final OrderService _orderService = OrderService();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Available'),
              Tab(text: 'My Orders'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_AvailableOrdersList(), _MyOrdersList()],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailableOrdersList extends StatefulWidget {
  @override
  __AvailableOrdersListState createState() => __AvailableOrdersListState();
}

class __AvailableOrdersListState extends State<_AvailableOrdersList> {
  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.blue.withOpacity(0.05),
          child: Row(
            children: [
              const Icon(Icons.radar, size: 18, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available orders',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Real-time updates active',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _orderService.getIncomingOrders(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final orders = snapshot.data ?? [];
              if (orders.isEmpty) {
                return _buildEmptyAvailableOrders();
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  return _AvailableOrderCard(order: orders[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyAvailableOrders() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_searching,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No orders nearby',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ll notify you when new orders appear in your area.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailableOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _AvailableOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderService = OrderService();
    final double? distanceMeters = (order['distance_meters'] as num?)
        ?.toDouble();
    final String distanceText = distanceMeters != null
        ? '${(distanceMeters / 1000).toStringAsFixed(1)} km away'
        : 'Nearby';

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: order['is_emergency'] == true
              ? Border.all(color: Colors.red.shade300, width: 2)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['pharmacy_name'] ?? 'Pharmacy Request',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        Text(
                          distanceText,
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (order['is_emergency'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'URGENT',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order['customer_address'] ?? 'Delivery Address N/A',
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimated Payout',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        '₹${(order['payout'] as num?)?.toDouble() ?? 0.0}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await orderService.acceptOrder(order['id']);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Order accepted!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('ACCEPT'),
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

class _MyOrdersList extends StatefulWidget {
  @override
  __MyOrdersListState createState() => __MyOrdersListState();
}

class __MyOrdersListState extends State<_MyOrdersList> {
  final OrderService _orderService = OrderService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _orderService.getMyOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allOrders = snapshot.data ?? [];
        if (allOrders.isEmpty) {
          return _buildEmptyState();
        }

        final activeOrders = allOrders
            .where(
              (o) => [
                'assigned',
                'accepted',
                'picked_up',
                'on_the_way',
                'delivered',
              ].contains(o['status']?.toString().toLowerCase()),
            )
            .toList();

        final pastOrders = allOrders
            .where(
              (o) => [
                'completed',
                'cancelled',
              ].contains(o['status']?.toString().toLowerCase()),
            )
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (activeOrders.isNotEmpty) ...[
              _buildSectionHeader('Active Orders'),
              ...activeOrders.map(
                (order) => _OrderListItem(order: order, isActive: true),
              ),
              const SizedBox(height: 24),
            ],
            if (pastOrders.isNotEmpty) ...[
              _buildSectionHeader('Past History'),
              ...pastOrders.map(
                (order) => _OrderListItem(order: order, isActive: false),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No orders found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Your assigned and past orders will appear here',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _OrderListItem extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool isActive;

  const _OrderListItem({required this.order, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final status = (order['status'] as String? ?? 'unknown').toLowerCase();
    final bool isFinalized = ['completed', 'cancelled'].contains(status);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: () {
          if (isFinalized) {
            Navigator.pushNamed(
              context,
              AppRoutes.orderSummary,
              arguments: order,
            );
          } else {
            Navigator.pushNamed(
              context,
              AppRoutes.orderDetails,
              arguments: order,
            );
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isFinalized ? Icons.receipt_long : Icons.shopping_bag_outlined,
            color: _getStatusColor(status),
            size: 20,
          ),
        ),
        title: Text(
          'Order #${order['id'].toString().substring(0, 8).toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              order['customer_address'] ?? 'No address',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            _StatusBadge(status: status),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'picked_up':
        return Colors.orange;
      case 'on_the_way':
        return Colors.blue;
      case 'accepted':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _OrderCard({required this.order});

  Future<void> _launchMapsNavigation(BuildContext context) async {
    final lat = order['delivery_lat'];
    final lng = order['delivery_lng'];

    if (lat != null && lng != null) {
      final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open maps.')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery location not available.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = order['created_at'] != null
        ? DateFormat(
            'MMM d, h:mm a',
          ).format(DateTime.parse(order['created_at']))
        : 'N/A';
    final status = order['status'] as String? ?? 'unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order from ${order['customer_name'] ?? 'N/A'}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${(order['payout'] as num?)?.toDouble() ?? 0.0}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatusBadge(status: status),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showStatusExplanation(context),
                  child: Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  time,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (status == 'accepted' || status == 'picked_up') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _launchMapsNavigation(context),
                  icon: const Icon(Icons.navigation_outlined),
                  label: const Text('NAVIGATE TO DELIVERY'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'picked_up':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'on_the_way':
        return Colors.blue;
      case 'assigned':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

void _showStatusExplanation(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Statuses',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatusExplanationRow(
              Colors.orange,
              'Pending',
              'You have accepted this order and need to complete the delivery.',
            ),
            const Divider(height: 24),
            _buildStatusExplanationRow(
              Colors.green,
              'Completed',
              'You have successfully completed this delivery.',
            ),
            const Divider(height: 24),
            _buildStatusExplanationRow(
              Colors.red,
              'Cancelled',
              'This order was cancelled by the customer or the system.',
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildStatusExplanationRow(Color color, String title, String subtitle) {
  return Row(
    children: [
      Icon(Icons.circle, color: color, size: 16),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(subtitle, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final bool isActiveTab;
  const _EmptyState({required this.onRefresh, required this.isActiveTab});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          const Icon(Icons.receipt_long, size: 100, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            isActiveTab ? 'No Active Orders' : 'No Past Orders',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            isActiveTab
                ? 'Go online on the dashboard to start receiving orders.'
                : 'Your completed or cancelled orders will appear here.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
