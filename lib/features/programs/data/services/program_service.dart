import 'package:dio/dio.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/config/api_endpoints.dart';
import '../models/program_model.dart';
import '../models/enrollment_model.dart';

/// Service for browsing coach-led programs, enrolling, and tracking progress.
/// Combines patterns from MarketplaceService (browse/purchase) and
/// WorkoutPlanService (schedule/completion) into one unified service.
class ProgramService {
  static ProgramService? _instance;
  final ApiClient _api;

  static ProgramService get instance {
    _instance ??= ProgramService._(ApiClient.instance);
    return _instance!;
  }

  ProgramService._(this._api);

  // ─────────────────────────────────────
  // Browse Programs (Public)
  // ─────────────────────────────────────

  /// Browse available programs with optional filters.
  Future<List<Program>> getPrograms({
    String? categoryId,
    String? coachId,
    String? search,
    String? difficulty,
    int? durationWeeks,
    bool? freeOnly,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (categoryId != null) queryParams['category'] = categoryId;
      if (coachId != null) queryParams['coach'] = coachId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (difficulty != null) queryParams['difficulty'] = difficulty;
      if (durationWeeks != null) queryParams['duration_weeks'] = durationWeeks;
      if (freeOnly == true) queryParams['free'] = true;

      final response = await _api.get(
        ApiEndpoints.programsBrowse,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data['success'] == true) {
        return (response.data['programs'] as List? ?? [])
            .map((p) => Program.fromJson(p))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to load programs');
    }
  }

  /// Get full program details including schedule preview.
  Future<Program> getProgramDetail(String programId) async {
    try {
      final response = await _api.get(
        ApiEndpoints.programDetail(programId),
      );

      if (response.data['success'] == true) {
        final data = response.data['program'] ?? response.data;
        return Program.fromJson(data);
      }
      throw ProgramException('Program not found');
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to load program');
    }
  }

  // ─────────────────────────────────────
  // Enrollment
  // ─────────────────────────────────────

  /// Enroll in a program.
  /// For free programs: immediately enrolls and returns enrollment ID.
  /// For paid programs: returns Stripe client_secret for payment.
  Future<Map<String, dynamic>> enrollInProgram(String programId) async {
    try {
      final response = await _api.post(
        ApiEndpoints.programEnroll(programId),
      );

      if (response.data['success'] == true) {
        return {
          'enrolled': response.data['enrolled'] ?? false,
          'enrollment_id': response.data['enrollment_id'],
          'client_secret': response.data['client_secret'],
          'amount': response.data['amount'],
          'currency': response.data['currency'],
          'is_free': response.data['is_free'] ?? false,
        };
      }
      throw ProgramException(
        response.data['error']?['message'] ?? 'Enrollment failed',
        code: response.data['error']?['code'],
      );
    } on DioException catch (e) {
      throw _extractError(e, 'Enrollment failed');
    }
  }

  /// Get all of the user's enrollments.
  Future<List<Enrollment>> getMyEnrollments({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;

      final response = await _api.get(
        ApiEndpoints.myEnrollments,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data['success'] == true) {
        return (response.data['enrollments'] as List? ?? [])
            .map((e) => Enrollment.fromJson(e))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to load enrollments');
    }
  }

  /// Get a specific enrollment with full schedule and content.
  Future<Enrollment> getEnrollmentDetail(String enrollmentId) async {
    try {
      final response = await _api.get(
        ApiEndpoints.enrollmentDetail(enrollmentId),
      );

      if (response.data['success'] == true) {
        return Enrollment.fromJson(
            response.data['enrollment'] ?? response.data);
      }
      throw ProgramException('Enrollment not found');
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to load enrollment');
    }
  }

  /// Get the full schedule for an enrollment.
  Future<List<ProgramScheduleDay>> getEnrollmentSchedule(
      String enrollmentId) async {
    try {
      final response = await _api.get(
        ApiEndpoints.enrollmentSchedule(enrollmentId),
      );

      if (response.data['success'] == true) {
        return (response.data['schedule'] as List? ?? [])
            .map((d) => ProgramScheduleDay.fromJson(d))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to load schedule');
    }
  }

  /// Get all content items for an enrollment.
  Future<List<ProgramContentItem>> getEnrollmentContent(
      String enrollmentId) async {
    try {
      final response = await _api.get(
        ApiEndpoints.enrollmentContent(enrollmentId),
      );

      if (response.data['success'] == true) {
        return (response.data['content_items'] as List? ?? [])
            .map((c) => ProgramContentItem.fromJson(c))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to load content');
    }
  }

  /// Mark a schedule day as completed.
  Future<void> completeScheduleDay(
    String enrollmentId,
    String dayId, {
    String? watchHistoryId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (watchHistoryId != null) body['watch_history_id'] = watchHistoryId;
      await _api.post(
        ApiEndpoints.enrollmentCompleteDay(enrollmentId, dayId),
        data: body,
      );
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to mark day complete');
    }
  }

  // ─────────────────────────────────────
  // Error handling
  // ─────────────────────────────────────

  ProgramException _extractError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final err = data['error'];
      if (err is Map) {
        return ProgramException(
          err['message'] ?? fallback,
          code: err['code'],
        );
      }
      return ProgramException(data['message']?.toString() ?? fallback);
    }
    if (e.response?.statusCode == 403) {
      return const ProgramException(
        'This feature requires a Premium subscription.',
        code: 'PREMIUM_REQUIRED',
      );
    }
    return ProgramException(fallback);
  }
}

class ProgramException implements Exception {
  final String message;
  final String? code;

  const ProgramException(this.message, {this.code});

  bool get isPremiumRequired => code == 'PREMIUM_REQUIRED';

  @override
  String toString() => message;
}
