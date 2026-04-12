import 'package:flutter/foundation.dart';

import '../../../core/services/api_client.dart';
import '../../../core/config/api_endpoints.dart';
import '../domain/entities/journal_entry.dart';
import '../domain/entities/mood_summary.dart';

/// API client for the AI Wellness Journal.
///
/// Uses the singleton ApiClient (same Dio instance with DRF Token auth)
/// matching the pattern used by SearchService, WorkoutBloc, etc.
class JournalService {
  final ApiClient _apiClient;

  JournalService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  /// Fetch journal entries, optionally filtered by month (YYYY-MM).
  Future<List<JournalEntry>> getEntries({String? month, int limit = 20, int offset = 0}) async {
    try {
      final params = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (month != null) params['month'] = month;

      final response = await _apiClient.get(
        '/journal/entries/',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final entries = (data['entries'] as List? ?? [])
            .map((e) => JournalEntry.fromJson(e))
            .toList();
        return entries;
      }
      return [];
    } catch (e) {
      debugPrint('JournalService.getEntries error: $e');
      return [];
    }
  }

  /// Get today's journal entry, or null if none exists.
  Future<JournalEntry?> getTodayEntry() async {
    try {
      final response = await _apiClient.get('/journal/entries/today/');
      if (response.statusCode == 200) {
        return JournalEntry.fromJson(response.data);
      }
      return null;
    } catch (e) {
      // 404 is expected when no entry exists for today
      debugPrint('JournalService.getTodayEntry: $e');
      return null;
    }
  }

  /// Create a new journal entry for today.
  /// Returns the created entry with AI-generated insight.
  Future<JournalEntry?> createEntry({
    required String mood,
    int moodIntensity = 3,
    String reflectionText = '',
  }) async {
    try {
      final response = await _apiClient.post(
        '/journal/entries/',
        data: {
          'mood': mood,
          'mood_intensity': moodIntensity,
          'reflection_text': reflectionText,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return JournalEntry.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('JournalService.createEntry error: $e');
      return null;
    }
  }

  /// Update an existing journal entry.
  Future<JournalEntry?> updateEntry({
    required String entryId,
    required String mood,
    int moodIntensity = 3,
    String reflectionText = '',
  }) async {
    try {
      final response = await _apiClient.patch(
        '/journal/entries/$entryId/',
        data: {
          'mood': mood,
          'mood_intensity': moodIntensity,
          'reflection_text': reflectionText,
        },
      );

      if (response.statusCode == 200) {
        return JournalEntry.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('JournalService.updateEntry error: $e');
      return null;
    }
  }

  /// Get mood summary (weekly moods, monthly distribution, streak).
  Future<MoodSummary?> getMoodSummary() async {
    try {
      final response = await _apiClient.get('/journal/mood-summary/');
      if (response.statusCode == 200) {
        return MoodSummary.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('JournalService.getMoodSummary error: $e');
      return null;
    }
  }

  /// Get calendar heatmap data for a specific month.
  Future<CalendarMonth?> getCalendarData({String? month}) async {
    try {
      final params = <String, dynamic>{};
      if (month != null) params['month'] = month;

      final response = await _apiClient.get(
        '/journal/calendar/',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        return CalendarMonth.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('JournalService.getCalendarData error: $e');
      return null;
    }
  }
}
