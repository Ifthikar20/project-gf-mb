import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../config/environment_config.dart';
import 'api_client.dart';

/// Google Analytics 4 Service using Measurement Protocol
/// 
/// This is a simple HTTP-based approach similar to react-ga4 on web.
/// No Firebase SDK required - just uses the GA4 Measurement Protocol API.
/// 
/// Docs: https://developers.google.com/analytics/devguides/collection/protocol/ga4
class AnalyticsService {
  static AnalyticsService? _instance;
  
  // GA4 Configuration
  final String _measurementId;
  final String _apiSecret;
  
  // Endpoint for GA4 Measurement Protocol
  static const String _baseUrl = 'https://www.google-analytics.com/mp/collect';
  static const String _debugUrl = 'https://www.google-analytics.com/debug/mp/collect';
  
  // Client ID (persistent anonymous user identifier)
  String? _clientId;
  String? _userId;
  
  // Session tracking
  String? _sessionId;
  int _sessionNumber = 1;
  int _engagementTimeMs = 0;
  
  AnalyticsService._({
    required String measurementId,
    required String apiSecret,
  }) : _measurementId = measurementId,
       _apiSecret = apiSecret;
  
  static AnalyticsService get instance {
    _instance ??= AnalyticsService._(
      measurementId: EnvironmentConfig.instance.gaMeasurementId,
      apiSecret: EnvironmentConfig.instance.gaApiSecret,
    );
    return _instance!;
  }
  
  /// Initialize analytics (call once at app start)
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get or create persistent client ID
    _clientId = prefs.getString('ga_client_id');
    if (_clientId == null) {
      _clientId = const Uuid().v4();
      await prefs.setString('ga_client_id', _clientId!);
    }
    
    // Get session number
    _sessionNumber = prefs.getInt('ga_session_number') ?? 1;
    
