import 'package:equatable/equatable.dart';
import '../../../../core/services/antigravity_chat_service.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

/// Active chat with a message list. [isLoading] is true while awaiting a reply.
class ChatReady extends ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;

  const ChatReady({
    required this.messages,
    this.isLoading = false,
    this.errorMessage,
  });

  ChatReady copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatReady(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, errorMessage];
}
