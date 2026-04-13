import 'package:flutter/foundation.dart';
import '../../../core/services/api_client.dart';
import '../domain/entities/journal_entry.dart';
import '../domain/entities/mood_summary.dart';

/// API service for the AI Wellness Journal.
///
/// Uses the singleton [ApiClient] (Dio + DRF Token auth) to communicate
/// with the Django `journal` app endpoints.
class JournalService {
  static JournalService? _instance;
  final ApiClient _api;

  static JournalService get instance {
    _instance ??= JournalService._();
    return _instance!;
  }

  JournalService._() : _api = ApiClient.instance;

  // ── Base path ──
  static const String _base = '/api/journal';

  // ========================================
  // Entries
  // ========================================

  /// Fetch journal entries (paginated, newest first).
  /// Optional [month] in `YYYY-MM` format filters by month.
  Future<List<JournalEntry>> getEntries({
    String? month,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final params = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (month != null) params['month'] = month;

      final response = await _api.get(
        '$_base/entries/',
        queryParameters: params,
      );

      final data = response.data as Map<String, dynamic>;
      final entries = (data['entries'] as List<dynamic>?)
              ?.map((e) =>
                  JournalEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      return entries;
    } catch (e) {
      debugPrint('📓 JournalService.getEntries error: $e');
      rethrow;
    }
  }

  /// Get today's journal entry, or null if none exists.
  Future<JournalEntry?> getTodayEntry() async {
    try {
      final response = await _api.get('$_base/entries/today/');
      return JournalEntry.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      // 404 = no entry for today — that's expected
      if (e.toString().contains('404')) return null;
      debugPrint('📓 JournalService.getTodayEntry error: $e');
      rethrow;
    }
  }

  /// Create a new journal entry for today.
  /// Returns the created entry with AI insight populated.
  Future<JournalEntry> createEntry({
    required String mood,
    int moodIntensity = 3,
    String reflectionText = '',
  }) async {
    try {
      final response = await _api.post(
        '$_base/entries/',
        data: {
          'mood': mood,
          'mood_intensity': moodIntensity,
          'reflection_text': reflectionText,
        },
      );
      return JournalEntry.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('📓 JournalService.createEntry error: $e');
      rethrow;
    }
  }

  /// Update an existing journal entry.
  /// Re-triggers AI insight if mood/text changes.
  Future<JournalEntry> updateEntry({
    required String entryId,
    required String mood,
    int moodIntensity = 3,
    String reflectionText = '',
  }) async {
    try {
      final response = await _api.patch(
        '$_base/entries/$entryId/',
        data: {
          'mood': mood,
          'mood_intensity': moodIntensity,
          'reflection_text': reflectionText,
        },
      );
      return JournalEntry.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('📓 JournalService.updateEntry error: $e');
      rethrow;
    }
  }

  // ========================================
  // Summary & Calendar
  // ========================================

  /// Fetch mood summary (weekly trends, monthly distribution, streaks).
  Future<MoodSummary> getMoodSummary() async {
    try {
      final response = await _api.get('$_base/mood-summary/');
      return MoodSummary.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('📓 JournalService.getMoodSummary error: $e');
      rethrow;
    }
  }

  /// Fetch calendar heatmap data for a month.
  /// [month] in `YYYY-MM` format. Defaults to current month on backend.
  Future<CalendarData> getCalendar({String? month}) async {
    try {
      final params = <String, dynamic>{};
      if (month != null) params['month'] = month;

      final response = await _api.get(
        '$_base/calendar/',
        queryParameters: params,
      );
      return CalendarData.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('📓 JournalService.getCalendar error: $e');
      rethrow;
    }
  }
}
