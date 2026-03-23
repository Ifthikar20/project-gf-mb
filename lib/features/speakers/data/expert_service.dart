import '../../../core/services/api_client.dart';
import '../../../core/services/app_logger.dart';
import '../domain/entities/expert_entity.dart';

/// Service for fetching instructor profile data
class ExpertService {
  final ApiClient _apiClient;
  
  static ExpertService? _instance;
  
  ExpertService._({ApiClient? apiClient}) 
      : _apiClient = apiClient ?? ApiClient.instance;
  
  /// Singleton instance
  static ExpertService get instance {
    _instance ??= ExpertService._();
    return _instance!;
  }
  
  /// Factory constructor for testing
  factory ExpertService({ApiClient? apiClient}) {
    if (apiClient != null) {
      return ExpertService._(apiClient: apiClient);
    }
    return instance;
  }

  /// Get instructor profile by slug or ID
  /// 
  /// Returns full instructor data including:
  /// - Profile info (name, bio, fun fact, image, background image)
  /// - Social links (LinkedIn, Instagram, website)
  /// - Organized content (videos, series, audio sessions)
  /// - Stats (total views, content counts)
  Future<ExpertEntity?> getExpertBySlug(String slugOrId) async {
    try {
      AppLogger.i('Fetching instructor profile: $slugOrId');
      
      final response = await _apiClient.get(
        '/api/instructors/$slugOrId',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        
        // Handle different response formats
        Map<String, dynamic> instructorData;
        if (data is Map<String, dynamic>) {
          instructorData = data['instructor'] ?? data['expert'] ?? data;
        } else {
          AppLogger.w('Unexpected response format for instructor');
          return null;
        }

        // Parse videos/audio/stats from top-level if present (new API format)
        if (data['videos'] is List && !instructorData.containsKey('videos')) {
          instructorData['videos'] = data['videos'];
        }
        if (data['audio_sessions'] is List && !instructorData.containsKey('audio_sessions')) {
          instructorData['audio_sessions'] = data['audio_sessions'];
        }
        if (data['stats'] is Map && !instructorData.containsKey('stats')) {
          instructorData['stats'] = data['stats'];
        }

        final expert = ExpertEntity.fromJson(instructorData);
        AppLogger.i('Loaded instructor: ${expert.name} (${expert.videos.length} videos, ${expert.series.length} series, ${expert.audioSessions.length} audio)');
        return expert;
      }

      AppLogger.w('Instructor not found: $slugOrId (status: ${response.statusCode})');
      return null;
    } catch (e, stackTrace) {
      AppLogger.e('Failed to fetch instructor profile', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get list of all instructors
  Future<List<ExpertEntity>> getAllExperts({int limit = 20, int offset = 0}) async {
    try {
      AppLogger.i('Fetching all instructors (limit: $limit, offset: $offset)');
      
      final response = await _apiClient.get(
        '/api/instructors',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic> items;
        
        if (data is List) {
          items = data;
        } else if (data is Map) {
          items = data['instructors'] ?? data['experts'] ?? data['items'] ?? [];
        } else {
          items = [];
        }

        final instructors = items.map((e) => ExpertEntity.fromJson(e)).toList();
        AppLogger.i('Fetched ${instructors.length} instructors');
        return instructors;
      }

      return [];
    } catch (e, stackTrace) {
      AppLogger.e('Failed to fetch instructors list', error: e, stackTrace: stackTrace);
      return [];
    }
  }
}
