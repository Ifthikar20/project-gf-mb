import 'package:flutter/foundation.dart';
import '../config/environment_config.dart';
import 'api_client.dart';

/// Streaming URL response from backend
class StreamingUrls {
  final String hlsMaster;
  final String? hls720p;
  final String? hls1080p;
  final String? thumbnail;
  final DateTime expiresAt;
  
  StreamingUrls({
    required this.hlsMaster,
    this.hls720p,
    this.hls1080p,
    this.thumbnail,
    required this.expiresAt,
  });
  
  factory StreamingUrls.fromJson(Map<String, dynamic> json) {
    return StreamingUrls(
      hlsMaster: json['hls_master'] ?? json['stream_url'] ?? '',
      hls720p: json['hls_720p'],
      hls1080p: json['hls_1080p'],
      thumbnail: json['thumbnail'],
      expiresAt: DateTime.tryParse(json['expires_at'] ?? '') ?? 
                 DateTime.now().add(const Duration(hours: 2)),
    );
  }
  
  /// Check if URLs are still valid
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  /// Time until expiry
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());
}

/// Content detail from backend
class ContentDetail {
  final String id;
  final String title;
  final String? description;
  final String contentType; // 'video' or 'audio'
  final String accessTier;  // 'free', 'basic', 'premium'
  final int durationSeconds;
  final String? thumbnailUrl;
  final bool locked;
  final bool canStream;
  final bool isHlsReady;
  
  ContentDetail({
    required this.id,
    required this.title,
    this.description,
    required this.contentType,
    required this.accessTier,
    required this.durationSeconds,
    this.thumbnailUrl,
    required this.locked,
    required this.canStream,
    required this.isHlsReady,
  });
  
  factory ContentDetail.fromJson(Map<String, dynamic> json) {
    return ContentDetail(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      contentType: json['content_type'] ?? 'video',
      accessTier: json['access_tier'] ?? 'free',
      durationSeconds: json['duration_seconds'] ?? 0,
      thumbnailUrl: json['thumbnail_url'],
      locked: json['locked'] ?? false,
      canStream: json['can_stream'] ?? false,
      isHlsReady: json['is_hls_ready'] ?? false,
    );
  }
}

/// Service for secure HLS video streaming
class StreamingService {
  static StreamingService? _instance;
  final ApiClient _api;
  
  // Cache streaming URLs to avoid repeated requests
  final Map<String, StreamingUrls> _urlCache = {};
  
  static StreamingService get instance {
    _instance ??= StreamingService._(ApiClient.instance);
    return _instance!;
  }
  
  StreamingService._(this._api);
  
  // ============================================
  // Content Methods
  // ============================================
  
  /// Get content detail by UUID
  Future<ContentDetail> getContentDetail(String contentId) async {
    try {
      final response = await _api.get('/content/detail/$contentId');
      return ContentDetail.fromJson(response.data);
    } catch (e) {
      throw StreamingException('Failed to get content detail: $e');
    }
  }
  
  /// Browse content with optional filters
  Future<List<ContentDetail>> browseContent({
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _api.get('/content/browse', queryParameters: {
        if (category != null) 'category': category,
        'limit': limit,
        'offset': offset,
      });
      
      final List<dynamic> items = response.data['content'] ?? [];
      return items.map((json) => ContentDetail.fromJson(json)).toList();
    } catch (e) {
      throw StreamingException('Failed to browse content: $e');
    }
  }
  
  // ============================================
  // Streaming Methods
  // ============================================
  
