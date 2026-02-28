import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pharmaco_delivery_partner/core/services/earnings_service.dart';
import 'package:pharmaco_delivery_partner/core/services/order_service.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:intl/intl.dart';
import 'package:pharmaco_delivery_partner/core/providers/language_provider.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<EarningsScreen> {
  final EarningsService _earningsService = EarningsService();
  final OrderService _orderService = OrderService();

  @override
  bool get wantKeepAlive => true;

  Future<void> _refreshData() async { setState(() {}); }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final lp = Provider.of<LanguageProvider>(context);
    return Scaffold(
      backgroundColor: PharmacoTokens.neutral50,
      body: RefreshIndicator(
        color: PharmacoTokens.primaryBase,
        onRefresh: _refreshData,
        child: ListView(
          padding: const EdgeInsets.all(PharmacoTokens.space20),
          children: [
            _buildBalanceOverview(theme, lp),
            const SizedBox(height: PharmacoTokens.space24),
            _buildStatsBreakdown(theme, lp),
            const SizedBox(height: PharmacoTokens.space24),
            _buildWithdrawalActions(theme, lp),
            const SizedBox(height: PharmacoTokens.space32),
            _buildTransactionHistoryHeader(theme, lp),
            _buildTransactionHistoryList(theme, lp),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceOverview(ThemeData theme, LanguageProvider lp) {
    return StreamBuilder<double>(
      stream: _earningsService.getWalletBalanceStream(),
      builder: (context, snapshot) {
        final balance = snapshot.data ?? 0.0;
        return Container(
          padding: const EdgeInsets.all(PharmacoTokens.space24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [PharmacoTokens.primaryBase, PharmacoTokens.primaryDark, const Color(0xFF1E3A8A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: PharmacoTokens.borderRadiusCard,
            boxShadow: [
              BoxShadow(color: PharmacoTokens.primaryBase.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              Text(lp.translate('available_balance'), style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: PharmacoTokens.weightMedium)),
              const SizedBox(height: PharmacoTokens.space8),
              Text('₹${balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: PharmacoTokens.weightBold)),
              const SizedBox(height: PharmacoTokens.space16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: PharmacoTokens.space12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: PharmacoTokens.borderRadiusFull),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text('${lp.translate('next_settlement')} 14h', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: PharmacoTokens.weightMedium)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsBreakdown(ThemeData theme, LanguageProvider lp) {
    return Row(
      children: [
        _buildMiniStat(theme, lp.translate('today'), _earningsService.getTodaysEarningsStream(), PharmacoTokens.primaryBase),
        const SizedBox(width: PharmacoTokens.space16),
        _buildMiniStat(theme, lp.translate('lifetime'), Future.value(12450.0), PharmacoTokens.success),
      ],
    );
  }

  Widget _buildMiniStat(ThemeData theme, String label, dynamic data, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(PharmacoTokens.space16),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            border: Border.all(color: color.withValues(alpha: 0.1)),
            borderRadius: PharmacoTokens.borderRadiusCard,
            boxShadow: PharmacoTokens.shadowZ1(),
          ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: PharmacoTokens.neutral400, fontWeight: PharmacoTokens.weightMedium)),
            const SizedBox(height: PharmacoTokens.space8),
            if (data is Stream<double>)
              StreamBuilder<double>(stream: data, builder: (context, snapshot) => Text('₹${(snapshot.data ?? 0.0).toStringAsFixed(0)}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: PharmacoTokens.weightBold)))
            else
              FutureBuilder<double>(future: data as Future<double>, builder: (context, snapshot) => Text('₹${(snapshot.data ?? 0.0).toStringAsFixed(0)}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: PharmacoTokens.weightBold))),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawalActions(ThemeData theme, LanguageProvider lp) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
            label: Text(lp.translate('upi_transfer')),
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmacoTokens.primarySurface,
              foregroundColor: PharmacoTokens.primaryDark,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: PharmacoTokens.borderRadiusMedium),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: PharmacoTokens.space12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.account_balance_outlined, size: 18),
            label: Text(lp.translate('bank_payout')),
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmacoTokens.successLight,
              foregroundColor: PharmacoTokens.success,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: PharmacoTokens.borderRadiusMedium),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionHistoryHeader(ThemeData theme, LanguageProvider lp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PharmacoTokens.space16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(lp.translate('recent_transactions'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: PharmacoTokens.weightBold)),
          TextButton(onPressed: () {}, child: Text(lp.translate('filters'))),
        ],
      ),
    );
  }

  Widget _buildTransactionHistoryList(ThemeData theme, LanguageProvider lp) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _earningsService.getTransactionHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: PharmacoTokens.primaryBase));
        final transactions = snapshot.data ?? [];
        if (transactions.isEmpty) return _buildEmptyHistory(lp, theme);
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const SizedBox(height: PharmacoTokens.space12),
          itemBuilder: (context, index) {
            final tx = transactions[index];
            final isEarning = tx['type'] == 'earning';
            return Container(
              padding: const EdgeInsets.all(PharmacoTokens.space12),
              decoration: BoxDecoration(
                color: PharmacoTokens.white,
                borderRadius: PharmacoTokens.borderRadiusMedium,
                boxShadow: PharmacoTokens.shadowZ1(),
              ),
              child: ListTile(
                onTap: isEarning
                    ? () async {
                        final order = await _orderService.getOrderDetails(tx['reference_id']);
                        if (mounted) Navigator.pushNamed(context, AppRoutes.orderSummary, arguments: order);
                      }
                    : null,
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isEarning ? PharmacoTokens.success : PharmacoTokens.primaryBase).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEarning ? Icons.add_chart_rounded : Icons.account_balance_wallet_outlined,
                    color: isEarning ? PharmacoTokens.success : PharmacoTokens.primaryBase, size: 20,
                  ),
                ),
                title: Text(isEarning ? lp.translate('order_payout') : lp.translate('transfer'), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: PharmacoTokens.weightBold)),
                subtitle: Text(DateFormat('MMM d, h:mm a').format(DateTime.parse(tx['created_at'])), style: theme.textTheme.labelSmall?.copyWith(color: PharmacoTokens.neutral400)),
                trailing: Text(
                  '${isEarning ? '+' : '-'} ₹${((tx['amount'] ?? tx['total_amount'] ?? 0) as num).toStringAsFixed(0)}',
                  style: TextStyle(fontWeight: PharmacoTokens.weightBold, fontSize: 16, color: isEarning ? PharmacoTokens.success : PharmacoTokens.error),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyHistory(LanguageProvider lp, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PharmacoTokens.space40),
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 48, color: PharmacoTokens.neutral300),
            const SizedBox(height: PharmacoTokens.space12),
            Text(lp.translate('no_transactions'), style: theme.textTheme.bodyMedium?.copyWith(color: PharmacoTokens.neutral400)),
          ],
        ),
      ),
    );
  }
}
