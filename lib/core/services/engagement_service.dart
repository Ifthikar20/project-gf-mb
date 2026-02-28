import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Engagement service for the BetterBliss API
/// Handles watch events, watch history, streaks, and favorites
class EngagementService {
  static EngagementService? _instance;
  final ApiClient _api;

  static EngagementService get instance {
    _instance ??= EngagementService._(ApiClient.instance);
    return _instance!;
  }

  EngagementService._(this._api);

  // ============================================
  // Watch Events
  // ============================================

  /// Log a watch event for content
  /// Call this when a user starts watching/listening to content
  Future<Map<String, dynamic>> logWatch({
    required String contentId,
    int? durationSeconds,
    int? progressSeconds,
  }) async {
    try {
      final response = await _api.post(
        '/api/engagement/watch',
        data: {
          'content_id': contentId,
          if (durationSeconds != null) 'duration_seconds': durationSeconds,
          if (progressSeconds != null) 'progress_seconds': progressSeconds,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('⚠️ Failed to log watch event: $e');
      rethrow;
    }
  }

  // ============================================
  // Watch History
  // ============================================

  /// Get the user's watch history
  Future<Map<String, dynamic>> getHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _api.get(
      '/api/engagement/history',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ============================================
  // Streaks
  // ============================================

  /// Get the user's streak statistics
  /// Returns current streak, longest streak, total days, etc.
  Future<Map<String, dynamic>> getStreak() async {
    final response = await _api.get('/api/engagement/streak');
    return response.data as Map<String, dynamic>;
  }

  // ============================================
  // Favorites
  // ============================================

  /// Toggle favorite status for a piece of content
  /// Returns the updated favorite status
  Future<Map<String, dynamic>> toggleFavorite(String contentId) async {
    final response = await _api.post('/api/engagement/favorite/$contentId');
    return response.data as Map<String, dynamic>;
  }

  /// Get the user's list of favorited content
  Future<Map<String, dynamic>> getFavorites({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _api.get(
      '/api/engagement/favorites',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
