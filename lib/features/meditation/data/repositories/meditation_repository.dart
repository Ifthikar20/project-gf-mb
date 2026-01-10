import 'package:flutter/foundation.dart';
import '../../../../core/services/api_client.dart';
import '../../domain/entities/meditation_audio.dart';
import '../../domain/entities/meditation_type.dart';

/// Repository for meditation/audio content
/// Fetches audio content from backend API
class MeditationRepository {
  final ApiClient _api;
  
  // Cache for audio content
  List<MeditationAudio>? _cachedAudios;
  List<MeditationType>? _cachedCategories;
  DateTime? _lastFetch;
  
  // Cache duration: 5 minutes
  static const _cacheDuration = Duration(minutes: 5);
  
  MeditationRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  /// Check if cache is still valid
  bool get _isCacheValid {
    if (_lastFetch == null || _cachedAudios == null) return false;
    return DateTime.now().difference(_lastFetch!) < _cacheDuration;
  }
  
  /// Clear cache
  void clearCache() {
    _cachedAudios = null;
    _cachedCategories = null;
    _lastFetch = null;
  }

  // ============================================
  // Audio Content Methods
  // ============================================

  /// Fetch all audio content from API
  /// GET /content/browse?content_type=audio
  Future<List<MeditationAudio>> fetchAllAudios({bool forceRefresh = false}) async {
    // Return cached if valid and not forcing refresh
    if (!forceRefresh && _isCacheValid && _cachedAudios != null) {
      debugPrint('📦 Using cached audio content (${_cachedAudios!.length} items)');
      return _cachedAudios!;
    }
    
    try {
      debugPrint('🎵 Fetching audio content from API...');
      final response = await _api.get('/content/browse', queryParameters: {
        'content_type': 'audio',
        'limit': 100,
      });
      
      // Debug: Log the full response to understand structure
      debugPrint('📋 API Response status: ${response.statusCode}');
      debugPrint('📋 API Response keys: ${response.data?.keys?.toList()}');
      
      final List<dynamic> items = response.data['content'] ?? [];
      debugPrint('📋 Found ${items.length} audio items in response');
      
      if (items.isEmpty) {
        debugPrint('⚠️ No audio content returned from API. Backend may not have audio content_type items.');
        debugPrint('💡 To fix: Add content with content_type="audio" to the backend database.');
        // Return fallback mock data
        return _getFallbackAudios();
      }
      
      final audios = items.map((json) => MeditationAudio.fromJson(json)).toList();
      
      // Cache the results
      _cachedAudios = audios;
      _lastFetch = DateTime.now();
      
      debugPrint('✅ Fetched ${audios.length} audio items from API');
      return audios;
    } catch (e) {
      debugPrint('❌ Failed to fetch audio content: $e');
      // Return cached if available, otherwise empty list
      if (_cachedAudios != null) {
        debugPrint('📦 Returning stale cache due to error');
        return _cachedAudios!;
      }
      // Return mock data as absolute fallback
      debugPrint('⚠️ Using fallback mock data');
      return _getFallbackAudios();
    }
  }

