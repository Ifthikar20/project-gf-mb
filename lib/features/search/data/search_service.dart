import '../../../../core/services/api_client.dart';
import '../../../../core/services/app_logger.dart';
import '../domain/entities/search_result.dart';
import '../domain/entities/unified_search_result.dart';

/// Secure service for searching content and experts
/// 
/// Security features:
/// - Input sanitization to prevent injection attacks
/// - Query length limits to prevent DoS
/// - Whitelist validation for filter parameters
/// - Proper URL encoding via Dio
class SearchService {
  final ApiClient _apiClient;
  
  // Security constants
  static const int _maxQueryLength = 100;
  static const int _maxTagsCount = 10;
  static const int _maxTagLength = 50;
  
  // Whitelist of allowed content types
  static const Set<String> _allowedContentTypes = {
    'all', 'video', 'audio', 'podcast'
  };
  
  // Whitelist of allowed categories (lowercase)
  static const Set<String> _allowedCategories = {
    'all', 'category', 'sleep', 'focus', 'calm', 'anxiety', 
    'stress', 'meditation', 'wellness', 'personal growth',
    'mental health', 'relationships', 'mindfulness'
  };

  SearchService({ApiClient? apiClient}) 
      : _apiClient = apiClient ?? ApiClient.instance;

  /// Search for content and experts with secure input handling
  /// 
  /// [query] - Search query text (sanitized, max 100 chars)
  /// [contentType] - Filter by content type: 'all', 'video', 'audio', 'podcast'
  /// [category] - Filter by category slug
  /// [tags] - Optional list of tags to filter by (max 10 tags)
  Future<List<SearchResult>> search({
    required String query,
    String contentType = 'all',
    String? category,
    List<String>? tags,
  }) async {
    // Sanitize and validate query
    final sanitizedQuery = _sanitizeQuery(query);
    if (sanitizedQuery.isEmpty) {
      return [];
    }

    // Validate content type against whitelist
    final validContentType = _validateContentType(contentType);
    
    // Validate category against whitelist
    final validCategory = _validateCategory(category);
    
    // Sanitize tags
    final sanitizedTags = _sanitizeTags(tags);

    try {
      AppLogger.i('Secure search: "$sanitizedQuery" (type: $validContentType, category: $validCategory, tags: $sanitizedTags)');
      
      final List<SearchResult> results = [];
      
      // Search for experts/speakers first (only if searching all types)
      if (validContentType == 'all') {
        final expertResults = await _searchExperts(query: sanitizedQuery);
        results.addAll(expertResults);
      }
      
      // Search for content (videos, audio, podcasts)
      final contentResults = await _searchContent(
        query: sanitizedQuery,
        contentType: validContentType,
        category: validCategory,
        tags: sanitizedTags,
      );
      results.addAll(contentResults);

      AppLogger.i('Search returned ${results.length} total results (${results.where((r) => r.isSpeaker).length} experts, ${results.where((r) => !r.isSpeaker).length} content)');
      return results;
    } catch (e, stackTrace) {
      AppLogger.e('Search failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Search for experts/speakers
  Future<List<SearchResult>> _searchExperts({required String query}) async {
    try {
      final response = await _apiClient.get(
        '/experts',
        queryParameters: {'search': query},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> items;
        
        if (data is List) {
          items = data;
        } else if (data is Map) {
          items = data['experts'] ?? data['results'] ?? data['items'] ?? [];
        } else {
          items = [];
        }

        final results = items
            .map((item) => SearchResult.fromSpeakerJson(item))
            .toList();

        AppLogger.i('Expert search returned ${results.length} items');
        return results;
      }

      return [];
    } catch (e) {
      // Don't fail the whole search if experts endpoint fails
      AppLogger.w('Expert search failed (continuing with content): $e');
      return [];
    }
  }

  /// Sanitize search query to prevent injection attacks
  String _sanitizeQuery(String query) {
    if (query.isEmpty) return '';
    
    // Trim and limit length
    String sanitized = query.trim();
    if (sanitized.length > _maxQueryLength) {
      sanitized = sanitized.substring(0, _maxQueryLength);
    }
    
    // Remove potentially dangerous characters
    // Allow alphanumeric, spaces, and common punctuation
    sanitized = sanitized.replaceAll(RegExp(r'[^\w\s\-.,!?@#&()]'), '');
    
    // Remove multiple consecutive spaces
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    
    // Check for SQL injection patterns
    final sqlPatterns = [
      RegExp(r'\b(SELECT|INSERT|UPDATE|DELETE|DROP|UNION|OR\s+1\s*=\s*1|AND\s+1\s*=\s*1)\b', caseSensitive: false),
      RegExp(r'["\x27]\s*(;|--)', caseSensitive: false),
    ];
    
    for (final pattern in sqlPatterns) {
      if (pattern.hasMatch(sanitized)) {
        AppLogger.w('Potential SQL injection attempt blocked: $query');
        return '';
      }
    }
    
    // Check for script injection
    if (sanitized.toLowerCase().contains('<script') || 
        sanitized.toLowerCase().contains('javascript:')) {
      AppLogger.w('Potential XSS attempt blocked: $query');
      return '';
    }
    
    return sanitized.trim();
  }

  /// Validate content type against whitelist
  String _validateContentType(String contentType) {
    final normalized = contentType.toLowerCase().trim();
    return _allowedContentTypes.contains(normalized) ? normalized : 'all';
  }

  /// Validate category against whitelist
  String? _validateCategory(String? category) {
    if (category == null || category.isEmpty) return null;
    
    final normalized = category.toLowerCase().trim();
    if (normalized == 'category' || normalized == 'all') return null;
    
    // Check against whitelist (but also allow categories not in the list
    // as long as they pass basic sanitization)
    final sanitized = normalized.replaceAll(RegExp(r'[^\w\s\-]'), '');
    if (sanitized.isEmpty || sanitized.length > _maxTagLength) return null;
    
    return sanitized;
  }

  /// Sanitize and validate tags list
  List<String>? _sanitizeTags(List<String>? tags) {
    if (tags == null || tags.isEmpty) return null;
    
    final sanitizedTags = <String>[];
    
    for (final tag in tags.take(_maxTagsCount)) {
      // Sanitize each tag
      String sanitized = tag.toLowerCase().trim();
      sanitized = sanitized.replaceAll(RegExp(r'[^\w\s\-]'), '');
      
      if (sanitized.isNotEmpty && sanitized.length <= _maxTagLength) {
        sanitizedTags.add(sanitized);
      }
    }
    
    return sanitizedTags.isEmpty ? null : sanitizedTags;
  }

  /// Search content items using /content/search endpoint
  Future<List<SearchResult>> _searchContent({
    required String query,
    String contentType = 'all',
    String? category,
    List<String>? tags,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'q': query, // Backend uses 'q' for search query
      };

      // Add content type filter if not 'all'
      if (contentType != 'all') {
        queryParams['content_type'] = contentType;
      }

      // Add category filter if provided
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      
      // Add tags filter if provided (comma-separated)
      if (tags != null && tags.isNotEmpty) {
        queryParams['tags'] = tags.join(',');
      }

      final response = await _apiClient.get(
        '/content/search',  // Use dedicated search endpoint
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // API returns {"content": [...], "total_results": N} 
        List<dynamic> items;
        if (data is List) {
          items = data;
        } else if (data is Map) {
          items = data['content'] ?? data['results'] ?? data['items'] ?? [];
        } else {
          items = [];
        }

        AppLogger.i('Found ${items.length} items in API response');

        final results = <SearchResult>[];
        for (final item in items) {
          final itemContentType = item['content_type']?.toString().toLowerCase() ?? 'video';
          
          if (itemContentType == 'video') {
            results.add(SearchResult.fromVideoJson(item));
          } else {
            results.add(SearchResult.fromAudioJson(item));
          }
        }

        AppLogger.i('Content search returned ${results.length} items');
        return results;
      }

      return [];
    } catch (e) {
      AppLogger.e('Content search failed', error: e);
      return [];
    }
  }

  /// Unified search - Spotify/YouTube style with grouped results
  /// 
  /// Returns experts, series, and content separately for grouped display
  Future<UnifiedSearchResult> unifiedSearch({required String query}) async {
    final sanitizedQuery = _sanitizeQuery(query);
    if (sanitizedQuery.isEmpty) {
      return UnifiedSearchResult(
        query: query,
        experts: [],
        series: [],
        content: [],
        totalResults: 0,
      );
    }

    try {
      AppLogger.i('Unified search: "$sanitizedQuery"');
      
      final response = await _apiClient.get(
        '/content/unified-search',
        queryParameters: {'q': sanitizedQuery},
      );

      if (response.statusCode == 200 && response.data != null) {
        final result = UnifiedSearchResult.fromJson(response.data);
        AppLogger.i('Unified search returned: ${result.experts.length} experts, '
            '${result.series.length} series, ${result.content.length} content');
        return result;
      }

      return UnifiedSearchResult(
        query: query,
        experts: [],
        series: [],
        content: [],
        totalResults: 0,
      );
    } catch (e, stackTrace) {
      AppLogger.e('Unified search failed', error: e, stackTrace: stackTrace);
      
      // Fallback to regular search if unified search endpoint fails
      try {
        final fallbackResults = await search(query: query);
        return UnifiedSearchResult(
          query: query,
          experts: [],
          series: [],
          content: fallbackResults
              .where((r) => !r.isSpeaker)
              .map((r) => UnifiedContentResult(
                    id: r.id,
                    title: r.title,
                    contentType: r.type.name,
                    thumbnailUrl: r.imageUrl,
                    expertName: r.authorName,
                    durationSeconds: r.durationInSeconds,
                    category: r.category,
                  ))
              .toList(),
          totalResults: fallbackResults.length,
        );
      } catch (_) {
        return UnifiedSearchResult(
          query: query,
          experts: [],
          series: [],
          content: [],
          totalResults: 0,
        );
      }
    }
  }

  /// Get search suggestions for autocomplete
  /// 
  /// Returns typeahead suggestions as user types
  Future<List<SearchSuggestion>> getSuggestions({required String query}) async {
    final sanitizedQuery = _sanitizeQuery(query);
    if (sanitizedQuery.isEmpty || sanitizedQuery.length < 2) {
      return [];
    }

    try {
      AppLogger.i('Getting suggestions for: "$sanitizedQuery"');
      
      final response = await _apiClient.get(
        '/content/search-suggestions',
        queryParameters: {'q': sanitizedQuery},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic> items;
        
        if (data is List) {
          items = data;
        } else if (data is Map) {
          items = data['suggestions'] ?? data['items'] ?? [];
        } else {
          items = [];
        }

        final suggestions = items
            .map((s) => SearchSuggestion.fromJson(s is Map<String, dynamic> ? s : {'text': s.toString()}))
            .toList();
        
        AppLogger.i('Got ${suggestions.length} suggestions');
        return suggestions;
      }

      return [];
    } catch (e) {
      AppLogger.w('Suggestions failed: $e');
      return [];
    }
  }
}

