import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pharmaco_delivery_partner/core/models/onboarding_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>> getProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return response ?? {};
  }

  Stream<Map<String, dynamic>> getProfileStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value({});

    debugPrint('ProfileService: Starting real-time profile stream for $userId');
    
    // Using .stream with eq filter for real-time updates
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) {
          if (data.isEmpty) {
            debugPrint('ProfileService: Profile not found for $userId');
            return <String, dynamic>{};
          }
          final profile = Map<String, dynamic>.from(data.first);
          debugPrint('ProfileService: Received realtime update: ${profile['full_name']}');
          return profile;
        })
        .handleError((error) {
          debugPrint('ProfileService: Stream error: $error');
          return <String, dynamic>{};
        });
  }

  Future<void> updateAvailability(bool isAvailable) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    await _client.from('profiles').update({'is_available': isAvailable}).eq('id', userId);
  }

  Future<void> updateOnboardingProfile(OnboardingProfile profile) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    String? photoUrl;
    if (profile.profileImage != null) {
      final fileExt = path.extension(profile.profileImage!.path);
      final fileName = 'profile_$userId${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final filePath = 'avatars/$fileName';

      await _client.storage.from('profile-photos').upload(
            filePath,
            profile.profileImage!,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
      photoUrl = _client.storage.from('profile-photos').getPublicUrl(filePath);
    }

    final updates = {
      'full_name': profile.fullName,
      'phone': profile.phone,
      'email': profile.email,
      'date_of_birth': profile.dateOfBirth?.toIso8601String(),
      'gender': profile.gender,
      'vehicle_type': profile.vehicleType,
      'vehicle_model': profile.vehicleModel,
      'vehicle_registration': profile.vehicleRegistration,
      'preferred_delivery_area': profile.preferredDeliveryArea,
      'profile_completed': true,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (photoUrl != null) {
      updates['profile_photo_url'] = photoUrl;
    }

    await _client.from('profiles').update(updates).eq('id', userId);
  }
}
