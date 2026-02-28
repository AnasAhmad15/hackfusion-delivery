import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pharmaco_delivery_partner/core/services/order_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:pharmaco_delivery_partner/core/providers/language_provider.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

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
          Container(
            color: PharmacoTokens.white,
            child: TabBar(
              tabs: [
                Tab(text: lp.translate('available')),
                Tab(text: lp.translate('my_orders')),
              ],
            ),
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
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: PharmacoTokens.space20, vertical: PharmacoTokens.space16),
          decoration: BoxDecoration(
            color: PharmacoTokens.primarySurface,
            border: const Border(bottom: BorderSide(color: PharmacoTokens.neutral200, width: 1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: PharmacoTokens.white, shape: BoxShape.circle, boxShadow: PharmacoTokens.shadowZ1()),
                child: const Icon(Icons.radar_rounded, size: 20, color: PharmacoTokens.primaryBase),
              ),
              const SizedBox(width: PharmacoTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lp.translate('available_orders'), style: theme.textTheme.titleSmall?.copyWith(fontWeight: PharmacoTokens.weightBold, color: PharmacoTokens.primaryDark)),
                    const SizedBox(height: 2),
                    Text(lp.translate('real_time_updates'), style: theme.textTheme.labelSmall?.copyWith(color: PharmacoTokens.primaryBase)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: PharmacoTokens.primaryBase,
            onRefresh: () async { if (!mounted) return; setState(() => _refreshToken++); },
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _orderService.getIncomingOrders(),
              builder: (context, snapshot) {
                final _ = _refreshToken;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [SizedBox(height: 200), Center(child: CircularProgressIndicator(color: PharmacoTokens.primaryBase))]);
                }
                if (snapshot.hasError) {
                  return ListView(physics: const AlwaysScrollableScrollPhysics(), children: [const SizedBox(height: 200), Center(child: Text('Error: ${snapshot.error}'))]);
                }
                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return ListView(physics: const AlwaysScrollableScrollPhysics(), children: [SizedBox(height: MediaQuery.of(context).size.height * 0.12), _buildEmptyAvailableOrders(lp, theme)]);
                }
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(PharmacoTokens.space16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) => _AvailableOrderCard(order: orders[index]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyAvailableOrders(LanguageProvider lp, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PharmacoTokens.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_searching_rounded, size: 64, color: PharmacoTokens.neutral300),
            const SizedBox(height: PharmacoTokens.space16),
            Text(lp.translate('no_orders_nearby'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: PharmacoTokens.weightBold)),
            const SizedBox(height: PharmacoTokens.space8),
            Text(lp.translate('notify_new_orders'), style: theme.textTheme.bodyMedium?.copyWith(color: PharmacoTokens.neutral500), textAlign: TextAlign.center),
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
    final String pharmacyTitle = (order['pharmacy_id'] != null) ? 'Pharmacy #${order['pharmacy_id'].toString().substring(0, 8).toUpperCase()}' : 'Pharmacy Request';
    final String addressText = (order['delivery_address'] as String?) ?? (order['customer_address'] as String?) ?? 'Delivery Address N/A';
    final double amount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
    final double? distanceMeters = (order['distance_meters'] as num?)?.toDouble();
    final String distanceText = distanceMeters != null ? '${(distanceMeters / 1000).toStringAsFixed(1)} ${lp.translate('km_away')}' : lp.translate('nearby');

    return Container(
      margin: const EdgeInsets.only(bottom: PharmacoTokens.space16),
      padding: const EdgeInsets.all(PharmacoTokens.space16),
      decoration: BoxDecoration(
        color: PharmacoTokens.white,
        borderRadius: PharmacoTokens.borderRadiusCard,
        boxShadow: PharmacoTokens.shadowZ1(),
        border: order['is_emergency'] == true ? Border.all(color: PharmacoTokens.error.withValues(alpha: 0.5), width: 2) : null,
      ),
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
                    Text(pharmacyTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: PharmacoTokens.weightBold)),
                    Text(distanceText, style: theme.textTheme.bodySmall?.copyWith(color: PharmacoTokens.primaryBase, fontWeight: PharmacoTokens.weightSemiBold)),
                  ],
                ),
              ),
              if (order['is_emergency'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: PharmacoTokens.space8, vertical: PharmacoTokens.space4),
                  decoration: BoxDecoration(color: PharmacoTokens.errorLight, borderRadius: PharmacoTokens.borderRadiusSmall),
                  child: Text(lp.translate('urgent'), style: const TextStyle(color: PharmacoTokens.error, fontSize: 10, fontWeight: PharmacoTokens.weightBold)),
                ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: PharmacoTokens.neutral400),
              const SizedBox(width: PharmacoTokens.space8),
              Expanded(child: Text(addressText, style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: PharmacoTokens.space16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lp.translate('estimated_payout'), style: theme.textTheme.labelSmall?.copyWith(color: PharmacoTokens.neutral400)),
                  Text('₹$amount', style: theme.textTheme.titleMedium?.copyWith(fontWeight: PharmacoTokens.weightBold, color: PharmacoTokens.success)),
                ],
              ),
              ElevatedButton(
                onPressed: () async {
                  await orderService.acceptOrder(order['id']);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lp.translate('order_accepted')), backgroundColor: PharmacoTokens.success));
                    final acceptedOrder = Map<String, dynamic>.from(order);
                    acceptedOrder['status'] = 'accepted';
                    Navigator.pushNamed(context, AppRoutes.liveDelivery, arguments: acceptedOrder);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: PharmacoTokens.primaryBase,
                  foregroundColor: PharmacoTokens.white,
                  elevation: PharmacoTokens.elevationZ2,
                  shadowColor: PharmacoTokens.primaryBase.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: PharmacoTokens.borderRadiusFull),
                  minimumSize: const Size(110, 44),
                  padding: const EdgeInsets.symmetric(horizontal: PharmacoTokens.space24, vertical: PharmacoTokens.space12),
                ),
                child: Text(lp.translate('accept')),
              ),
            ],
          ),
        ],
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
    final theme = Theme.of(context);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _orderService.getMyOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: PharmacoTokens.primaryBase));
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

        final allOrders = snapshot.data ?? [];
        if (allOrders.isEmpty) return _buildEmptyState(lp, theme);

        final activeOrders = allOrders.where((o) => ['ready', 'preparing', 'accepted', 'picked_up', 'delivered'].contains(o['status']?.toString().toLowerCase())).toList();
        final pastOrders = allOrders.where((o) => ['completed', 'cancelled'].contains(o['status']?.toString().toLowerCase())).toList();

        return ListView(
          padding: const EdgeInsets.all(PharmacoTokens.space16),
          children: [
            if (activeOrders.isNotEmpty) ...[
              _buildSectionHeader(lp.translate('active_orders'), theme),
              ...activeOrders.map((order) => _OrderListItem(order: order, isActive: true)),
              const SizedBox(height: PharmacoTokens.space24),
            ],
            if (pastOrders.isNotEmpty) ...[
              _buildSectionHeader(lp.translate('past_history'), theme),
              ...pastOrders.map((order) => _OrderListItem(order: order, isActive: false)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PharmacoTokens.space12, left: 4.0),
      child: Text(title.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(fontWeight: PharmacoTokens.weightBold, color: PharmacoTokens.neutral400, letterSpacing: 1.1)),
    );
  }

  Widget _buildEmptyState(LanguageProvider lp, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: PharmacoTokens.neutral300),
          const SizedBox(height: PharmacoTokens.space16),
          Text(lp.translate('no_orders_found'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: PharmacoTokens.weightBold)),
          const SizedBox(height: PharmacoTokens.space8),
          Text(lp.translate('my_orders_empty_desc'), style: theme.textTheme.bodyMedium?.copyWith(color: PharmacoTokens.neutral500)),
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

    return Container(
      margin: const EdgeInsets.only(bottom: PharmacoTokens.space12),
      decoration: BoxDecoration(
        color: PharmacoTokens.white,
        borderRadius: PharmacoTokens.borderRadiusCard,
        boxShadow: PharmacoTokens.shadowZ1(),
      ),
      child: ListTile(
        onTap: () {
          if (isFinalized) { Navigator.pushNamed(context, AppRoutes.orderSummary, arguments: order); }
          else { Navigator.pushNamed(context, AppRoutes.orderDetails, arguments: order); }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: PharmacoTokens.space16, vertical: PharmacoTokens.space8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _getStatusColor(status).withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(isFinalized ? Icons.receipt_long_rounded : Icons.shopping_bag_outlined, color: _getStatusColor(status), size: 20),
        ),
        title: Text('Order #${order['id'].toString().substring(0, 8).toUpperCase()}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: PharmacoTokens.weightBold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(order['customer_address'] ?? 'No address', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(color: PharmacoTokens.neutral500)),
            const SizedBox(height: 4),
            _StatusBadge(status: status),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: PharmacoTokens.neutral400),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return PharmacoTokens.success;
      case 'cancelled': return PharmacoTokens.error;
      case 'picked_up': return PharmacoTokens.warning;
      case 'accepted': return PharmacoTokens.primaryBase;
      default: return PharmacoTokens.neutral500;
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
      final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lp.translate('could_not_open_maps'))));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lp.translate('delivery_loc_not_available'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lp = Provider.of<LanguageProvider>(context);
    final time = order['created_at'] != null ? DateFormat('MMM d, h:mm a').format(DateTime.parse(order['created_at'])) : 'N/A';
    final status = order['status'] as String? ?? 'unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: PharmacoTokens.space16),
      padding: const EdgeInsets.all(PharmacoTokens.space16),
      decoration: BoxDecoration(
        color: PharmacoTokens.white,
        borderRadius: PharmacoTokens.borderRadiusCard,
        boxShadow: PharmacoTokens.shadowZ1(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${lp.translate('order_from')} ${order['customer_name'] ?? 'N/A'}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: PharmacoTokens.weightBold)),
              Text('₹${(order['total_amount'] as num?)?.toDouble() ?? 0.0}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: PharmacoTokens.weightBold, color: PharmacoTokens.primaryBase)),
            ],
          ),
          const SizedBox(height: PharmacoTokens.space8),
          Row(
            children: [
              _StatusBadge(status: status),
              const SizedBox(width: PharmacoTokens.space8),
              GestureDetector(
                onTap: () => _showStatusExplanation(context, lp),
                child: const Icon(Icons.info_outline_rounded, size: 20, color: PharmacoTokens.neutral400),
              ),
              const Spacer(),
              Text(time, style: theme.textTheme.bodySmall?.copyWith(color: PharmacoTokens.neutral400)),
            ],
          ),
          if (status == 'accepted' || status == 'picked_up') ...[
            const SizedBox(height: PharmacoTokens.space16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _launchMapsNavigation(context, lp),
                icon: const Icon(Icons.navigation_outlined),
                label: Text(lp.translate('navigate_to_delivery')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'completed': return PharmacoTokens.success;
      case 'pending': return PharmacoTokens.warning;
      case 'cancelled': return PharmacoTokens.error;
      case 'picked_up': return PharmacoTokens.warning;
      case 'accepted': return PharmacoTokens.primaryBase;
      default: return PharmacoTokens.neutral500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    final lp = Provider.of<LanguageProvider>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: PharmacoTokens.borderRadiusFull,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        lp.translate(status.toLowerCase()).toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: PharmacoTokens.weightBold, letterSpacing: 0.5),
      ),
    );
  }
}

