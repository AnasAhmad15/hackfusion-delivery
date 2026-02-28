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

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.95 + (0.05 * value),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: List.generate(stages.length, (index) {
                final isCompleted = index <= currentIndex;
                final isCurrent = index == currentIndex;
                final isLast = index == stages.length - 1;
                
                return Expanded(
                  child: Row(
                    children: [
                      // Stage Circle
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted ? Colors.blue : Colors.white,
                          border: Border.all(
                            color: isCompleted ? Colors.blue : Colors.grey.shade300,
                            width: 2,
                          ),
                          boxShadow: isCurrent ? [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ] : null,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, size: 18, color: Colors.white)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade400,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      // Connector Line
                      if (!isLast)
                        Expanded(
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: index < currentIndex
                                  ? Colors.blue
                                  : Colors.grey.shade200,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _timelineLabel('Accepted', status == 'accepted'),
                _timelineLabel('Picked Up', status == 'picked_up'),
                _timelineLabel('Delivered', status == 'delivered'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timelineLabel(String label, bool isActive) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      style: TextStyle(
        fontSize: 12,
        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
        color: isActive ? Colors.blue : Colors.grey.shade400,
        letterSpacing: 0.5,
      ),
      child: Text(label),
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
        ['accepted', 'ready', 'preparing', 'picked_up'].contains(currentStatus);
    final bool canAction =
        (isPickup && ['accepted', 'ready', 'preparing'].contains(currentStatus)) ||
        (!isPickup && currentStatus == 'picked_up');
    
    // Specifically check if we should show the navigate button for THIS card
    final bool showNavigateForThisCard = canNavigate && (
      (isPickup && ['accepted', 'ready', 'preparing'].contains(currentStatus)) ||
      (!isPickup && currentStatus == 'picked_up')
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: isPickup ? Colors.blue.shade50.withOpacity(0.5) : Colors.orange.shade50.withOpacity(0.5),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isPickup ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isPickup ? Icons.storefront_rounded : Icons.person_pin_circle_rounded,
                      color: isPickup ? Colors.blue : Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isPickup ? Colors.blue.shade900 : Colors.orange.shade900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  if (!isPickup && order['customer_name'] != null)
                    Text(
                      order['customer_name'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_rounded, color: Colors.grey.shade400, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  if (!isPickup && order['customer_phone'] != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.phone_android_rounded, color: Colors.grey.shade400, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          order['customer_phone'],
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      if (showNavigateForThisCard)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.liveDelivery,
                              arguments: order,
                            ),
                            icon: const Icon(Icons.directions_rounded, size: 18),
                            label: const Text('NAVIGATE'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue,
                              elevation: 0,
                              side: BorderSide(color: Colors.blue.shade100, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      if (showNavigateForThisCard && canAction) const SizedBox(width: 12),
                      if (canAction)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: (isPickup ? Colors.blue : Colors.orange).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () => _handleMainAction(context, order, isPickup),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isPickup ? Colors.blue : Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                isPickup ? 'CONFIRM PICKUP' : 'CONFIRM DELIVERY',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (!isPickup && currentStatus == 'delivered')
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'DELIVERED',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
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
        // Instead of redirecting to liveDelivery, just stay on OrderDetails
        // The StreamBuilder will pick up the 'picked_up' status and update the UI
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
