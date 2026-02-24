import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> getIncomingOrders({double? lat, double? lng, double radiusMeters = 5000}) {
    if (lat != null && lng != null) {
      // Use the RPC for nearby orders
      return _client
          .rpc('get_nearby_orders', params: {
            'partner_lat': lat,
            'partner_lng': lng,
            'radius_meters': radiusMeters,
          })
          .asStream()
          .map((data) => List<Map<String, dynamic>>.from(data));
    }

    // Fallback to standard stream if no location is provided
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .map((orders) => orders.where((order) => order['delivery_partner_id'] == null).toList());
  }

  Stream<int> getAvailableOrdersCountStream({double? lat, double? lng, double radiusMeters = 5000}) {
    if (lat != null && lng != null) {
      return getIncomingOrders(lat: lat, lng: lng, radiusMeters: radiusMeters)
          .map((orders) => orders.length);
    }
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .map((orders) => orders.where((order) => order['delivery_partner_id'] == null).length);
  }

  Future<void> acceptOrder(String orderId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _client.from('orders').update({
      'status': 'accepted',
      'delivery_partner_id': userId,
    }).eq('id', orderId);
  }

  Future<void> rejectOrder(String orderId) async {
    // In a real app, you might hide this order from the user instead of changing status
    print('Order $orderId rejected by user.');
  }

  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    final response = await _client.from('orders').select().eq('id', orderId).single();
    return response;
  }

  Stream<Map<String, dynamic>?> getOrderStream(String orderId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((orders) => orders.isNotEmpty ? Map<String, dynamic>.from(orders.first) : null);
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
      final response = await _client.rpc('complete_order', params: {
        'p_order_id': orderId,
        'p_partner_id': userId,
        'p_proof_type': proofType,
        'p_proof_url': proofUrl,
        'p_lat': lat,
        'p_lng': lng,
      });

      return Map<String, dynamic>.from(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> updateLastActivity() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('orders')
        .update({'last_activity_at': DateTime.now().toIso8601String()})
        .eq('delivery_partner_id', userId)
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

    final activeStatuses = ['assigned', 'accepted', 'picked_up', 'on_the_way', 'delivered'];
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('delivery_partner_id', userId)
        .order('created_at', ascending: false)
        .map((orders) {
          final activeOrders = orders.where((order) => 
            activeStatuses.contains(order['status']?.toString().toLowerCase())
          ).toList();
          return activeOrders.isNotEmpty ? Map<String, dynamic>.from(activeOrders.first) : null;
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

    final List<Map<String, dynamic>> allOrders = List<Map<String, dynamic>>.from(response);

    final activeStatuses = ['accepted', 'picked_up', 'on_the_way', 'delivered'];
    final pastStatuses = ['completed', 'cancelled'];

    final activeOrders = allOrders.where((order) => activeStatuses.contains(order['status'].toString().toLowerCase())).toList();
    final pastOrders = allOrders.where((order) => pastStatuses.contains(order['status'].toString().toLowerCase())).toList();

    return {
      'active': activeOrders,
      'past': pastOrders,
    };
  }
}