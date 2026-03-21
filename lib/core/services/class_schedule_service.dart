import 'package:flutter/foundation.dart';
import '../../core/services/api_client.dart';
import '../../features/explore/data/models/scheduled_class_model.dart';

/// Service for class scheduling API calls.
/// Falls back gracefully if backend hasn't deployed the classes app yet.
class ClassScheduleService {
  final ApiClient _api;

  ClassScheduleService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  /// Fetch classes for a specific date.
  /// Returns empty list if API not available (404).
  Future<List<ScheduledClassModel>> getClassesForDate(DateTime date) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await _api.get(
        '/api/classes/',
        queryParameters: {'date': dateStr},
      );
      final data = response.data as Map<String, dynamic>?;
      if (data == null) return [];
      final list = data['classes'] as List<dynamic>? ?? [];
      return list
          .map((e) =>
              ScheduledClassModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('📅 Classes API unavailable: $e');
      return [];
    }
  }

  /// Set a reminder for a class.
  /// Returns the reminder ID on success, null on failure.
  Future<String?> setReminder({
    required String classId,
    int remindMinutesBefore = 15,
    String? fcmToken,
  }) async {
    try {
      final response = await _api.post(
        '/api/classes/reminders/',
        data: {
          'class_id': classId,
          'remind_minutes_before': remindMinutesBefore,
          if (fcmToken != null) 'fcm_token': fcmToken,
        },
      );
      final data = response.data as Map<String, dynamic>?;
      return data?['id'] as String?;
    } catch (e) {
      debugPrint('📅 Set reminder failed: $e');
      return null;
    }
  }

  /// Cancel a reminder.
  Future<bool> cancelReminder(String reminderId) async {
    try {
      await _api.delete('/api/classes/reminders/$reminderId/');
      return true;
    } catch (e) {
      debugPrint('📅 Cancel reminder failed: $e');
      return false;
    }
  }

  /// List user's active reminders.
  Future<List<Map<String, dynamic>>> getReminders() async {
    try {
      final response = await _api.get('/api/classes/reminders/');
      final data = response.data as Map<String, dynamic>?;
      if (data == null) return [];
      return (data['reminders'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];
    } catch (e) {
      debugPrint('📅 Get reminders failed: $e');
      return [];
    }
  }
}
