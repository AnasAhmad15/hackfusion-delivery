import 'package:supabase_flutter/supabase_flutter.dart';

class RatingsService {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetches the average rating and total rating count
  Future<Map<String, dynamic>> getRatingsSummary() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    try {
      final response = await _client
          .from('ratings')
          .select('rating')
          .eq('delivery_partner_id', userId);

      if (response == null || (response as List).isEmpty) {
        return {'average_rating': 0.0, 'total_ratings': 0};
      }

      final List ratingsList = response as List;
      double totalRating = 0;
      for (var item in ratingsList) {
        totalRating += (item['rating'] as num?)?.toDouble() ?? 0.0;
      }
      final averageRating = totalRating / ratingsList.length;

      return {
        'average_rating': averageRating,
        'total_ratings': ratingsList.length,
      };
    } catch (e) {
      print('RatingsService.getRatingsSummary error: $e');
      return {'average_rating': 0.0, 'total_ratings': 0};
    }
  }

  // Fetches the list of feedback/reviews
  Future<List<Map<String, dynamic>>> getFeedbackList() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    try {
      final response = await _client
          .from('ratings')
          .select('rating, feedback, created_at')
          .eq('delivery_partner_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('RatingsService.getFeedbackList error: $e');
      return [];
    }
  }
}