    // Create new session
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    
    debugPrint('📊 GA4 initialized: $_measurementId');
    debugPrint('   Client ID: $_clientId');
    debugPrint('   Session #$_sessionNumber');
  }
  
  /// Set user ID (after login)
  void setUserId(String? userId) {
    _userId = userId;
    debugPrint('📊 GA4: User ID set');
  }
  
  // ============================================
  // VIDEO TRACKING
  // ============================================
  
  /// Track video view (sends to both GA4 and backend)
  Future<void> trackVideoView({
    required String videoId,
    required String videoTitle,
    String? category,
    String? expert,
    int? durationSeconds,
  }) async {
    // Send to GA4
    await _sendEvent('video_view', {
      'content_id': videoId,
      'video_title': _truncate(videoTitle, 100),
      if (category != null) 'category': category,
      if (expert != null) 'expert': expert,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      'content_type': 'video',
    });
    
    // Also send to backend to record view count
    await _trackViewToBackend(
      contentId: videoId,
      videoTitle: videoTitle,
      category: category,
      expert: expert,
      durationSeconds: durationSeconds,
    );
  }
  
  /// Track view to backend API (for view count tracking)
  Future<void> _trackViewToBackend({
    required String contentId,
    String? videoTitle,
    String? category,
    String? expert,
    int? durationSeconds,
  }) async {
    try {
      final api = ApiClient.instance;
      
      await api.post('/api/analytics/track/view', data: {
        'content_id': contentId,
        'video_title': videoTitle,
        'category': category,
        'expert': expert,
        'duration_seconds': durationSeconds,
        'user_id': _userId,
        'session_id': _sessionId,
      });
      
      debugPrint('📊 Backend: View tracked for $contentId ✓');
    } catch (e) {
      // Don't fail silently but also don't break the app
      debugPrint('⚠️ Backend view tracking failed: $e');
    }
  }
  
  /// Track video progress milestones
  Future<void> trackVideoProgress({
    required String videoId,
    required int progressPercent,
    required int watchTimeSeconds,
  }) async {
    await _sendEvent('video_progress', {
      'content_id': videoId,
      'progress_percent': progressPercent,
      'watch_time_seconds': watchTimeSeconds,
    });
  }
  
  /// Track video complete (90%+ watched)
  Future<void> trackVideoComplete({
    required String videoId,
    required String videoTitle,
    required int watchTimeSeconds,
  }) async {
    await _sendEvent('video_complete', {
      'content_id': videoId,
      'video_title': _truncate(videoTitle, 100),
      'watch_time_seconds': watchTimeSeconds,
    });
  }
  
  // ============================================
  // MEDITATION/AUDIO TRACKING
  // ============================================
  
  Future<void> trackMeditationStart({
    required String audioId,
    required String audioTitle,
    String? category,
    int? durationSeconds,
  }) async {
    // Send to GA4
    await _sendEvent('meditation_start', {
      'content_id': audioId,
      'audio_title': _truncate(audioTitle, 100),
      if (category != null) 'category': category,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      'content_type': 'audio',
    });
    
    // Also send to backend to record view count
    await _trackViewToBackend(
      contentId: audioId,
      videoTitle: audioTitle,
      category: category,
      durationSeconds: durationSeconds,
    );
  }
  
  Future<void> trackMeditationComplete({
    required String audioId,
    required int listenTimeSeconds,
  }) async {
    await _sendEvent('meditation_complete', {
      'content_id': audioId,
      'listen_time_seconds': listenTimeSeconds,
    });
  }
  
  // ============================================
  // USER LIFECYCLE EVENTS
  // ============================================
  
  Future<void> trackSignUp({String method = 'email'}) async {
    await _sendEvent('sign_up', {
      'method': method,
    });
  }
  
  Future<void> trackLogin({String method = 'email'}) async {
    await _sendEvent('login', {
      'method': method,
    });
  }
  
  // ============================================
  // CONTENT INTERACTION EVENTS
  // ============================================
  
  Future<void> trackAddToFavorites({
    required String contentId,
    required String contentTitle,
    required String contentType,
  }) async {
    await _sendEvent('add_to_favorites', {
      'content_id': contentId,
      'content_title': _truncate(contentTitle, 100),
      'content_type': contentType,
    });
  }
  
  Future<void> trackRemoveFromFavorites({
    required String contentId,
  }) async {
    await _sendEvent('remove_from_favorites', {
      'content_id': contentId,
    });
  }
  
  Future<void> trackSearch({
    required String searchTerm,
    int? resultCount,
  }) async {
    await _sendEvent('search', {
      'search_term': searchTerm,
      if (resultCount != null) 'result_count': resultCount,
    });
  }
  
  Future<void> trackCategoryView({
    required String categoryName,
    String? categorySlug,
  }) async {
    await _sendEvent('view_category', {
      'category_name': categoryName,
      if (categorySlug != null) 'category_slug': categorySlug,
    });
  }
  
  Future<void> trackExpertView({
    required String expertName,
    String? expertSlug,
  }) async {
    await _sendEvent('view_expert', {
      'expert_name': expertName,
      if (expertSlug != null) 'expert_slug': expertSlug,
    });
  }
  
  // ============================================
  // SCREEN/PAGE TRACKING
  // ============================================
  
  Future<void> trackScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _sendEvent('screen_view', {
      'screen_name': screenName,
      if (screenClass != null) 'screen_class': screenClass,
    });
  }
  
  // ============================================
  // CORE EVENT SENDING
  // ============================================
  
  /// Send event to GA4 Measurement Protocol
  Future<void> _sendEvent(String eventName, Map<String, dynamic> params) async {
    // Skip if not configured
    if (_measurementId.isEmpty || _apiSecret.isEmpty) {
      debugPrint('📊 [GA4 Disabled] $eventName: $params');
      return;
    }
    
    // Initialize if needed
    if (_clientId == null) {
      await initialize();
    }
    
    try {
      final url = Uri.parse('$_baseUrl?measurement_id=$_measurementId&api_secret=$_apiSecret');
      
      final body = {
        'client_id': _clientId,
        if (_userId != null) 'user_id': _userId,
        'events': [
          {
            'name': eventName,
            'params': {
              ...params,
              'session_id': _sessionId,
              'engagement_time_msec': _engagementTimeMs.toString(),
            },
          },
        ],
      };
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        debugPrint('📊 GA4: $eventName sent ✓');
      } else {
        debugPrint('⚠️ GA4 error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('⚠️ GA4 send failed: $e');
      // Don't throw - analytics failures shouldn't break the app
    }
  }
  
  /// Debug: Validate event (sends to debug endpoint)
  Future<Map<String, dynamic>?> validateEvent(String eventName, Map<String, dynamic> params) async {
    if (_measurementId.isEmpty || _apiSecret.isEmpty) {
      return {'error': 'GA4 not configured'};
    }
    
    if (_clientId == null) {
      await initialize();
    }
    
    try {
      final url = Uri.parse('$_debugUrl?measurement_id=$_measurementId&api_secret=$_apiSecret');
      
      final body = {
        'client_id': _clientId,
        'events': [
          {
            'name': eventName,
            'params': params,
          },
        ],
      };
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  // ============================================
  // SESSION MANAGEMENT
  // ============================================
  
  /// Start new session (call when app comes to foreground)
  Future<void> startNewSession() async {
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _sessionNumber++;
    _engagementTimeMs = 0;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ga_session_number', _sessionNumber);
    
    // Send session_start event
    await _sendEvent('session_start', {
      'session_number': _sessionNumber,
    });
  }
  
  /// Update engagement time (call periodically while app is active)
  void updateEngagementTime(int additionalMs) {
    _engagementTimeMs += additionalMs;
  }
  
  // ============================================
  // UTILITY
  // ============================================
  
  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
}
