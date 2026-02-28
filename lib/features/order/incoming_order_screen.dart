import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:pharmaco_delivery_partner/core/services/order_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

class IncomingOrderScreen extends StatefulWidget {
  const IncomingOrderScreen({super.key});

  @override
  State<IncomingOrderScreen> createState() => _IncomingOrderScreenState();
}

class _IncomingOrderScreenState extends State<IncomingOrderScreen> {
  Timer? _timer;
  int _countdown = 900;
  final OrderService _orderService = OrderService();
  final SupabaseClient _client = Supabase.instance.client;
  Map<String, dynamic>? _pharmacy;

  @override
  void initState() { super.initState(); _startTimer(); }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        _timer?.cancel();
        if (mounted) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          if (arguments != null && arguments is Map<String, dynamic>) {
            _orderService.rejectOrder(arguments['id']);
          }
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [PharmacoTokens.primaryBase, PharmacoTokens.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(PharmacoTokens.space24),
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
                    if (_pharmacy == null && pharmacyId != null) _loadPharmacy(pharmacyId);
                    return _buildOrderDetails(context, liveOrder);
                  },
                ),
                _buildActionButtons(context, order),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadPharmacy(String pharmacyId) async {
    try {
      final data = await _client.from('medical_partners').select('id, medical_name, address').eq('id', pharmacyId).maybeSingle();
      if (!mounted) return;
      setState(() => _pharmacy = data);
    } catch (_) {}
  }

  Widget _buildOrderDetails(BuildContext context, Map<String, dynamic> order) {
    final theme = Theme.of(context);
    final String pharmacyName = (_pharmacy?['medical_name'] as String?) ?? 'Medical Partner';
    final String pharmacyAddress = (_pharmacy?['address'] as String?) ?? 'Pharmacy location';
    final double amount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;

    return Column(
      children: [
        Text('NEW ORDER REQUEST', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70, fontWeight: PharmacoTokens.weightBold, letterSpacing: 1.5)),
        const SizedBox(height: PharmacoTokens.space48),
        Text(_formattedCountdown, style: const TextStyle(fontSize: 64, fontWeight: PharmacoTokens.weightBold, color: Colors.white)),
        const SizedBox(height: PharmacoTokens.space48),
        _buildInfoCard(context, icon: Icons.store_rounded, title: pharmacyName, subtitle: pharmacyAddress),
        const SizedBox(height: PharmacoTokens.space16),
        _buildInfoCard(context, icon: Icons.currency_rupee_rounded, title: '₹$amount', subtitle: 'Order Amount'),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(PharmacoTokens.space16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: PharmacoTokens.borderRadiusMedium,
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: PharmacoTokens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: PharmacoTokens.weightBold)),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isAccepting = false;

  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> order) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isAccepting ? null : () async {
              setState(() => _isAccepting = true);
              _timer?.cancel();
              try {
                await _orderService.acceptOrder(order['id']);
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, AppRoutes.liveDelivery, arguments: order);
              } catch (e) {
                if (!mounted) return;
                setState(() => _isAccepting = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to accept: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmacoTokens.success,
              foregroundColor: PharmacoTokens.white,
              padding: const EdgeInsets.symmetric(vertical: PharmacoTokens.space24),
              textStyle: const TextStyle(fontSize: 18, fontWeight: PharmacoTokens.weightBold),
            ),
            child: _isAccepting
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('ACCEPT'),
          ),
        ),
        const SizedBox(width: PharmacoTokens.space16),
        Expanded(
          child: ElevatedButton(
            onPressed: () { _timer?.cancel(); _orderService.rejectOrder(order['id']); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmacoTokens.error,
              foregroundColor: PharmacoTokens.white,
              padding: const EdgeInsets.symmetric(vertical: PharmacoTokens.space24),
              textStyle: const TextStyle(fontSize: 18, fontWeight: PharmacoTokens.weightBold),
            ),
            child: const Text('REJECT'),
          ),
        ),
      ],
    );
  }
}