  /// Get secure streaming URLs for content
  /// Calls the streaming endpoint to get signed CloudFront URLs
  /// Falls back to content detail if streaming endpoint fails
  Future<StreamingUrls> getStreamingUrls(String contentId) async {
    // Check cache first
    if (_urlCache.containsKey(contentId)) {
      final cached = _urlCache[contentId]!;
      // Return cached if still valid (with 5 min buffer)
      if (cached.timeUntilExpiry.inMinutes > 5) {
        debugPrint('📼 Using cached streaming URLs for $contentId');
        return cached;
      }
    }
    
    // Method 1: Call the streaming endpoint for signed URLs (preferred)
    try {
      debugPrint('🔐 Calling streaming endpoint for signed URL: /api/streaming/content/$contentId/stream');
      final response = await _api.get('/api/streaming/content/$contentId/stream');
      final data = response.data;
      debugPrint('🔐 Streaming response: $data');
      
      // Parse the streaming response with signed URLs
      final hlsPlaylistUrl = data['hls_playlist_url'] as String?;
      if (hlsPlaylistUrl != null && hlsPlaylistUrl.isNotEmpty) {
        // Diagnostic: Check if the URL appears to be signed
        final isSigned = hlsPlaylistUrl.contains('Policy=') || 
                         hlsPlaylistUrl.contains('Signature=') || 
                         hlsPlaylistUrl.contains('md5=');
        
        if (isSigned) {
          debugPrint('✅ Got signed streaming URL: $hlsPlaylistUrl');
        } else {
          debugPrint('⚠️ WARNING: Got UNSIGNED streaming URL from endpoint: $hlsPlaylistUrl');
          debugPrint('💡 TIP: CloudFront likely requires a signed URL. This may cause a 403 Forbidden error.');
        }
        
        final expiresAt = DateTime.tryParse(data['expires_at'] ?? '') ?? 
            DateTime.now().add(const Duration(hours: 2));
        
        final urls = StreamingUrls(
          hlsMaster: hlsPlaylistUrl,
          thumbnail: data['thumbnail_url'],
          expiresAt: expiresAt,
        );
        
        // Cache the signed URLs
        _urlCache[contentId] = urls;
        return urls;
      } else {
        debugPrint('⚠️ Streaming response missing hls_playlist_url');
      }
    } catch (e) {
      debugPrint('⚠️ Streaming endpoint failed, trying fallback: $e');
    }
    
    // Method 2: Fall back to content detail (unsigned URLs, may fail)
    final urls = await getStreamingUrlsFromContentDetail(contentId);
    if (urls != null) {
      return urls;
    }
    
    throw StreamingException('No HLS streaming URLs available for this content');
  }
  
  /// Construct HLS streaming URLs directly from content detail fields
  /// First tries s3_key_video fields, then falls back to hls_playlist_url
  /// Requires CLOUDFRONT_URL to be set in .env for s3_key construction
  Future<StreamingUrls?> getStreamingUrlsFromContentDetail(String contentId) async {
    try {
      final response = await _api.get('/content/detail/$contentId');
      final data = response.data;
      
      // Check for s3_key fields first
      final s3Key720p = data['s3_key_video_720p'];
      final s3Key1080p = data['s3_key_video_1080p'];
      
      String? hls720p;
      String? hls1080p;
      String hlsMaster = '';
      
      // Method 1: Construct from s3_key fields
      if (s3Key720p != null || s3Key1080p != null) {
        final cloudfrontUrl = EnvironmentConfig.instance.cloudfrontUrl;
        if (cloudfrontUrl.isNotEmpty) {
          hls720p = s3Key720p != null ? '$cloudfrontUrl/$s3Key720p' : null;
          hls1080p = s3Key1080p != null ? '$cloudfrontUrl/$s3Key1080p' : null;
          hlsMaster = hls720p ?? hls1080p ?? '';
          debugPrint('✅ Constructed HLS URLs from s3_keys: $hlsMaster');
        }
      }
      
      // Method 2: Fall back to hls_playlist_url if s3_keys didn't work
      if (hlsMaster.isEmpty) {
        final hlsPlaylistUrl = data['hls_playlist_url'];
        if (hlsPlaylistUrl != null && hlsPlaylistUrl.toString().isNotEmpty) {
          hlsMaster = hlsPlaylistUrl.toString();
          debugPrint('✅ Using hls_playlist_url directly: $hlsMaster');
        }
      }
      
      // Check is_hls_ready flag
      final isHlsReady = data['is_hls_ready'] ?? false;
      if (!isHlsReady && hlsMaster.isNotEmpty) {
        debugPrint('⚠️ Content has HLS URL but is_hls_ready=false, attempting anyway');
      }
      
      if (hlsMaster.isEmpty) {
        debugPrint('⚠️ No HLS URLs available in content detail');
        return null;
      }
      
      final urls = StreamingUrls(
        hlsMaster: hlsMaster,
        hls720p: hls720p,
        hls1080p: hls1080p,
        thumbnail: data['thumbnail_url'],
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
      );
      
      // NOTE: Don't cache these URLs - they are unsigned and may fail with 403
      // Only signed URLs from the streaming endpoint should be cached
      
      return urls;
    } catch (e) {
      debugPrint('❌ Failed to get HLS URLs from content detail: $e');
      return null;
    }
  }
  
  /// Clear cached URLs (on logout or error)
  void clearCache() {
    _urlCache.clear();
  }
  
  /// Check if content can be streamed by current user
  Future<bool> canStream(String contentId) async {
    try {
      final content = await getContentDetail(contentId);
      return content.canStream && !content.locked;
    } catch (e) {
      return false;
    }
  }
  
  /// Refresh streaming URLs before they expire
  Future<StreamingUrls> refreshStreamingUrls(String contentId) async {
    _urlCache.remove(contentId);
    return getStreamingUrls(contentId);
  }
}

/// Streaming exception
class StreamingException implements Exception {
  final String message;
  StreamingException(this.message);
  
  @override
  String toString() => message;
}
