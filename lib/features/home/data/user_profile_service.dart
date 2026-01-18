import 'package:supabase_flutter/supabase_flutter.dart';

/// Service untuk mengelola data User Profile
class UserProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch user profile berdasarkan user ID
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      rethrow;
    }
  }

  /// Fetch hanya target calorie
  Future<int> getTargetCalorie(String userId) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select('target_calorie')
          .eq('id', userId)
          .single();
      return response['target_calorie'] ?? 2000;
    } catch (e) {
      print('Error fetching target calorie: $e');
      return 2000; // Default value
    }
  }

  /// Update target calorie
  Future<void> updateTargetCalorie(String userId, int targetCalorie) async {
    try {
      await _client
          .from('user_profiles')
          .update({'target_calorie': targetCalorie})
          .eq('id', userId);
    } catch (e) {
      print('Error updating target calorie: $e');
      rethrow;
    }
  }

  /// Create user profile
  Future<void> createUserProfile({
    required String userId,
    required String fullName,
    int targetCalorie = 2000,
    int? age,
    String? gender,
    int? height,
    int? weight,
    String activityLevel = 'moderate',
  }) async {
    try {
      await _client.from('user_profiles').insert({
        'id': userId,
        'full_name': fullName,
        'target_calorie': targetCalorie,
        'age': age,
        'gender': gender,
        'height': height,
        'weight': weight,
        'activity_level': activityLevel,
      });
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  /// Update full user profile
  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    int? targetCalorie,
    int? age,
    String? gender,
    int? height,
    int? weight,
    String? activityLevel,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (fullName != null) updates['full_name'] = fullName;
      if (targetCalorie != null) updates['target_calorie'] = targetCalorie;
      if (age != null) updates['age'] = age;
      if (gender != null) updates['gender'] = gender;
      if (height != null) updates['height'] = height;
      if (weight != null) updates['weight'] = weight;
      if (activityLevel != null) updates['activity_level'] = activityLevel;

      if (updates.isEmpty) return;

      await _client.from('user_profiles').update(updates).eq('id', userId);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Subscribe to user profile changes (real-time)
  Stream<List<Map<String, dynamic>>> watchUserProfile(String userId) {
    return _client
        .from('user_profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((event) => event.cast<Map<String, dynamic>>());
  }
}
