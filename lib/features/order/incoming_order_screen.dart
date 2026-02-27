import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:pharmaco_delivery_partner/core/services/order_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IncomingOrderScreen extends StatefulWidget {
  const IncomingOrderScreen({super.key});

  @override
  State<IncomingOrderScreen> createState() => _IncomingOrderScreenState();
}

class _IncomingOrderScreenState extends State<IncomingOrderScreen> {
  Timer? _timer;
  int _countdown = 900; // 15 minutes in seconds
  final OrderService _orderService = OrderService();
  final SupabaseClient _client = Supabase.instance.client;

  Map<String, dynamic>? _pharmacy;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
        if (mounted) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          if (arguments != null && arguments is Map<String, dynamic>) {
            final order = arguments;
            _orderService.rejectOrder(order['id']);
          }
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedCountdown {
    final minutes = (_countdown ~/ 60).toString().padLeft(2, '0');
    final seconds = (_countdown % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args == null || args is! Map<String, dynamic>) {
      return const Scaffold(body: Center(child: Text('Invalid order data.')));
    }
    final order = args;

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox.shrink(),
              StreamBuilder<Map<String, dynamic>?>(
                stream: _orderService.getOrderStream(order['id']),
                builder: (context, snapshot) {
                  final liveOrder = snapshot.data ?? order;
                  final pharmacyId = liveOrder['pharmacy_id']?.toString();
                  if (_pharmacy == null && pharmacyId != null) {
                    _loadPharmacy(pharmacyId);
                  }
                  return _buildOrderDetails(context, liveOrder);
                },
              ),
              _buildActionButtons(context, order),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadPharmacy(String pharmacyId) async {
    try {
      final data = await _client
          .from('medical_partners')
          .select('id, medical_name, address')
          .eq('id', pharmacyId)
          .maybeSingle();
      if (!mounted) return;
      setState(() => _pharmacy = data);
    } catch (_) {
      // ignore
    }
  }

  Widget _buildOrderDetails(BuildContext context, Map<String, dynamic> order) {
    final String pharmacyName =
        (_pharmacy?['medical_name'] as String?) ?? 'Medical Partner';
    final String pharmacyAddress =
        (_pharmacy?['address'] as String?) ?? 'Pickup Location';
    final double amount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;

    return Column(
      children: [
        Text(
          'NEW ORDER REQUEST',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 48),
        Text(
          _formattedCountdown,
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 48),
        _buildInfoCard(
          context,
          icon: Icons.store,
          title: pharmacyName,
          subtitle: pharmacyAddress,
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          context,
          icon: Icons.attach_money,
          title: '₹$amount',
          subtitle: 'Order Amount',
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.2),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> order) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              _timer?.cancel();
              _orderService.acceptOrder(order['id']);
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.orderDetails,
                arguments: order,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 24),
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('ACCEPT'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              _timer?.cancel();
              _orderService.rejectOrder(order['id']);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 24),
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('REJECT'),
          ),
        ),
      ],
    );
  }
}
