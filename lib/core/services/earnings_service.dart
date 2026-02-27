import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EarningsService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Real-time stream of today's total earnings using Supabase Realtime.
  /// Listens to changes on the 'orders' table and recalculates the sum
  /// of payouts for delivered orders created today.
  Stream<double> getTodaysEarningsStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.error(Exception('User not logged in'));

    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('delivery_partner_id', userId)
        .order('created_at', ascending: false)
        .map((orders) {
          final today = DateTime.now();
          final startOfDay = DateTime(today.year, today.month, today.day);

          double total = 0;
          for (var order in orders) {
            final status = (order['status'] as String? ?? '').toLowerCase();
            if (status != 'delivered') continue;

            final createdAt = DateTime.tryParse(order['created_at'] ?? '');
            if (createdAt == null || createdAt.isBefore(startOfDay)) continue;

            total += (order['payout'] as num?)?.toDouble() ?? 0.0;
          }
          return total;
        });
  }

  /// Real-time stream of weekly earnings summary using Supabase Realtime.
  /// Returns a map of day keys (Mon–Sun) to total payout amounts.
  Stream<Map<String, double>> getWeeklySummaryStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.error(Exception('User not logged in'));

    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('delivery_partner_id', userId)
        .order('created_at', ascending: false)
        .map((orders) {
          final now = DateTime.now();
          final startOfWeek = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: now.weekday - 1));

          Map<String, double> weeklySummary = {
            'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0
          };

          for (var order in orders) {
            final status = (order['status'] as String? ?? '').toLowerCase();
            if (status != 'completed') continue;

            final createdAt = DateTime.tryParse(order['created_at'] ?? '');
            if (createdAt == null || createdAt.isBefore(startOfWeek)) continue;

            final dayKey = _getDayKey(createdAt.weekday);
            weeklySummary[dayKey] = (weeklySummary[dayKey] ?? 0.0) +
                ((order['payout'] as num?)?.toDouble() ?? 0.0);
          }

          return weeklySummary;
        });
  }

  /// Kept for backward compatibility — fetches weekly summary once.
  Future<Map<String, double>> getWeeklySummary() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final response = await _client
        .from('orders')
        .select('created_at, payout')
        .eq('delivery_partner_id', userId)
        .eq('status', 'completed')
        .gte('created_at', startOfWeek.toIso8601String());

    Map<String, double> weeklySummary = {
      'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0
    };

    for (var order in response) {
      final createdAt = DateTime.parse(order['created_at']);
      final dayKey = _getDayKey(createdAt.weekday);
      weeklySummary[dayKey] = (weeklySummary[dayKey] ?? 0.0) +
          ((order['payout'] as num?)?.toDouble() ?? 0.0);
    }

    return weeklySummary;
  }

  String _getDayKey(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  /// Real-time stream of completed order history using Supabase Realtime.
  Stream<List<Map<String, dynamic>>> getOrderHistory() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.error(Exception('User not logged in'));

    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('delivery_partner_id', userId)
        .order('created_at', ascending: false)
        .map((orders) => List<Map<String, dynamic>>.from(orders));
  }

  /// Real-time stream of wallet balance using Supabase Realtime on profiles.
  Stream<double> getWalletBalanceStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.error(Exception('User not logged in'));

    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) {
          if (data.isEmpty) return 0.0;
          return (data.first['wallet_balance'] as num?)?.toDouble() ?? 0.0;
        });
  }

  /// Kept for backward compatibility — fetches wallet balance once.
  Future<double> getWalletBalance() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final response = await _client
        .from('profiles')
        .select('wallet_balance')
        .eq('id', userId)
        .single();

    return (response['wallet_balance'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, dynamic>> withdrawEarnings({
    required double amount,
    required String method,
    required Map<String, dynamic> details,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    try {
      final response = await _client.rpc('process_withdrawal', params: {
        'partner_id': userId,
        'withdrawal_amount': amount,
        'method': method,
        'details': details,
      });

      return Map<String, dynamic>.from(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Real-time stream of transaction history using Supabase Realtime.
  Stream<List<Map<String, dynamic>>> getTransactionHistory() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('delivery_partner_id', userId)
        .order('created_at', ascending: false);
  }
}
