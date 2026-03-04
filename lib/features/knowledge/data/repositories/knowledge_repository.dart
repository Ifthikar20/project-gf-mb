import 'package:flutter/foundation.dart';
import '../models/knowledge_models.dart';
import '../wellness_tips_data.dart';
import '../../../../core/services/personalization_service.dart';

/// Repository for knowledge content — API-first with local fallback
class KnowledgeRepository {
  final PersonalizationService _personalization;

  KnowledgeRepository({PersonalizationService? personalization})
      : _personalization = personalization ?? PersonalizationService.instance;

  /// Fetch articles — tries API first, falls back to local content
  Future<List<Article>> getArticles({int limit = 20}) async {
    try {
      final response = await _personalization.getRecommendations(
        limit: limit,
        contentType: 'article',
      );

      final items = response['results'] as List? ?? response['articles'] as List? ?? [];
      if (items.isNotEmpty) {
        return items
            .map((json) => Article.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('⚠ Failed to fetch articles from API: $e');
    }

    // Fallback to local curated content
    return WellnessTipsData.fallbackArticles;
  }

  /// Get all wellness tips (always local)
  List<WellnessTip> getTips() {
    return WellnessTipsData.allTips;
  }

  /// Get tip of the day
  WellnessTip getTipOfTheDay() {
    return WellnessTipsData.getTipOfTheDay();
  }
}
