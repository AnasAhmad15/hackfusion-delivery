import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/core/services/earnings_service.dart';
import 'package:pharmaco_delivery_partner/core/services/order_service.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:intl/intl.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin<EarningsScreen> {
  final EarningsService _earningsService = EarningsService();
  final OrderService _orderService = OrderService();

  @override
  bool get wantKeepAlive => true;

  Future<void> _refreshData() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Earnings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            _buildBalanceOverview(theme),
            const SizedBox(height: 24),
            _buildStatsBreakdown(theme),
            const SizedBox(height: 24),
            _buildWithdrawalActions(theme),
            const SizedBox(height: 32),
            _buildTransactionHistoryHeader(theme),
            _buildTransactionHistoryList(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceOverview(ThemeData theme) {
    return FutureBuilder<double>(
      future: _earningsService.getWalletBalance(),
      builder: (context, snapshot) {
        final balance = snapshot.data ?? 0.0;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Available Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${balance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Next settlement in 14h',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsBreakdown(ThemeData theme) {
    return Row(
      children: [
        _buildMiniStat(
          theme,
          'Today',
          _earningsService.getTodaysEarningsStream(),
          Colors.blue,
        ),
        const SizedBox(width: 16),
        _buildMiniStat(
          theme,
          'Lifetime',
          Future.value(12450.0),
          Colors.green,
        ), // Mock lifetime
      ],
    );
  }

  Widget _buildMiniStat(
    ThemeData theme,
    String label,
    dynamic data,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            if (data is Stream<double>)
              StreamBuilder<double>(
                stream: data,
                builder: (context, snapshot) => Text(
                  '₹${(snapshot.data ?? 0.0).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              FutureBuilder<double>(
                future: data as Future<double>,
                builder: (context, snapshot) => Text(
                  '₹${(snapshot.data ?? 0.0).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawalActions(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
            label: const Text('UPI TRANSFER'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue.shade700,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.account_balance_outlined, size: 18),
            label: const Text('BANK Payout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade50,
              foregroundColor: Colors.green.shade700,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionHistoryHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Recent Transactions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(onPressed: () {}, child: const Text('Filters')),
        ],
      ),
    );
  }

  Widget _buildTransactionHistoryList(ThemeData theme) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _earningsService.getTransactionHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final transactions = snapshot.data ?? [];
        if (transactions.isEmpty) {
          return _buildEmptyHistory();
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final tx = transactions[index];
            final isEarning = tx['type'] == 'earning';
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: ListTile(
                onTap: isEarning
                    ? () async {
                        final order = await _orderService.getOrderDetails(
                          tx['reference_id'],
                        );
                        if (mounted)
                          Navigator.pushNamed(
                            context,
                            AppRoutes.orderSummary,
                            arguments: order,
                          );
                      }
                    : null,
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isEarning ? Colors.green : Colors.blue).withOpacity(
                      0.1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEarning
                        ? Icons.add_chart
                        : Icons.account_balance_wallet_outlined,
                    color: isEarning ? Colors.green : Colors.blue,
                    size: 20,
                  ),
                ),
                title: Text(
                  isEarning ? 'Order Payout' : 'Transfer',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  DateFormat(
                    'MMM d, h:mm a',
                  ).format(DateTime.parse(tx['created_at'])),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  '${isEarning ? '+' : '-'} ₹${(tx['amount'] as num).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isEarning ? Colors.green : Colors.red,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'No transactions yet',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double height;
  final double width;

  const _Skeleton({
    this.height = double.infinity,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
    );
  }
}