void _showStatusExplanation(BuildContext context, LanguageProvider lp) {
  final theme = Theme.of(context);
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(PharmacoTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lp.translate('order_statuses'), style: theme.textTheme.headlineMedium),
            const SizedBox(height: PharmacoTokens.space16),
            _buildStatusExplanationRow(PharmacoTokens.warning, lp.translate('pending'), lp.translate('pending_status_desc')),
            const Divider(height: 24),
            _buildStatusExplanationRow(PharmacoTokens.success, lp.translate('completed'), lp.translate('completed_status_desc')),
            const Divider(height: 24),
            _buildStatusExplanationRow(PharmacoTokens.error, lp.translate('cancelled'), lp.translate('cancelled_status_desc')),
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
      const SizedBox(width: PharmacoTokens.space16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: PharmacoTokens.weightBold, fontSize: 16)),
            Text(subtitle, style: const TextStyle(color: PharmacoTokens.neutral500)),
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
    final theme = Theme.of(context);
    return RefreshIndicator(
      color: PharmacoTokens.primaryBase,
      onRefresh: onRefresh,
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Icon(Icons.receipt_long_rounded, size: 80, color: PharmacoTokens.neutral300),
          const SizedBox(height: PharmacoTokens.space16),
          Text(
            isActiveTab ? lp.translate('no_active_orders') : lp.translate('no_past_orders'),
            textAlign: TextAlign.center, style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: PharmacoTokens.space8),
          Text(
            isActiveTab ? lp.translate('go_online_to_receive') : lp.translate('past_orders_appear_here'),
            textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: PharmacoTokens.neutral500),
          ),
        ],
      ),
    );
  }
}
