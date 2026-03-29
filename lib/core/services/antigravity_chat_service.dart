import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// A chat message exchanged with the AntiGravity AI assistant.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

/// Sends conversational messages to the backend wellness chat endpoint.
/// The backend proxies requests to Gemini — the API key never leaves the server.
class AntiGravityChatService {
  static AntiGravityChatService? _instance;
  final ApiClient _api;

  static AntiGravityChatService get instance {
    _instance ??= AntiGravityChatService._(ApiClient.instance);
    return _instance!;
  }

  AntiGravityChatService._(this._api);

  /// Send [message] with the current [history] and return the AI reply text.
  ///
  /// Throws [ChatException] on any error.
  Future<String> sendMessage({
    required String message,
    required List<ChatMessage> history,
  }) async {
    try {
      final historyPayload = history
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'text': m.text,
              })
          .toList();

      final response = await _api.post(
        '/api/wellness/chat',
        data: {
          'message': message,
          'history': historyPayload,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['reply'] is String) {
        return data['reply'] as String;
      }
      throw ChatException('Unexpected response format from server.');
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map ? (data['error']?['message'] ?? data['message']) : null;
      debugPrint('💬 AntiGravity Chat error: $msg');
      if (e.response?.statusCode == 429) {
        throw ChatException('Too many messages. Please wait a moment.');
      }
      if (e.response?.statusCode == 401) {
        throw ChatException('Please log in to use the chat.');
      }
      throw ChatException(msg?.toString() ?? 'Could not reach the server.');
    } catch (e) {
      if (e is ChatException) rethrow;
      throw ChatException('Something went wrong. Please try again.');
    }
  }
}

class ChatException implements Exception {
  final String message;
  const ChatException(this.message);

  @override
  String toString() => message;
}
