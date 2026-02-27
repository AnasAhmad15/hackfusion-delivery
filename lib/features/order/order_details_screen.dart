import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:pharmaco_delivery_partner/core/services/order_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _isPickedUp = false;
  final OrderService _orderService = OrderService();
  final SupabaseClient _client = Supabase.instance.client;
  Map<String, dynamic>? _pharmacy;

  Future<void> _loadPharmacy(String? pharmacyId) async {
    if (pharmacyId == null) return;
    debugPrint('OrderDetails: Starting _loadPharmacy for $pharmacyId');
    try {
      final data = await _client
          .from('medical_partners')
          .select('id, medical_name, address, lat, lng')
          .eq('id', pharmacyId)
          .maybeSingle();
      
      debugPrint('OrderDetails: Pharmacy data result: $data');
      
      if (!mounted) return;
      if (data != null) {
        setState(() => _pharmacy = data);
      } else {
        debugPrint('OrderDetails: No pharmacy found in medical_partners for ID: $pharmacyId');
      }
    } catch (e) {
      debugPrint('OrderDetails: Error in _loadPharmacy: $e');
    }
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      final order = arguments;
      final status = (order['status'] as String? ?? 'pending').toLowerCase();
      setState(() {
        _isPickedUp = ['picked_up', 'delivered'].contains(status);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments == null || arguments is! Map<String, dynamic>) {
      return const Scaffold(body: Center(child: Text('Invalid order data.')));
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _orderService.getOrderStream(arguments['id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final order = snapshot.data ?? arguments;
        final status = (order['status'] as String? ?? 'pending').toLowerCase();
        final pharmacyId = order['pharmacy_id']?.toString();

    if (_pharmacy == null && pharmacyId != null) {
      debugPrint('OrderDetails: Initial fetch for pharmacyId: $pharmacyId');
      _loadPharmacy(pharmacyId);
    }

        // Auto-redirect if finalized
        if (['completed', 'cancelled'].contains(status)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.orderSummary,
              arguments: order,
            );
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              'Order #${order['id'].toString().substring(0, 8).toUpperCase()}',
            ),
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          body: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              _buildTimeline(status),
              const SizedBox(height: 24),
            _buildLocationCard(
                context,
                order: order,
                title: 'Pickup From',
                address:
                    _pharmacy?['medical_name'] != null 
                    ? "${_pharmacy!['medical_name']}\n${_pharmacy!['address'] ?? ''}"
                    : (order['pharmacy_name'] ?? order['medical_name'] ?? 'Pharmacy location'),
                isPickup: true,
                currentStatus: status,
              ),
              const SizedBox(height: 16),
              _buildLocationCard(
                context,
                order: order,
                title: 'Deliver To',
                address: order['customer_address'] ?? 'Customer location',
                isPickup: false,
                currentStatus: status,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeline(String status) {
    final stages = ['accepted', 'picked_up', 'delivered'];
    final currentIndex = stages.indexOf(status);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(stages.length, (index) {
              final isCompleted = index <= currentIndex;
              final isLast = index == stages.length - 1;
              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? Colors.blue : Colors.grey.shade300,
                        border: Border.all(
                          color: isCompleted
                              ? Colors.blue
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index < currentIndex
                              ? Colors.blue
                              : Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _timelineLabel('Accepted', status == 'accepted'),
              _timelineLabel('Picked Up', status == 'picked_up'),
              _timelineLabel('Arrived', status == 'delivered'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timelineLabel(String label, bool isActive) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        color: isActive ? Colors.blue : Colors.grey,
      ),
    );
  }

  Widget _buildLocationCard(
    BuildContext context, {
    required Map<String, dynamic> order,
    required String title,
    required String address,
    required bool isPickup,
    required String currentStatus,
  }) {
    final theme = Theme.of(context);
    final bool canNavigate =
        ['accepted', 'ready', 'preparing', 'picked_up', 'delivered'].contains(currentStatus);
    final bool canAction =
        (isPickup && ['accepted', 'ready', 'preparing'].contains(currentStatus)) ||
        (!isPickup && currentStatus == 'picked_up');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPickup ? Icons.storefront : Icons.location_on_outlined,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              address,
              style: TextStyle(color: Colors.grey.shade800, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (canNavigate)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.liveDelivery,
                        arguments: order,
                      ),
                      icon: const Icon(Icons.navigation_outlined, size: 18),
                      label: const Text('NAVIGATE'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                if (canNavigate && canAction) const SizedBox(width: 12),
                if (canAction)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _handleMainAction(context, order, isPickup),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPickup
                            ? theme.primaryColor
                            : Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isPickup ? 'CONFIRM PICKUP' : 'CONFIRM DELIVERY',
                      ),
                    ),
                  ),
                if (!isPickup && currentStatus == 'delivered')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.liveDelivery,
                        arguments: order,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('ARRIVED'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleMainAction(
    BuildContext context,
    Map<String, dynamic> order,
    bool isPickup,
  ) async {
    if (isPickup) {
      final result = await Navigator.pushNamed(
        context,
        AppRoutes.pickupConfirmation,
        arguments: order,
      );
      if (result == true) {
        await _orderService.updateOrderStatus(order['id'], 'picked_up');
        if (!context.mounted) return;
        final nextOrder = Map<String, dynamic>.from(order);
        nextOrder['status'] = 'picked_up';
        if (_pharmacy != null) {
          nextOrder['pharmacy_address'] = _pharmacy?['address'];
          nextOrder['pharmacy_lat'] = _pharmacy?['lat'];
          nextOrder['pharmacy_lng'] = _pharmacy?['lng'];
        }
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.liveDelivery,
          arguments: nextOrder,
        );
      }
    } else {
      // Handle Delivery Confirmation
      Navigator.pushNamed(
        context,
        AppRoutes.confirmDelivery,
        arguments: order,
      );
    }
  }
}
