import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../config/environment_config.dart';

/// Content service for the BetterBliss API
/// Handles content browsing, categories, instructors, and analytics tracking
class ContentService {
  static ContentService? _instance;
  final ApiClient _api;
  
  static ContentService get instance {
    _instance ??= ContentService._(ApiClient.instance);
    return _instance!;
  }
  
  ContentService._(this._api);
  
  // ============================================
  // Content Browsing
  // ============================================
  
  /// Browse and search content (public — no auth required)
  Future<Map<String, dynamic>> browseContent({
    String? search,
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _api.get(
      '/api/content/browse',
      queryParameters: {
        if (search != null) 'search': search,
        if (category != null) 'category': category,
        'limit': limit,
        'offset': offset,
      },
    );
    return response.data as Map<String, dynamic>;
  }
  
  /// Get a single content item by UUID
  Future<Map<String, dynamic>> getContentDetail(String contentId) async {
    final response = await _api.get('/api/content/$contentId');
    return response.data as Map<String, dynamic>;
  }
  
  // ============================================
  // Categories
  // ============================================
  
  /// List all content categories
  Future<Map<String, dynamic>> getCategories() async {
    final response = await _api.get('/api/categories');
    return response.data as Map<String, dynamic>;
  }
  
  // ============================================
  // Instructors (formerly Experts)
  // ============================================
  
  /// List featured wellness instructors
  Future<Map<String, dynamic>> getFeaturedExperts() async {
    final response = await _api.get('/api/instructors');
    return response.data as Map<String, dynamic>;
  }
  
  /// Search for instructors
  Future<Map<String, dynamic>> searchExperts(String query) async {
    final response = await _api.get(
      '/api/instructors/search',
      queryParameters: {'q': query},
    );
    return response.data as Map<String, dynamic>;
  }
  
  /// Get full expert profile with their content
  Future<Map<String, dynamic>> getExpertProfile(String slug) async {
    final response = await _api.get('/api/instructors/$slug');
    return response.data as Map<String, dynamic>;
  }
  
  // ============================================
  // Analytics Tracking
  // ============================================
  
  /// Track a content view
  Future<void> trackView(String contentId) async {
    try {
      await _api.post('/api/track/view/$contentId');
    } catch (e) {
      debugPrint(' Track view failed: $e');
    }
  }
  
  /// Track a content play
  Future<void> trackPlay(String contentId) async {
    try {
      await _api.post('/api/track/play/$contentId');
    } catch (e) {
      debugPrint(' Track play failed: $e');
    }
  }
  
  /// Track a search query
  Future<void> trackSearch(String query) async {
    try {
      await _api.post('/api/track/search', data: {'query': query});
    } catch (e) {
      debugPrint(' Track search failed: $e');
    }
  }
  
  // ============================================
  // Streaming
  // ============================================
  
  /// Build the stream URL for a content item
  String getStreamUrl(String contentId) {
    return '${EnvironmentConfig.instance.apiBaseUrl}/$contentId/stream';
  }
}
