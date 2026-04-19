import 'package:dio/dio.dart';
import 'api_client.dart';
import '../config/api_endpoints.dart';
import '../../features/coaching/data/models/coach_chat_models.dart';

/// Service for 1:1 coach chat, messaging, and workout management.
/// Wraps the backend endpoints in coaching/chat_views.py.
class CoachChatService {
  static CoachChatService? _instance;
  final ApiClient _api;

  static CoachChatService get instance {
    _instance ??= CoachChatService._(ApiClient.instance);
    return _instance!;
  }

  CoachChatService._(this._api);

  /// Get the current user's coaching chats
  Future<List<CoachChatModel>> getMyChats() async {
    try {
      final response = await _api.get(ApiEndpoints.coachChats);
      if (response.data['success'] == true) {
        return (response.data['chats'] as List? ?? [])
            .map((c) => CoachChatModel.fromJson(c))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      throw _extractError(e, 'Failed to load chats');
    }
  }

  /// Add a coach — creates a 1:1 chat with the given coach profile
  Future<CoachChatModel> addCoach(String coachId) async {
    try {
      final response = await _api.post(
        ApiEndpoints.coachChats,
        data: {'coach_id': coachId},
      );
      if (response.data['success'] == true) {
        return CoachChatModel.fromJson(response.data['chat']);
      }
      throw CoachChatException(
        response.data['error']?['message'] ?? 'Failed to add coach',
      );
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to add coach');
    }
  }

  /// Get messages for a chat (paginated, newest first)
  Future<List<ChatMessageModel>> getMessages(
    String chatId, {
    int limit = 50,
    String? before,
  }) async {
    try {
      final params = <String, dynamic>{'limit': limit};
      if (before != null) params['before'] = before;

      final response = await _api.get(
        ApiEndpoints.chatMessages(chatId),
        queryParameters: params,
      );

      if (response.data['success'] == true) {
        return (response.data['messages'] as List? ?? [])
            .map((m) => ChatMessageModel.fromJson(m))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      // 404 means the messages endpoint doesn't exist yet — return empty
      if (e.response?.statusCode == 404) {
        return [];
      }
      throw _extractError(e, 'Failed to load messages');
    }
  }

  /// Send a text message
  Future<ChatMessageModel> sendMessage(String chatId, String text) async {
    try {
      final response = await _api.post(
        ApiEndpoints.chatMessages(chatId),
        data: {'text': text},
      );

      if (response.data['success'] == true) {
        return ChatMessageModel.fromJson(response.data['message']);
      }
      throw CoachChatException('Failed to send message');
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to send message');
    }
  }

  /// Get assigned workouts for a chat
  Future<List<AssignedWorkoutModel>> getWorkouts(
    String chatId, {
    String? status,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (status != null) params['status'] = status;

      final response = await _api.get(
        ApiEndpoints.chatWorkouts(chatId),
        queryParameters: params.isNotEmpty ? params : null,
      );

      if (response.data['success'] == true) {
        return (response.data['workouts'] as List? ?? [])
            .map((w) => AssignedWorkoutModel.fromJson(w))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      throw _extractError(e, 'Failed to load workouts');
    }
  }

  /// Start an assigned workout (begins timer)
  Future<AssignedWorkoutModel> startWorkout(
    String chatId,
    String workoutId,
  ) async {
    try {
      final response = await _api.post(
        ApiEndpoints.startWorkout(chatId, workoutId),
      );

      if (response.data['success'] == true) {
        return AssignedWorkoutModel.fromJson(response.data['workout']);
      }
      throw CoachChatException(
        response.data['error']?['message'] ?? 'Failed to start workout',
      );
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to start workout');
    }
  }

  /// Confirm workout completion
  Future<Map<String, dynamic>> confirmWorkout(
    String chatId,
    String workoutId, {
    String? feedback,
    String? mood,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (feedback != null) data['feedback'] = feedback;
      if (mood != null) data['mood'] = mood;

      final response = await _api.post(
        ApiEndpoints.confirmWorkout(chatId, workoutId),
        data: data.isNotEmpty ? data : null,
      );

      if (response.data['success'] == true) {
        return {
          'workout': AssignedWorkoutModel.fromJson(response.data['workout']),
          'calories_burned': response.data['calories_burned'],
        };
      }
      throw CoachChatException(
        response.data['error']?['message'] ?? 'Failed to confirm workout',
      );
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to confirm workout');
    }
  }

  /// Skip an assigned workout
  Future<AssignedWorkoutModel> skipWorkout(
    String chatId,
    String workoutId, {
    String? reason,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.skipWorkout(chatId, workoutId),
        data: reason != null ? {'reason': reason} : null,
      );

      if (response.data['success'] == true) {
        return AssignedWorkoutModel.fromJson(response.data['workout']);
      }
      throw CoachChatException(
        response.data['error']?['message'] ?? 'Failed to skip workout',
      );
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to skip workout');
    }
  }

  CoachChatException _extractError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      if (data['error'] is Map) {
        return CoachChatException(
          data['error']['message'] ?? fallback,
          code: data['error']['code'],
        );
      }
      return CoachChatException(data['message'] ?? fallback);
    }
    return CoachChatException(fallback);
  }
}

class CoachChatException implements Exception {
  final String message;
  final String? code;

  CoachChatException(this.message, {this.code});

  @override
  String toString() => message;
}
