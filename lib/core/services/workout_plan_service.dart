import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../config/api_endpoints.dart';

// ─────────────────────────────────────
// Models
// ─────────────────────────────────────

class PlanCoach {
  final String id;
  final String name;
  final String? avatarUrl;

  const PlanCoach({required this.id, required this.name, this.avatarUrl});

  factory PlanCoach.fromJson(Map<String, dynamic> json) => PlanCoach(
        id: json['id'] ?? '',
        name: json['name'] ?? 'Coach',
        avatarUrl: json['avatar_url'],
      );
}

class PlanContent {
  final String id;
  final String title;
  final String? thumbnailUrl;
  final int durationSeconds;

  const PlanContent({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    required this.durationSeconds,
  });

  factory PlanContent.fromJson(Map<String, dynamic> json) => PlanContent(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        thumbnailUrl: json['thumbnail_url'],
        durationSeconds: json['duration_seconds'] ?? 0,
      );

  int get durationMinutes => (durationSeconds / 60).round();
}

class PlanDay {
  final String id;
  final int weekNumber;
  final int dayOfWeek;
  final String dayName;
  final PlanContent? content;
  final String? coachNotes;
  final bool isCompleted;
  final String? completedAt;

  const PlanDay({
    required this.id,
    required this.weekNumber,
    required this.dayOfWeek,
    required this.dayName,
    this.content,
    this.coachNotes,
    required this.isCompleted,
    this.completedAt,
  });

  factory PlanDay.fromJson(Map<String, dynamic> json) => PlanDay(
        id: json['id'] ?? '',
        weekNumber: json['week_number'] ?? 1,
        dayOfWeek: json['day_of_week'] ?? 0,
        dayName: json['day_name'] ?? '',
        content: json['content'] != null
            ? PlanContent.fromJson(json['content'] as Map<String, dynamic>)
            : null,
        coachNotes: json['coach_notes'],
        isCompleted: json['is_completed'] ?? false,
        completedAt: json['completed_at'],
      );
}

class PlanProgress {
  final int totalDays;
  final int completedDays;
  final int percent;

  const PlanProgress({
    required this.totalDays,
    required this.completedDays,
    required this.percent,
  });

  factory PlanProgress.fromJson(Map<String, dynamic> json) => PlanProgress(
        totalDays: json['total_days'] ?? 0,
        completedDays: json['completed_days'] ?? 0,
        percent: json['percent'] ?? 0,
      );
}

class WorkoutPlan {
  final String id;
  final String title;
  final String description;
  final int durationWeeks;
  final String? notesForClient;
  final PlanCoach coach;
  final List<PlanDay> days;
  final PlanProgress progress;
  final String createdAt;

  const WorkoutPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.durationWeeks,
    this.notesForClient,
    required this.coach,
    required this.days,
    required this.progress,
    required this.createdAt,
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) => WorkoutPlan(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        durationWeeks: json['duration_weeks'] ?? 1,
        notesForClient: json['notes_for_client'],
        coach: PlanCoach.fromJson(json['coach'] ?? {}),
        days: (json['days'] as List? ?? [])
            .map((d) => PlanDay.fromJson(d as Map<String, dynamic>))
            .toList(),
        progress: PlanProgress.fromJson(json['progress'] ?? {}),
        createdAt: json['created_at'] ?? '',
      );

  /// Days grouped by week number (sorted).
  Map<int, List<PlanDay>> get daysByWeek {
    final map = <int, List<PlanDay>>{};
    for (final day in days) {
      map.putIfAbsent(day.weekNumber, () => []).add(day);
    }
    return map;
  }
}

class ConsultationStatus {
  final bool eligible;
  final bool usedThisMonth;
  final int durationMinutes;
  final String month;
  final String message;

  const ConsultationStatus({
    required this.eligible,
    required this.usedThisMonth,
    required this.durationMinutes,
    required this.month,
    required this.message,
  });

  factory ConsultationStatus.fromJson(Map<String, dynamic> json) =>
      ConsultationStatus(
        eligible: json['eligible'] ?? false,
        usedThisMonth: json['used_this_month'] ?? false,
        durationMinutes: json['duration_minutes'] ?? 20,
        month: json['month'] ?? '',
        message: json['message'] ?? '',
      );
}

// ─────────────────────────────────────
// Service
// ─────────────────────────────────────

/// Service for Premium workout plan, free consultation, and food-sharing APIs.
class WorkoutPlanService {
  static WorkoutPlanService? _instance;
  final ApiClient _api;

  static WorkoutPlanService get instance {
    _instance ??= WorkoutPlanService._(ApiClient.instance);
    return _instance!;
  }

  WorkoutPlanService._(this._api);

  /// Fetch the user's active workout plan.
  /// Returns `null` if no plan exists yet.
  Future<WorkoutPlan?> getMyPlan() async {
    try {
      final response = await _api.get(ApiEndpoints.myWorkoutPlan);
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['plan'] != null) {
        return WorkoutPlan.fromJson(data['plan'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to load workout plan');
    }
  }

  /// Mark a plan day as complete. Pass [watchHistoryId] if available.
  Future<void> completePlanDay(String dayId, {String? watchHistoryId}) async {
    try {
      final body = <String, dynamic>{};
      if (watchHistoryId != null) body['watch_history_id'] = watchHistoryId;
      await _api.post(ApiEndpoints.completePlanDay(dayId), data: body);
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to mark workout complete');
    }
  }

  /// Check if the user is eligible for the free monthly consultation.
  Future<ConsultationStatus> getConsultationStatus() async {
    try {
      final response = await _api.get(ApiEndpoints.consultationEligibility);
      final data = response.data as Map<String, dynamic>;
      return ConsultationStatus.fromJson(
          data['consultation'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to check consultation eligibility');
    }
  }

  /// Book the free consultation with a coach.
  Future<Map<String, dynamic>> bookConsultation({
    required String coachId,
    required DateTime scheduledAt,
  }) async {
    try {
      final response = await _api.post(ApiEndpoints.bookConsultation, data: {
        'coach_id': coachId,
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      });
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) return data;
      throw WorkoutPlanException(
        data['error']?['message'] ?? 'Booking failed',
        code: data['error']?['code'],
      );
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to book consultation');
    }
  }

  /// Toggle food data sharing with coach.
  Future<bool> setFoodSharing({required bool enabled}) async {
    try {
      final response = await _api.patch(ApiEndpoints.foodSharing, data: {
        'enabled': enabled,
      });
      final data = response.data as Map<String, dynamic>;
      return data['share_food_data_with_coach'] as bool? ?? enabled;
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to update food sharing setting');
    }
  }

  WorkoutPlanException _extractError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final err = data['error'];
      if (err is Map) {
        return WorkoutPlanException(err['message'] ?? fallback,
            code: err['code']);
      }
      return WorkoutPlanException(data['message']?.toString() ?? fallback);
    }
    if (e.response?.statusCode == 403) {
      return const WorkoutPlanException(
        'This feature requires a Premium subscription.',
        code: 'PREMIUM_REQUIRED',
      );
    }
    return WorkoutPlanException(fallback);
  }
}

class WorkoutPlanException implements Exception {
  final String message;
  final String? code;

  const WorkoutPlanException(this.message, {this.code});

  bool get isPremiumRequired => code == 'PREMIUM_REQUIRED';

  @override
  String toString() => message;
}
