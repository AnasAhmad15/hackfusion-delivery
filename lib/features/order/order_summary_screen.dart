import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderSummaryScreen extends StatelessWidget {
  const OrderSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments == null || arguments is! Map<String, dynamic>) {
      return const Scaffold(body: Center(child: Text('Invalid order data.')));
    }
    final order = arguments;
    final status = (order['status'] as String? ?? 'completed').toLowerCase();
    final bool isCancelled = status == 'cancelled';
    final String formattedDate = order['completed_at'] != null 
        ? DateFormat('MMM d, yyyy • h:mm a').format(DateTime.parse(order['completed_at']))
        : order['created_at'] != null 
            ? DateFormat('MMM d, yyyy • h:mm a').format(DateTime.parse(order['created_at']))
            : 'N/A';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Order Summary', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildStatusHeader(status, isCancelled),
          const SizedBox(height: 24),
          _buildOrderInfoCard(order, formattedDate),
          const SizedBox(height: 24),
          _buildLocationSection(order),
          const SizedBox(height: 24),
          _buildPaymentBreakdown(order),
          const SizedBox(height: 32),
          const Center(
            child: Text(
              'Thank you for your service!',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(String status, bool isCancelled) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: (isCancelled ? Colors.red : Colors.green).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            isCancelled ? Icons.cancel_outlined : Icons.check_circle_outline,
            size: 64,
            color: isCancelled ? Colors.red : Colors.green,
          ),
          const SizedBox(height: 12),
          Text(
            isCancelled ? 'Order Cancelled' : 'Order Completed',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isCancelled ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard(Map<String, dynamic> order, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ORDER DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
        const SizedBox(height: 12),
        _detailRow('Order ID', '#${order['id'].toString().substring(0, 8).toUpperCase()}'),
        _detailRow('Completed On', date),
        _detailRow('Customer', order['customer_name'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildLocationSection(Map<String, dynamic> order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DELIVERY ROUTE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
        const SizedBox(height: 16),
        _locationItem(Icons.storefront, 'Pickup', order['pharmacy_address'] ?? 'N/A', Colors.blue),
        Padding(
          padding: const EdgeInsets.only(left: 11),
          child: Container(width: 2, height: 20, color: Colors.grey.shade200),
        ),
        _locationItem(Icons.location_on_outlined, 'Drop-off', order['customer_address'] ?? 'N/A', Colors.orange),
      ],
    );
  }

  Widget _locationItem(IconData icon, String label, String address, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(address, style: const TextStyle(fontSize: 14, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentBreakdown(Map<String, dynamic> order) {
    final double total = (order['payout'] as num?)?.toDouble() ?? 0.0;
    final double commission = (order['commission_amount'] as num?)?.toDouble() ?? 40.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('EARNINGS BREAKDOWN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
          const SizedBox(height: 16),
          _priceRow('Order Amount', total),
          _priceRow('Base Pay', commission),
          _priceRow('Peak Bonus', 0.0, isBonus: true),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Earned', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('₹${commission.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool isBonus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBonus ? FontWeight.bold : FontWeight.w500,
              color: isBonus ? Colors.blue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
