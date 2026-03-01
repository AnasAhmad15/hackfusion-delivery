import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class PayoutDetailsService {
  final SupabaseClient _client = Supabase.instance.client;

  // --- Bank Details ---

  Future<Map<String, dynamic>?> getBankDetails() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      return await _client
          .from('bank_details')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
    } catch (e) {
      debugPrint('PayoutDetailsService.getBankDetails error: $e');
      return null;
    }
  }

  Future<void> saveBankDetails({
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
    required String bankName,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _client.from('bank_details').upsert({
      'user_id': userId,
      'account_holder_name': accountHolderName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'bank_name': bankName,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // --- UPI Details ---

  Future<Map<String, dynamic>?> getUPIDetails() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      return await _client
          .from('upi_details')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
    } catch (e) {
      debugPrint('PayoutDetailsService.getUPIDetails error: $e');
      return null;
    }
  }

  Future<void> saveUPIDetails(String upiId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _client.from('upi_details').upsert({
      'user_id': userId,
      'upi_id': upiId,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
