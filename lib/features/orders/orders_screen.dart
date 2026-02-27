import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pharmaco_delivery_partner/core/services/order_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:pharmaco_delivery_partner/core/providers/language_provider.dart';

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
    final lp = Provider.of<LanguageProvider>(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: lp.translate('available')),
              Tab(text: lp.translate('my_orders')),
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
  int _refreshToken = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
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
                      lp.translate('available_orders'),
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      lp.translate('real_time_updates'),
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
          child: RefreshIndicator(
            onRefresh: () async {
              if (!mounted) return;
              setState(() => _refreshToken++);
            },
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _orderService.getIncomingOrders(),
              builder: (context, snapshot) {
                // tie rebuilds to manual refresh
                final _ = _refreshToken;

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 200),
                      Center(child: CircularProgressIndicator()),
                    ],
                  );
                }
                if (snapshot.hasError) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 200),
                      Center(child: Text('Error: ${snapshot.error}')),
                    ],
                  );
                }

                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.12,
                      ),
                      _buildEmptyAvailableOrders(lp),
                    ],
                  );
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    return _AvailableOrderCard(order: orders[index]);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyAvailableOrders(LanguageProvider lp) {
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
            Text(
              lp.translate('no_orders_nearby'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              lp.translate('notify_new_orders'),
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
    final lp = Provider.of<LanguageProvider>(context);
    final orderService = OrderService();
    final String pharmacyTitle = (order['pharmacy_id'] != null)
        ? 'Pharmacy #${order['pharmacy_id'].toString().substring(0, 8).toUpperCase()}'
        : 'Pharmacy Request';
    final String addressText =
        (order['delivery_address'] as String?) ??
        (order['customer_address'] as String?) ??
        'Delivery Address N/A';
    final double amount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
    final double? distanceMeters = (order['distance_meters'] as num?)
        ?.toDouble();
    final String distanceText = distanceMeters != null
        ? '${(distanceMeters / 1000).toStringAsFixed(1)} ${lp.translate('km_away')}'
        : lp.translate('nearby');

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
                          pharmacyTitle,
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
                      child: Text(
                        lp.translate('urgent'),
                        style: const TextStyle(
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
                      addressText,
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
                      Text(
                        lp.translate('estimated_payout'),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        '₹$amount',
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
                          SnackBar(
                            content: Text(lp.translate('order_accepted')),
                            backgroundColor: Colors.green,
                          ),
                        );
                        
                        // Explicitly set status to 'accepted' for the redirected screen
                        final acceptedOrder = Map<String, dynamic>.from(order);
                        acceptedOrder['status'] = 'accepted';

                        // Redirect to Live Delivery Screen immediately after accepting
                        Navigator.pushNamed(
                          context,
                          AppRoutes.liveDelivery,
                          arguments: acceptedOrder,
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
                    child: Text(lp.translate('accept')),
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
    final lp = Provider.of<LanguageProvider>(context);
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
          return _buildEmptyState(lp);
        }

        final activeOrders = allOrders
            .where(
              (o) => [
                'ready',
                'preparing',
                'accepted',
                'picked_up',
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
              _buildSectionHeader(lp.translate('active_orders')),
              ...activeOrders.map(
                (order) => _OrderListItem(order: order, isActive: true),
              ),
              const SizedBox(height: 24),
            ],
            if (pastOrders.isNotEmpty) ...[
              _buildSectionHeader(lp.translate('past_history')),
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

  Widget _buildEmptyState(LanguageProvider lp) {
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
          Text(
            lp.translate('no_orders_found'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            lp.translate('my_orders_empty_desc'),
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

  Future<void> _launchMapsNavigation(BuildContext context, LanguageProvider lp) async {
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
        ).showSnackBar(SnackBar(content: Text(lp.translate('could_not_open_maps'))));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lp.translate('delivery_loc_not_available'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lp = Provider.of<LanguageProvider>(context);
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
                  '${lp.translate('order_from')} ${order['customer_name'] ?? 'N/A'}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${(order['total_amount'] as num?)?.toDouble() ?? 0.0}',
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
                  onTap: () => _showStatusExplanation(context, lp),
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
                  onPressed: () => _launchMapsNavigation(context, lp),
                  icon: const Icon(Icons.navigation_outlined),
                  label: Text(lp.translate('navigate_to_delivery')),
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
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    final lp = Provider.of<LanguageProvider>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        lp.translate(status.toLowerCase()).toUpperCase(),
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

void _showStatusExplanation(BuildContext context, LanguageProvider lp) {
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
              lp.translate('order_statuses'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatusExplanationRow(
              Colors.orange,
              lp.translate('pending'),
              lp.translate('pending_status_desc'),
            ),
            const Divider(height: 24),
            _buildStatusExplanationRow(
              Colors.green,
              lp.translate('completed'),
              lp.translate('completed_status_desc'),
            ),
            const Divider(height: 24),
            _buildStatusExplanationRow(
              Colors.red,
              lp.translate('cancelled'),
              lp.translate('cancelled_status_desc'),
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
    final lp = Provider.of<LanguageProvider>(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          const Icon(Icons.receipt_long, size: 100, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            isActiveTab ? lp.translate('no_active_orders') : lp.translate('no_past_orders'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            isActiveTab
                ? lp.translate('go_online_to_receive')
                : lp.translate('past_orders_appear_here'),
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
