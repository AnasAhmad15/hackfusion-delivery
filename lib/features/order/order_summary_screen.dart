import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

class OrderSummaryScreen extends StatelessWidget {
  const OrderSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments == null || arguments is! Map<String, dynamic>) {
      return const Scaffold(body: Center(child: Text('Invalid order data.')));
    }
    final order = arguments;
    final theme = Theme.of(context);
    final status = (order['status'] as String? ?? 'completed').toLowerCase();
    final bool isCancelled = status == 'cancelled';
    final String formattedDate = order['completed_at'] != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(DateTime.parse(order['completed_at']))
        : order['created_at'] != null
            ? DateFormat('MMM d, yyyy • h:mm a').format(DateTime.parse(order['created_at']))
            : 'N/A';

    return Scaffold(
      backgroundColor: PharmacoTokens.neutral50,
      appBar: AppBar(
        title: const Text('Order Summary'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(PharmacoTokens.space20),
        children: [
          _buildStatusHeader(status, isCancelled, theme),
          const SizedBox(height: PharmacoTokens.space24),
          _buildOrderInfoCard(order, formattedDate, theme),
          const SizedBox(height: PharmacoTokens.space24),
          _buildLocationSection(order, theme),
          const SizedBox(height: PharmacoTokens.space24),
          _buildPaymentBreakdown(order, theme),
          const SizedBox(height: PharmacoTokens.space32),
          Center(child: Text('Thank you for your service!', style: theme.textTheme.bodyMedium?.copyWith(color: PharmacoTokens.neutral400, fontStyle: FontStyle.italic))),
          const SizedBox(height: PharmacoTokens.space20),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(String status, bool isCancelled, ThemeData theme) {
    final color = isCancelled ? PharmacoTokens.error : PharmacoTokens.success;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: PharmacoTokens.space24),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: PharmacoTokens.borderRadiusCard),
      child: Column(
        children: [
          Icon(isCancelled ? Icons.cancel_outlined : Icons.check_circle_outline_rounded, size: 64, color: color),
          const SizedBox(height: PharmacoTokens.space12),
          Text(isCancelled ? 'Order Cancelled' : 'Order Completed', style: theme.textTheme.titleLarge?.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard(Map<String, dynamic> order, String date, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(PharmacoTokens.space20),
      decoration: BoxDecoration(color: PharmacoTokens.white, borderRadius: PharmacoTokens.borderRadiusCard, boxShadow: PharmacoTokens.shadowZ1()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ORDER DETAILS', style: theme.textTheme.labelSmall?.copyWith(fontWeight: PharmacoTokens.weightBold, color: PharmacoTokens.neutral400, letterSpacing: 1.1)),
          const SizedBox(height: PharmacoTokens.space12),
          _detailRow('Order ID', '#${order['id'].toString().substring(0, 8).toUpperCase()}', theme),
          _detailRow('Completed On', date, theme),
          _detailRow('Customer', order['customer_name'] ?? 'N/A', theme),
        ],
      ),
    );
  }

  Widget _buildLocationSection(Map<String, dynamic> order, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(PharmacoTokens.space20),
      decoration: BoxDecoration(color: PharmacoTokens.white, borderRadius: PharmacoTokens.borderRadiusCard, boxShadow: PharmacoTokens.shadowZ1()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DELIVERY ROUTE', style: theme.textTheme.labelSmall?.copyWith(fontWeight: PharmacoTokens.weightBold, color: PharmacoTokens.neutral400, letterSpacing: 1.1)),
          const SizedBox(height: PharmacoTokens.space16),
          _locationItem(Icons.storefront_rounded, 'Pickup', order['pharmacy_address'] ?? 'N/A', PharmacoTokens.primaryBase, theme),
          Padding(padding: const EdgeInsets.only(left: 11), child: Container(width: 2, height: 20, color: PharmacoTokens.neutral200)),
          _locationItem(Icons.location_on_outlined, 'Drop-off', order['customer_address'] ?? 'N/A', PharmacoTokens.warning, theme),
        ],
      ),
    );
  }

  Widget _locationItem(IconData icon, String label, String address, Color color, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(width: PharmacoTokens.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelSmall?.copyWith(color: PharmacoTokens.neutral400, fontWeight: PharmacoTokens.weightMedium)),
              const SizedBox(height: 2),
              Text(address, style: theme.textTheme.bodyMedium?.copyWith(height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentBreakdown(Map<String, dynamic> order, ThemeData theme) {
    final double total = (order['payout'] as num?)?.toDouble() ?? 0.0;
    final double commission = (order['commission_amount'] as num?)?.toDouble() ?? 40.0;

    return Container(
      padding: const EdgeInsets.all(PharmacoTokens.space20),
      decoration: BoxDecoration(color: PharmacoTokens.white, borderRadius: PharmacoTokens.borderRadiusCard, boxShadow: PharmacoTokens.shadowZ1()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EARNINGS BREAKDOWN', style: theme.textTheme.labelSmall?.copyWith(fontWeight: PharmacoTokens.weightBold, color: PharmacoTokens.neutral400, letterSpacing: 1.1)),
          const SizedBox(height: PharmacoTokens.space16),
          _priceRow('Order Amount', total, theme),
          _priceRow('Base Pay', commission, theme),
          _priceRow('Peak Bonus', 0.0, theme, isBonus: true),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Earned', style: theme.textTheme.titleSmall?.copyWith(fontWeight: PharmacoTokens.weightBold)),
              Text('₹${commission.toStringAsFixed(2)}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: PharmacoTokens.weightBold, color: PharmacoTokens.success)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: PharmacoTokens.neutral400)),
          Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: PharmacoTokens.weightMedium)),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount, ThemeData theme, {bool isBonus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: PharmacoTokens.neutral600)),
          Text('₹${amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: isBonus ? PharmacoTokens.weightBold : PharmacoTokens.weightMedium, color: isBonus ? PharmacoTokens.primaryBase : PharmacoTokens.neutral900)),
        ],
      ),
    );
  }
}
