import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'models/wellness_suggestion_model.dart';
import 'wellness_context.dart';
import 'wellness_rules.dart';

/// Dual-mode wellness advisor:
/// 1. **API mode** — sends WellnessContext to `POST /api/wellness/advisor`
///    and returns AI-generated, deeply personalized suggestions.
/// 2. **Local fallback** — uses [WellnessRules] rule engine when
///    offline or API is unavailable.
class WellnessAdvisorService {
  static WellnessAdvisorService? _instance;
  final ApiClient _api;

  static WellnessAdvisorService get instance {
    _instance ??= WellnessAdvisorService._(ApiClient.instance);
    return _instance!;
  }

  WellnessAdvisorService._(this._api);

  /// Cache: avoid re-fetching constantly
  List<WellnessSuggestion>? _cachedSuggestions;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 15);

  /// Get personalized wellness suggestions.
  /// Tries the AI endpoint first; falls back to local rules.
  Future<List<WellnessSuggestion>> getSuggestions({
    bool forceRefresh = false,
  }) async {
    // Return cached if fresh
    if (!forceRefresh &&
        _cachedSuggestions != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedSuggestions!;
    }

    // Collect the user's wellness context from local data
    final context = await WellnessContextCollector.collect();

    // Try API first
    try {
      final suggestions = await _fetchFromApi(context);
      if (suggestions.isNotEmpty) {
        _cachedSuggestions = suggestions;
        _cacheTime = DateTime.now();
        return suggestions;
      }
    } catch (e) {
      debugPrint('⚠ WellnessAdvisor: API failed, using local rules: $e');
    }

    // Fallback to local rule engine
    final localSuggestions = WellnessRules.evaluate(context);
    _cachedSuggestions = localSuggestions;
    _cacheTime = DateTime.now();
    return localSuggestions;
  }

  /// POST the wellness context to the AI endpoint
  Future<List<WellnessSuggestion>> _fetchFromApi(WellnessContext context) async {
    final response = await _api.post(
      '/api/wellness/advisor',
      data: context.toJson(),
    );

    final data = response.data as Map<String, dynamic>;
    final items = data['suggestions'] as List? ?? [];
    return items
        .map((json) =>
            WellnessSuggestion.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get suggestions filtered for a specific tab context.
  /// e.g., the Nourish tab only shows nutrition/hydration suggestions.
  Future<List<WellnessSuggestion>> getSuggestionsForTab(String tab) async {
    final all = await getSuggestions();

    switch (tab) {
      case 'home':
        return all; // show all on home
      case 'nourish':
        return all
            .where((s) =>
                s.category == 'nutrition' || s.category == 'hydration')
            .toList();
      case 'meditate':
        return all
            .where((s) =>
                s.category == 'breathing' ||
                s.category == 'mental' ||
                s.category == 'sleep')
            .toList();
      case 'learn':
        return all
            .where((s) =>
                s.category == 'recovery' ||
                s.category == 'activity' ||
                s.category == 'celebration')
            .toList();
      default:
        return all;
    }
  }

  /// Invalidate cache (e.g., after logging a workout or meal)
  void invalidateCache() {
    _cachedSuggestions = null;
    _cacheTime = null;
  }
}
