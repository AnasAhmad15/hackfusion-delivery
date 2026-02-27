import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> getIncomingOrders() {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((orders) {
          debugPrint('OrderService.getIncomingOrders: rows=${orders.length}');
          if (orders.isNotEmpty) {
            final first = orders.first;
            debugPrint(
              'OrderService.getIncomingOrders: sample status=${first['status']} delivery_partner_id=${first['delivery_partner_id']}',
            );
          }

          final available = orders.where((order) {
            final status = (order['status'] as String? ?? '').toLowerCase();
            final unassigned = order['delivery_partner_id'] == null;
            return status == 'accepted' && unassigned;
          }).toList();
          return List<Map<String, dynamic>>.from(available);
        });
  }

  Stream<int> getAvailableOrdersCountStream() {
    return getIncomingOrders().map((orders) => orders.length);
  }

  Future<void> acceptOrder(String orderId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    try {
      // Keep status='accepted' (DB constraint does not allow 'assigned').
      // Assign the driver id into both columns for compatibility.
      await _client
          .from('orders')
          .update({
            'delivery_partner_id': userId,
            'delivery_partner_assigned_id': userId,
          })
          .eq('id', orderId);
    } catch (e) {
      debugPrint('OrderService.acceptOrder failed: $e');
      rethrow;
    }
  }

  Future<void> rejectOrder(String orderId) async {
    // In a real app, you might hide this order from the user instead of changing status
    print('Order $orderId rejected by user.');
  }

  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    final response = await _client
        .from('orders')
        .select()
        .eq('id', orderId)
        .single();
    return response;
  }

  Stream<Map<String, dynamic>?> getOrderStream(String orderId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map(
          (orders) => orders.isNotEmpty
              ? Map<String, dynamic>.from(orders.first)
              : null,
        );
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _client.from('orders').update({'status': status}).eq('id', orderId);
  }

  Future<Map<String, dynamic>> completeOrder({
    required String orderId,
    required String proofType,
    String? proofUrl,
    double? lat,
    double? lng,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    try {
      final response = await _client.rpc(
        'complete_order',
        params: {
          'p_order_id': orderId,
          'p_partner_id': userId,
          'p_proof_type': proofType,
          'p_proof_url': proofUrl,
          'p_lat': lat,
          'p_lng': lng,
        },
      );

      return Map<String, dynamic>.from(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> updateLastActivity() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('orders')
        .update({'last_activity_at': DateTime.now().toIso8601String()})
        .or(
          'delivery_partner_id.eq.$userId,delivery_partner_assigned_id.eq.$userId',
        )
        .eq('status', 'accepted');
  }

  Future<int> getCompletedDeliveriesCount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return 0;
    }

    final count = await _client
        .from('orders')
        .count()
        .eq('delivery_partner_id', userId)
        .eq('status', 'completed');

    return count;
  }

  Stream<Map<String, dynamic>?> getActiveOrderStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value(null);

    final activeStatuses = ['accepted', 'picked_up', 'delivered'];
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('delivery_partner_id', userId)
        .order('created_at', ascending: false)
        .map((orders) {
          final activeOrders = orders
              .where(
                (order) => activeStatuses.contains(
                  order['status']?.toString().toLowerCase(),
                ),
              )
              .toList();
          return activeOrders.isNotEmpty
              ? Map<String, dynamic>.from(activeOrders.first)
              : null;
        });
  }

  Stream<List<Map<String, dynamic>>> getMyOrders() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('delivery_partner_id', userId)
        .order('created_at', ascending: false)
        .map((orders) => List<Map<String, dynamic>>.from(orders));
  }

  Future<Map<String, List<Map<String, dynamic>>>> getOrders() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final response = await _client
        .from('orders')
        .select()
        .eq('delivery_partner_id', userId)
        .order('created_at', ascending: false);

    final List<Map<String, dynamic>> allOrders =
        List<Map<String, dynamic>>.from(response);

    final activeStatuses = ['accepted', 'picked_up', 'delivered'];
    final pastStatuses = ['completed', 'cancelled'];

    final activeOrders = allOrders
        .where(
          (order) =>
              activeStatuses.contains(order['status'].toString().toLowerCase()),
        )
        .toList();
    final pastOrders = allOrders
        .where(
          (order) =>
              pastStatuses.contains(order['status'].toString().toLowerCase()),
        )
        .toList();

    return {'active': activeOrders, 'past': pastOrders};
  }
}
