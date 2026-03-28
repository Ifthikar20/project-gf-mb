import 'package:dio/dio.dart';
import 'api_client.dart';
import '../config/api_endpoints.dart';

class Coach {
  final String id;
  final CoachExpert expert;
  final String hourlyRate;
  final String? discountedRate;
  final int? premiumDiscountPercent;
  final String bio;
  final List<String> specialties;
  final bool isAcceptingClients;
  final bool hasCalcom;

  Coach({
    required this.id,
    required this.expert,
    required this.hourlyRate,
    this.discountedRate,
    this.premiumDiscountPercent,
    required this.bio,
    required this.specialties,
    required this.isAcceptingClients,
    required this.hasCalcom,
  });

  factory Coach.fromJson(Map<String, dynamic> json) {
    return Coach(
      id: json['id'] ?? '',
      expert: CoachExpert.fromJson(json['expert'] ?? {}),
      hourlyRate: json['hourly_rate'] ?? '0.00',
      discountedRate: json['discounted_rate'],
      premiumDiscountPercent: json['premium_discount_percent'],
      bio: json['bio'] ?? '',
      specialties: (json['specialties'] as List?)
              ?.map((s) => s.toString())
              .toList() ??
          [],
      isAcceptingClients: json['is_accepting_clients'] ?? false,
      hasCalcom: json['has_calcom'] ?? false,
    );
  }
}

class CoachExpert {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? title;

  CoachExpert({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.title,
  });

  factory CoachExpert.fromJson(Map<String, dynamic> json) {
    return CoachExpert(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      avatarUrl: json['avatar_url'],
      title: json['title'],
    );
  }
}

class CoachingSession {
  final String id;
  final CoachExpert? coach;
  final String? clientId;
  final String scheduledAt;
  final int durationMinutes;
  final String status;
  final String amount;
  final bool discountApplied;
  final String? notes;
  final String? createdAt;
  final String? roomUrl;

  CoachingSession({
    required this.id,
    this.coach,
    this.clientId,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.status,
    required this.amount,
    this.discountApplied = false,
    this.notes,
    this.createdAt,
    this.roomUrl,
  });

  factory CoachingSession.fromJson(Map<String, dynamic> json) {
    return CoachingSession(
      id: json['id'] ?? '',
      coach: json['coach'] != null ? CoachExpert.fromJson(json['coach']) : null,
      clientId: json['client_id'],
      scheduledAt: json['scheduled_at'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 60,
      status: json['status'] ?? 'pending_payment',
      amount: json['amount'] ?? '0.00',
      discountApplied: json['discount_applied'] ?? false,
      notes: json['notes'],
      createdAt: json['created_at'],
      roomUrl: json['room_url'],
    );
  }

  DateTime? get scheduledDateTime => DateTime.tryParse(scheduledAt);

  bool get isUpcoming =>
      status == 'pending_payment' ||
      status == 'confirmed' ||
      status == 'in_progress';

  bool get isPast =>
      status == 'completed' ||
      status == 'cancelled_by_client' ||
      status == 'cancelled_by_coach' ||
      status == 'no_show';

  String get statusLabel {
    switch (status) {
      case 'pending_payment':
        return 'Payment Needed';
      case 'confirmed':
        return 'Confirmed';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled_by_client':
        return 'Cancelled';
      case 'cancelled_by_coach':
        return 'Cancelled by Coach';
      case 'no_show':
        return 'Missed';
      default:
        return status;
    }
  }
}

class CoachingService {
  static CoachingService? _instance;
  final ApiClient _api;

  static CoachingService get instance {
    _instance ??= CoachingService._(ApiClient.instance);
    return _instance!;
  }

  CoachingService._(this._api);

  /// Browse coaches
  Future<List<Coach>> getCoaches({
    String? specialty,
    double? maxPrice,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (specialty != null) queryParams['specialty'] = specialty;
      if (maxPrice != null) queryParams['max_price'] = maxPrice;

      final response = await _api.get(
        ApiEndpoints.coaches,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data['success'] == true) {
        return (response.data['coaches'] as List? ?? [])
            .map((c) => Coach.fromJson(c))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to load coaches');
    }
  }

  /// Get coach detail
  Future<Coach> getCoachDetail(String coachId) async {
    try {
      final response = await _api.get(ApiEndpoints.coachDetail(coachId));

      if (response.data['success'] == true) {
        final data = response.data['coach'] ?? response.data;
        return Coach.fromJson(data);
      }
      throw CoachingException('Coach not found');
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to load coach');
    }
  }

  /// Get Cal.com booking URL for a coach
  Future<Map<String, dynamic>> getBookingUrl(String coachId) async {
    try {
      final response = await _api.get(ApiEndpoints.coachBookingUrl(coachId));

      if (response.data['success'] == true) {
        return {
          'booking_url': response.data['booking_url'],
          'embed_url': response.data['embed_url'],
          'coach': response.data['coach'],
        };
      }
      throw CoachingException(
        response.data['error']?['message'] ?? 'Failed to get booking URL',
        code: response.data['error']?['code'],
      );
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to get booking URL');
    }
  }

  /// Get my coaching sessions
  Future<List<CoachingSession>> getSessions({String role = 'client'}) async {
    try {
      final response = await _api.get(
        ApiEndpoints.coachingSessions,
        queryParameters: {'role': role},
      );

      if (response.data['success'] == true) {
        return (response.data['sessions'] as List? ?? [])
            .map((s) => CoachingSession.fromJson(s))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to load sessions');
    }
  }

  /// Join a video session — returns LiveKit token
  Future<Map<String, dynamic>> joinSession(String sessionId) async {
    try {
      final response = await _api.post(
        ApiEndpoints.coachingSessionJoin(sessionId),
      );

      if (response.data['success'] == true) {
        return {
          'token': response.data['token'],
          'livekit_url': response.data['livekit_url'],
          'room_name': response.data['room_name'],
          'role': response.data['role'],
          'session': response.data['session'],
        };
      }
      throw CoachingException(
        response.data['error']?['message'] ?? 'Failed to join session',
        code: response.data['error']?['code'],
      );
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to join session');
    }
  }

  /// Cancel a coaching session
  Future<Map<String, dynamic>> cancelSession(
    String sessionId, {
    String? reason,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.coachingSessionCancel(sessionId),
        data: reason != null ? {'reason': reason} : null,
      );

      if (response.data['success'] == true) {
        return {
          'status': response.data['status'],
          'refund_amount': response.data['refund_amount'],
          'hours_until_session': response.data['hours_until_session'],
        };
      }
      throw CoachingException(
        response.data['error']?['message'] ?? 'Failed to cancel session',
        code: response.data['error']?['code'],
      );
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to cancel session');
    }
  }

  CoachingException _extractError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      if (data['error'] is Map) {
        return CoachingException(
          data['error']['message'] ?? fallback,
          code: data['error']['code'],
        );
      }
      return CoachingException(data['message'] ?? fallback);
    }
    return CoachingException(fallback);
  }
}

class CoachingException implements Exception {
  final String message;
  final String? code;

  CoachingException(this.message, {this.code});

  @override
  String toString() => message;
}