  /// Fetch audio by category
  /// GET /content/browse?content_type=audio&category={slug}
  Future<List<MeditationAudio>> fetchAudiosByCategory(String categorySlug) async {
    try {
      debugPrint('🎵 Fetching audio for category: $categorySlug');
      final response = await _api.get('/content/browse', queryParameters: {
        'content_type': 'audio',
        'category': categorySlug.toLowerCase(),
        'limit': 50,
      });
      
      final List<dynamic> items = response.data['content'] ?? [];
      return items.map((json) => MeditationAudio.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Failed to fetch audio by category: $e');
      // Filter cached data if available
      if (_cachedAudios != null) {
        return _cachedAudios!
            .where((a) => a.category.toLowerCase() == categorySlug.toLowerCase())
            .toList();
      }
      return [];
    }
  }

  /// Fetch featured audio
  /// GET /content/browse?content_type=audio&featured=true
  Future<List<MeditationAudio>> fetchFeaturedAudios({int limit = 5}) async {
    try {
      final response = await _api.get('/content/browse', queryParameters: {
        'content_type': 'audio',
        'featured': true,
        'limit': limit,
      });
      
      final List<dynamic> items = response.data['content'] ?? [];
      return items.map((json) => MeditationAudio.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Failed to fetch featured audio: $e');
      // Return first few from cache
      if (_cachedAudios != null) {
        return _cachedAudios!.where((a) => a.featured).take(limit).toList();
      }
      return [];
    }
  }

  /// Get audio content detail
  /// GET /content/detail/{id}
  Future<MeditationAudio?> fetchAudioById(String id) async {
    try {
      final response = await _api.get('/content/detail/$id');
      return MeditationAudio.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Failed to fetch audio detail: $e');
      // Try cache
      if (_cachedAudios != null) {
        try {
          return _cachedAudios!.firstWhere((a) => a.id == id);
        } catch (_) {}
      }
      return null;
    }
  }

  /// Get streaming URL for audio
  /// GET /api/streaming/content/{id}/stream
  Future<String?> getAudioStreamingUrl(String audioId) async {
    try {
      debugPrint('📡 Fetching streaming URL for audio: $audioId');
      final response = await _api.get('/api/streaming/content/$audioId/stream');
      
      final audioUrl = response.data['audio_url'];
      if (audioUrl != null && audioUrl.toString().isNotEmpty) {
        debugPrint('✅ Got audio URL: $audioUrl');
        return audioUrl.toString();
      }
      
      debugPrint('⚠️ No audio_url in response');
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get streaming URL: $e');
      return null;
    }
  }

  // ============================================
  // Category Methods
  // ============================================

  /// Fetch categories from API
  /// GET /categories (or use default if not available)
  Future<List<MeditationType>> fetchCategories() async {
    if (_cachedCategories != null) {
      return _cachedCategories!;
    }
    
    try {
      final response = await _api.get('/categories', queryParameters: {
        'content_type': 'audio',
      });
      
      final List<dynamic> items = response.data['categories'] ?? response.data ?? [];
      final categories = items.map((json) => MeditationType.fromJson(json)).toList();
      
      _cachedCategories = categories;
      return categories;
    } catch (e) {
      debugPrint('⚠️ Categories API not available, using defaults');
      return MeditationType.defaultCategories;
    }
  }

  /// Get main meditation types (categories) 
  List<MeditationType> getMeditationTypes() {
    return _cachedCategories ?? MeditationType.defaultCategories;
  }

  /// Get mood-based types
  List<MeditationType> getMoodBasedTypes() {
    return MeditationType.moodCategories;
  }

  // ============================================
  // Synchronous Methods (for backward compatibility)
  // ============================================

  /// Get all audio (from cache or fallback)
  /// @deprecated Use fetchAllAudios() instead
  List<MeditationAudio> getAllAudios() {
    return _cachedAudios ?? _getFallbackAudios();
  }

  /// Get audio by category (from cache)
  /// @deprecated Use fetchAudiosByCategory() instead
  List<MeditationAudio> getAudiosByCategory(String category) {
    return getAllAudios()
        .where((audio) => audio.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Get audio by ID (from cache)
  /// @deprecated Use fetchAudioById() instead
  MeditationAudio? getAudioById(String id) {
    try {
      return getAllAudios().firstWhere((audio) => audio.id == id);
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // Fallback Mock Data
  // ============================================

  /// Fallback mock data when API is unavailable
  List<MeditationAudio> _getFallbackAudios() {
    return const [
      MeditationAudio(
        id: '1',
        title: 'Ocean Waves',
        description: 'Gentle waves lapping on the shore',
        durationInSeconds: 600,
        category: 'calm',
        imageUrl: 'https://picsum.photos/seed/ocean/400/400',
      ),
      MeditationAudio(
        id: '2',
        title: 'Rainforest',
        description: 'Tropical rain and wildlife sounds',
        durationInSeconds: 720,
        category: 'calm',
        imageUrl: 'https://picsum.photos/seed/rainforest/400/400',
      ),
      MeditationAudio(
        id: '3',
        title: 'Forest Ambience',
        description: 'Birds chirping and gentle breeze',
        durationInSeconds: 900,
        category: 'focus',
        imageUrl: 'https://picsum.photos/seed/forest/400/400',
      ),
      MeditationAudio(
        id: '4',
        title: 'Deep Breathing',
        description: '4-7-8 breathing technique',
        durationInSeconds: 300,
        category: 'breathe',
        imageUrl: 'https://picsum.photos/seed/breathing/400/400',
      ),
      MeditationAudio(
        id: '5',
        title: 'Sleep Sounds',
        description: 'Calming sounds for better sleep',
        durationInSeconds: 1200,
        category: 'sleep',
        imageUrl: 'https://picsum.photos/seed/sleep/400/400',
      ),
      MeditationAudio(
        id: '6',
        title: 'Morning Energy',
        description: 'Start your day with intention',
        durationInSeconds: 600,
        category: 'morning',
        imageUrl: 'https://picsum.photos/seed/morning/400/400',
      ),
    ];
  }
}
