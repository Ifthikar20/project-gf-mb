import 'package:flutter/foundation.dart';
import '../../../../core/services/api_client.dart';
import '../../domain/entities/video_entity.dart';
import '../../domain/entities/episode_entity.dart';
import '../../domain/entities/series_entity.dart';

class VideosRepository {
  final ApiClient _api = ApiClient.instance;
  
  // Cache for videos
  List<VideoEntity>? _cachedVideos;
  
  /// Fetch videos from backend API
  /// Falls back to mock data if API fails or user is not authenticated
  Future<List<VideoEntity>> getVideos({String? category}) async {
    try {
      // Try fetching from backend API
      debugPrint('📼 Fetching videos from API...');
      final response = await _api.get('/content/browse', queryParameters: {
        if (category != null && category != 'All') 'category': category,
        'content_type': 'video',
        'limit': 50,
      });
      
      final List<dynamic> items = response.data['content'] ?? response.data ?? [];
      List<VideoEntity> videos = items.map((json) => VideoEntity(
        id: json['id'] ?? json['uuid'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        thumbnailUrl: json['thumbnail_url'] ?? 'https://via.placeholder.com/600x400?text=Video',
        videoUrl: json['video_url'] ?? json['hls_url'] ?? '',
        durationInSeconds: json['duration_seconds'] ?? 0,
        category: json['category_name'] ?? json['category'] ?? 'General',
        instructor: json['expert_name'] ?? json['instructor'] ?? 'Instructor',
        accessTier: json['access_tier'] ?? 'free',
        viewCount: json['view_count'] ?? 0,
        // Series fields
        isSeries: json['is_series'] ?? false,
        seriesId: json['series_id'],
        episodeNumber: json['episode_number'],
        episodeCount: json['episode_count'],
      )).toList();
      
      debugPrint('✅ Loaded ${videos.length} videos from API');
      
      // Fetch view counts for all videos
      videos = await _enrichWithViewCounts(videos);
      
      _cachedVideos = videos;
      return videos;
    } catch (e) {
      debugPrint('⚠️ API fetch failed, using mock data: $e');
      return _getMockVideos(category);
    }
  }
  
  /// Get a single video by ID (UUID)
  Future<VideoEntity?> getVideoById(String id) async {
    // Check cache first
    if (_cachedVideos != null) {
      try {
        return _cachedVideos!.firstWhere((v) => v.id == id);
      } catch (_) {
        // Not in cache, fetch from API
      }
    }
    
    try {
      // Fetch specific video from API
      debugPrint('📼 Fetching video $id from API...');
      final response = await _api.get('/content/detail/$id');
      
      final json = response.data;
      VideoEntity video = VideoEntity(
        id: json['id'] ?? json['uuid'] ?? id,
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        thumbnailUrl: json['thumbnail_url'] ?? 'https://via.placeholder.com/600x400?text=Video',
        videoUrl: json['video_url'] ?? json['hls_url'] ?? '',
        durationInSeconds: json['duration_seconds'] ?? 0,
        category: json['category_name'] ?? json['category'] ?? 'General',
        instructor: json['expert_name'] ?? json['instructor'] ?? 'Instructor',
        accessTier: json['access_tier'] ?? 'free',
        viewCount: json['view_count'] ?? 0,
        // Series fields
        isSeries: json['is_series'] ?? false,
        seriesId: json['series_id'],
        episodeNumber: json['episode_number'],
        episodeCount: json['episode_count'],
      );
      
      // Fetch view count for this specific video
      final viewCount = await _getViewCount(id);
      if (viewCount > 0) {
        video = _copyWithViewCount(video, viewCount);
      }
      
      return video;
    } catch (e) {
      debugPrint('⚠️ Video detail fetch failed: $e');
      // Fall back to mock
      final mockVideos = await _getMockVideos(null);
      try {
        return mockVideos.firstWhere((v) => v.id == id);
      } catch (_) {
        return mockVideos.isNotEmpty ? mockVideos.first : null;
      }
    }
  }
  
  /// Fetch view counts from analytics API and enrich videos
  Future<List<VideoEntity>> _enrichWithViewCounts(List<VideoEntity> videos) async {
    try {
      debugPrint('📊 Fetching view counts for ${videos.length} videos...');
      
      // Fetch view counts for each video (in parallel)
      final futures = videos.map((video) => _getViewCount(video.id));
      final viewCounts = await Future.wait(futures);
      
      // Create new list with updated view counts
      final enrichedVideos = <VideoEntity>[];
      for (int i = 0; i < videos.length; i++) {
        if (viewCounts[i] > 0) {
          enrichedVideos.add(_copyWithViewCount(videos[i], viewCounts[i]));
        } else {
          enrichedVideos.add(videos[i]);
        }
      }
      
      debugPrint('✅ View counts enriched');
      return enrichedVideos;
    } catch (e) {
      debugPrint('⚠️ Failed to fetch view counts: $e');
      return videos; // Return original videos if enrichment fails
    }
  }
  
  /// Get view count for a single video from analytics API
  Future<int> _getViewCount(String contentId) async {
    try {
      final response = await _api.get('/api/analytics/views/$contentId');
      return response.data['view_count'] ?? 0;
    } catch (e) {
      // Silent fail - view count is optional
      return 0;
    }
  }
  
  /// Create a copy of VideoEntity with updated view count
  VideoEntity _copyWithViewCount(VideoEntity video, int viewCount) {
    return VideoEntity(
      id: video.id,
      title: video.title,
      description: video.description,
      thumbnailUrl: video.thumbnailUrl,
      videoUrl: video.videoUrl,
      durationInSeconds: video.durationInSeconds,
      category: video.category,
      instructor: video.instructor,
      accessTier: video.accessTier,
      viewCount: viewCount,
      // Preserve series fields
      isSeries: video.isSeries,
      seriesId: video.seriesId,
      episodeNumber: video.episodeNumber,
      episodeCount: video.episodeCount,
    );
  }
  
  /// Fetch series details with all episodes from CMS API
  /// Returns SeriesEntity with full episode list, or null if fetch fails
  Future<SeriesEntity?> getSeriesWithEpisodes(String seriesId) async {
    try {
      debugPrint('📺 Fetching series $seriesId from CMS API...');
      final response = await _api.get('/v1/cms/series/$seriesId');
      
      final seriesEntity = SeriesEntity.fromJson(response.data);
      debugPrint('✅ Loaded series with ${seriesEntity.episodes.length} episodes');
      return seriesEntity;
    } catch (e) {
      debugPrint('⚠️ Series fetch failed: $e');
      // Return mock series data for demo/offline mode
      return _getMockSeries(seriesId);
    }
  }
  
  /// Get episodes for a series by ID
  Future<List<EpisodeEntity>> getSeriesEpisodes(String seriesId) async {
    final series = await getSeriesWithEpisodes(seriesId);
    return series?.episodes ?? [];
  }
  
  /// Fetch published series for browse pages
  /// Use showOnExplore=true for Explore page, showOnMeditate=true for Meditate page
  Future<List<SeriesEntity>> getPublishedSeries({
    bool showOnExplore = false,
    bool showOnMeditate = false,
  }) async {
    try {
      debugPrint('📺 Fetching published series from CMS API...');
      
      final queryParams = <String, dynamic>{
        'status': 'published',
        if (showOnExplore) 'show_on_explore': true,
        if (showOnMeditate) 'show_on_meditate': true,
      };
      
      final response = await _api.get('/v1/cms/series', queryParameters: queryParams);
      
      final List<dynamic> items = response.data['series'] ?? response.data ?? [];
      final series = items.map((json) => SeriesEntity.fromJson(json)).toList();
      
      debugPrint('✅ Loaded ${series.length} published series');
      return series;
    } catch (e) {
      debugPrint('⚠️ Published series fetch failed: $e');
      return _getMockPublishedSeries();
    }
  }
  
  /// Mock published series for demo/offline mode
  List<SeriesEntity> _getMockPublishedSeries() {
    return [
      SeriesEntity(
        id: 'mock-series-1',
        title: 'Mindfulness Foundations',
        description: 'Begin your journey to mindfulness',
        thumbnailUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=600&h=400&fit=crop',
        episodeCount: 5,
        episodes: [],
        contentType: 'video',
        showOnExplore: true,
        expertName: 'Dr. Sarah Chen',
      ),
      SeriesEntity(
        id: 'mock-series-2',
        title: 'Sleep Better Tonight',
        description: 'Audio meditations for deep sleep',
        thumbnailUrl: 'https://images.unsplash.com/photo-1511295742362-92c96b1cf484?w=600&h=400&fit=crop',
        episodeCount: 8,
        episodes: [],
        contentType: 'audio',
        showOnExplore: true,
        expertName: 'Emma Wilson',
      ),
    ];
  }
  
  /// Mock series data for offline/demo mode
  SeriesEntity? _getMockSeries(String seriesId) {
    return SeriesEntity(
      id: seriesId,
      title: 'Personal Growth Journey',
      description: 'A comprehensive series on personal development',
      thumbnailUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=600&h=400&fit=crop',
      episodeCount: 5,
      episodes: [
        const EpisodeEntity(
          id: 'ep-1',
          title: 'Introduction',
          episodeNumber: 1,
          durationSeconds: 225,
          thumbnailUrl: 'https://picsum.photos/seed/ep1/120/80',
          hlsPlaylistUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
          description: 'Get started with the basics of mindfulness.',
          accessTier: 'free',
        ),
        const EpisodeEntity(
          id: 'ep-2',
          title: 'Getting Started',
          episodeNumber: 2,
          durationSeconds: 320,
          thumbnailUrl: 'https://picsum.photos/seed/ep2/120/80',
          hlsPlaylistUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
          description: 'Learn the fundamental breathing techniques.',
          accessTier: 'premium',
        ),
        const EpisodeEntity(
          id: 'ep-3',
          title: 'Deep Dive',
          episodeNumber: 3,
          durationSeconds: 495,
          thumbnailUrl: 'https://picsum.photos/seed/ep3/120/80',
          hlsPlaylistUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
          description: 'Explore advanced meditation practices.',
          accessTier: 'premium',
        ),
        const EpisodeEntity(
          id: 'ep-4',
          title: 'Advanced Techniques',
          episodeNumber: 4,
          durationSeconds: 390,
          thumbnailUrl: 'https://picsum.photos/seed/ep4/120/80',
          hlsPlaylistUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
          description: 'Master the art of focused attention.',
          accessTier: 'premium',
        ),
        const EpisodeEntity(
          id: 'ep-5',
          title: 'Final Steps',
          episodeNumber: 5,
          durationSeconds: 290,
          thumbnailUrl: 'https://picsum.photos/seed/ep5/120/80',
          hlsPlaylistUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
          description: 'Integration practices for daily life.',
          accessTier: 'premium',
        ),
      ],
    );
  }
  
  /// Mock data for offline/demo mode
  Future<List<VideoEntity>> _getMockVideos(String? category) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final allVideos = [
      const VideoEntity(
        id: '1',
        title: 'Morning Yoga Flow',
        description: 'Start your day with this energizing 15-minute yoga flow',
        thumbnailUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=600&h=400&fit=crop',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
        durationInSeconds: 900,
        category: 'Yoga',
        instructor: 'Sarah Johnson',
        viewCount: 1247,  // Mock view count
      ),
      const VideoEntity(
        id: '2',
        title: '5-Minute Breathing Exercise',
        description: 'Calm your mind with guided breathwork',
        thumbnailUrl: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=600&h=400&fit=crop',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        durationInSeconds: 300,
        category: 'Breathing',
        instructor: 'Dr. Michael Chen',
        viewCount: 892,  // Mock view count
      ),
      const VideoEntity(
        id: '3',
        title: 'Full Body Workout',
        description: '20-minute home workout for all fitness levels',
        thumbnailUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=600&h=400&fit=crop',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
        durationInSeconds: 1200,
        category: 'Exercises',
        instructor: 'Alex Martinez',
        viewCount: 3456,  // Mock view count
      ),
      const VideoEntity(
        id: '4',
        title: 'Mindfulness Meditation',
        description: 'Guided meditation for stress relief and clarity',
        thumbnailUrl: 'https://images.unsplash.com/photo-1499209974431-9dddcece7f88?w=600&h=400&fit=crop',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
        durationInSeconds: 600,
        category: 'Mindfulness',
        instructor: 'Emma Wilson',
        viewCount: 5621,  // Mock view count
      ),
      const VideoEntity(
        id: '5',
        title: 'Evening Stretch Routine',
        description: 'Gentle stretches to wind down your day',
        thumbnailUrl: 'https://images.unsplash.com/photo-1552196563-55cd4e45efb3?w=600&h=400&fit=crop',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
        durationInSeconds: 720,
        category: 'Yoga',
        instructor: 'Sarah Johnson',
        viewCount: 2103,  // Mock view count
      ),
    ];

    if (category == null || category == 'All') {
      return allVideos;
    }

    return allVideos.where((video) => video.category == category).toList();
  }
}
