import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Personalization service for the BetterBliss API
/// Handles onboarding, user preferences, and content recommendations
class PersonalizationService {
  static PersonalizationService? _instance;
  final ApiClient _api;

  static PersonalizationService get instance {
    _instance ??= PersonalizationService._(ApiClient.instance);
    return _instance!;
  }

  PersonalizationService._(this._api);

  // ============================================
  // Onboarding
  // ============================================

  /// Check if the user has completed onboarding
  /// Returns true if completed, false otherwise
  Future<bool> isOnboardingCompleted() async {
    try {
      final response = await _api.get('/api/personalization/onboarding');
      final data = response.data as Map<String, dynamic>;
      return data['onboarding']?['is_completed'] == true;
    } catch (e) {
      debugPrint('⚠️ Onboarding check failed: $e');
      // Default to completed so users aren't stuck
      return true;
    }
  }

  /// Get the list of valid options for building the onboarding UI
  /// Call once and cache — the values don't change
  Future<Map<String, dynamic>> getOnboardingOptions() async {
    final response = await _api.get('/api/personalization/onboarding/options');
    return response.data as Map<String, dynamic>;
  }

  /// Submit onboarding answers
  /// Calling again updates the existing profile (idempotent)
  Future<Map<String, dynamic>> submitOnboarding({
    required List<String> fitnessGoals,
    required String experienceLevel,
    required String preferredSessionDuration,
    required List<String> interests,
    required String preferredTimeOfDay,
  }) async {
    final response = await _api.post(
      '/api/personalization/onboarding',
      data: {
        'fitness_goals': fitnessGoals,
        'experience_level': experienceLevel,
        'preferred_session_duration': preferredSessionDuration,
        'interests': interests,
        'preferred_time_of_day': preferredTimeOfDay,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ============================================
  // Preferences
  // ============================================

  /// Get user preferences (auto-created with defaults if first time)
  Future<Map<String, dynamic>> getPreferences() async {
    final response = await _api.get('/api/personalization/preferences');
    return response.data as Map<String, dynamic>;
  }

  /// Update specific preferences — only send fields you want to change
  Future<Map<String, dynamic>> updatePreferences({
    bool? notificationsEnabled,
    String? dailyReminderTime,
    bool? darkMode,
    String? contentLanguage,
    bool? autoplayNext,
    bool? downloadWifiOnly,
  }) async {
    final response = await _api.patch(
      '/api/personalization/preferences',
      data: {
        if (notificationsEnabled != null)
          'notifications_enabled': notificationsEnabled,
        if (dailyReminderTime != null)
          'daily_reminder_time': dailyReminderTime,
        if (darkMode != null) 'dark_mode': darkMode,
        if (contentLanguage != null) 'content_language': contentLanguage,
        if (autoplayNext != null) 'autoplay_next': autoplayNext,
        if (downloadWifiOnly != null) 'download_wifi_only': downloadWifiOnly,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ============================================
  // Recommendations
  // ============================================

  /// Get personalized content recommendations based on onboarding answers
  /// If onboarding not completed, returns popular content instead
  Future<Map<String, dynamic>> getRecommendations({
    int limit = 20,
    String? contentType, // 'video', 'audio', or 'article'
  }) async {
    final response = await _api.get(
      '/api/personalization/recommendations',
      queryParameters: {
        'limit': limit,
        if (contentType != null) 'type': contentType,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
