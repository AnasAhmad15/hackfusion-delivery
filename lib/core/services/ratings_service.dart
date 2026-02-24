import 'package:supabase_flutter/supabase_flutter.dart';

class RatingsService {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetches the average rating and total rating count
  Future<Map<String, dynamic>> getRatingsSummary() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final response = await _client
        .from('ratings')
        .select('rating')
        .eq('delivery_partner_id', userId);

    if (response.isEmpty) {
      return {'average_rating': 0.0, 'total_ratings': 0};
    }

    double totalRating = 0;
    for (var item in response) {
      totalRating += (item['rating'] as num?)?.toDouble() ?? 0.0;
    }
    final averageRating = totalRating / response.length;

    return {
      'average_rating': averageRating,
      'total_ratings': response.length,
    };
  }

  // Fetches the list of feedback/reviews
  Future<List<Map<String, dynamic>>> getFeedbackList() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    return await _client
        .from('ratings')
        .select('feedback, created_at')
        .eq('delivery_partner_id', userId)
        .order('created_at', ascending: false);
  }
}
