import '../../../core/services/api_client.dart';
import '../../../core/services/app_logger.dart';
import '../domain/entities/expert_entity.dart';

/// Service for fetching expert/speaker profile data
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

  /// Get expert profile by slug or ID
  /// 
  /// Returns full expert data including:
  /// - Profile info (name, bio, image, background image)
  /// - Social links (LinkedIn, Instagram, website)
  /// - Organized content (videos, series, audio sessions)
  /// - Stats (total views, content counts)
  Future<ExpertEntity?> getExpertBySlug(String slugOrId) async {
    try {
      AppLogger.i('Fetching expert profile: $slugOrId');
      
      final response = await _apiClient.get(
        '/content/experts/$slugOrId',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        
        // Handle different response formats
        Map<String, dynamic> expertData;
        if (data is Map<String, dynamic>) {
          expertData = data['expert'] ?? data;
        } else {
          AppLogger.w('Unexpected response format for expert');
          return null;
        }

        final expert = ExpertEntity.fromJson(expertData);
        AppLogger.i('Loaded expert: ${expert.name} (${expert.videos.length} videos, ${expert.series.length} series, ${expert.audioSessions.length} audio)');
        return expert;
      }

      AppLogger.w('Expert not found: $slugOrId (status: ${response.statusCode})');
      return null;
    } catch (e, stackTrace) {
      AppLogger.e('Failed to fetch expert profile', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get list of all experts
  Future<List<ExpertEntity>> getAllExperts({int limit = 20, int offset = 0}) async {
    try {
      AppLogger.i('Fetching all experts (limit: $limit, offset: $offset)');
      
      final response = await _apiClient.get(
        '/experts',
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
          items = data['experts'] ?? data['items'] ?? [];
        } else {
          items = [];
        }

        final experts = items.map((e) => ExpertEntity.fromJson(e)).toList();
        AppLogger.i('Fetched ${experts.length} experts');
        return experts;
      }

      return [];
    } catch (e, stackTrace) {
      AppLogger.e('Failed to fetch experts list', error: e, stackTrace: stackTrace);
      return [];
    }
  }
}
