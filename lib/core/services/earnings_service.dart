import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class EarningsService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<double> getTodaysEarningsStream() {
    final controller = StreamController<double>();
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      controller.addError(Exception('User not logged in'));
      return controller.stream;
    }

    Future<void> fetchEarnings() async {
      try {
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final response = await _client
            .from('orders')
            .select('payout')
            .eq('delivery_partner_id', userId)
            .eq('status', 'delivered')
            .gte('created_at', startOfDay.toIso8601String())
            .lt('created_at', endOfDay.toIso8601String());

        double total = 0;
        for (var order in response) {
          total += (order['payout'] as num?)?.toDouble() ?? 0.0;
        }
        controller.add(total);
      } catch (e) {
        controller.addError(e);
      }
    }

    fetchEarnings();
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (controller.isClosed) {
        timer.cancel();
      } else {
        fetchEarnings();
      }
    });

    return controller.stream;
  }

  Future<Map<String, double>> getWeeklySummary() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    final response = await _client
        .from('orders')
        .select('created_at, payout')
        .eq('delivery_partner_id', userId)
        .eq('status', 'completed')
        .gte('created_at', DateTime.now().toIso8601String().substring(0, 10));

    Map<String, double> weeklySummary = {
      'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0
    };

    for (var order in response) {
      final createdAt = DateTime.parse(order['created_at']);
      final dayOfWeek = createdAt.weekday;
      final dayKey = _getDayKey(dayOfWeek);
      weeklySummary[dayKey] = (weeklySummary[dayKey] ?? 0.0) + ((order['payout'] as num?)?.toDouble() ?? 0.0);
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

  Stream<List<Map<String, dynamic>>> getOrderHistory() {
    final controller = StreamController<List<Map<String, dynamic>>>();
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      controller.addError(Exception('User not logged in'));
      return controller.stream;
    }

    Future<void> fetchHistory() async {
      try {
        final response = await _client
            .from('orders')
            .select()
            .eq('delivery_partner_id', userId)
            .order('created_at', ascending: false);
        controller.add(response);
      } catch (e) {
        controller.addError(e);
      }
    }

    fetchHistory();
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (controller.isClosed) {
        timer.cancel();
      } else {
        fetchHistory();
      }
    });

    return controller.stream;
  }

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
