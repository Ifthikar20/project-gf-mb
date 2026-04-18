import 'package:dio/dio.dart';
import 'api_client.dart';
import '../config/api_endpoints.dart';
import '../../features/coaching/data/models/coach_program_models.dart';

/// Service for coach-created training programs.
/// Handles browsing, enrollment, calendar, and progress tracking.
class CoachProgramService {
  static CoachProgramService? _instance;
  final ApiClient _api;

  static CoachProgramService get instance {
    _instance ??= CoachProgramService._(ApiClient.instance);
    return _instance!;
  }

  CoachProgramService._(this._api);

  /// Browse all coach programs (optionally filter by coach)
  Future<List<CoachProgram>> getPrograms({
    String? coachId,
    String? category,
    int? durationWeeks,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (coachId != null) queryParams['coach'] = coachId;
      if (category != null) queryParams['category'] = category;
      if (durationWeeks != null) {
        queryParams['duration_weeks'] = durationWeeks;
      }

      final response = await _api.get(
        ApiEndpoints.coachPrograms,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data['success'] == true) {
        return (response.data['programs'] as List? ?? [])
            .map((p) => CoachProgram.fromJson(p))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to load programs');
    }
  }

  /// Get full program detail with training calendar
  Future<CoachProgram> getProgramDetail(String programId) async {
    try {
      final response = await _api.get(
        ApiEndpoints.coachProgramDetail(programId),
      );

      if (response.data['success'] == true) {
        final data = response.data['program'] ?? response.data;
        return CoachProgram.fromJson(data);
      }
      throw CoachProgramException('Program not found');
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to load program');
    }
  }

  /// Enroll the current user in a program
  Future<Map<String, dynamic>> enrollInProgram(String programId) async {
    try {
      final response = await _api.post(
        ApiEndpoints.coachProgramEnroll(programId),
      );

      if (response.data['success'] == true) {
        return {
          'enrolled': true,
          'enrolled_count': response.data['enrolled_count'],
          'message': response.data['message'] ?? 'Enrolled successfully',
        };
      }
      throw CoachProgramException(
        response.data['error']?['message'] ?? 'Enrollment failed',
        code: response.data['error']?['code'],
      );
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to enroll');
    }
  }

  /// Get training calendar for a program
  Future<List<CalendarWeek>> getProgramCalendar(String programId) async {
    try {
      final response = await _api.get(
        ApiEndpoints.coachProgramCalendar(programId),
      );

      if (response.data['success'] == true) {
        return (response.data['calendar'] as List? ?? [])
            .map((w) => CalendarWeek.fromJson(w))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to load calendar');
    }
  }

  /// Mark a calendar day as complete
  Future<void> markDayComplete(String programId, String dayId) async {
    try {
      final response = await _api.post(
        ApiEndpoints.coachProgramDayComplete(programId, dayId),
      );

      if (response.data['success'] != true) {
        throw CoachProgramException(
          response.data['error']?['message'] ?? 'Failed to mark complete',
        );
      }
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to mark day complete');
    }
  }

  /// Get current user's enrolled programs
  Future<List<CoachProgram>> getMyEnrollments() async {
    try {
      final response = await _api.get(ApiEndpoints.coachProgramEnrollments);

      if (response.data['success'] == true) {
        return (response.data['programs'] as List? ?? [])
            .map((p) => CoachProgram.fromJson(p))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to load enrollments');
    }
  }

  CoachProgramException _extractError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      if (data['error'] is Map) {
        return CoachProgramException(
          data['error']['message'] ?? fallback,
          code: data['error']['code'],
        );
      }
      return CoachProgramException(data['message'] ?? fallback);
    }
    return CoachProgramException(fallback);
  }
}

class CoachProgramException implements Exception {
  final String message;
  final String? code;

  CoachProgramException(this.message, {this.code});

  @override
  String toString() => message;
}
