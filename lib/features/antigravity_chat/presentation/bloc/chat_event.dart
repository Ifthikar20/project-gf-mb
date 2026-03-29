import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

/// Initialise the chat session (show welcome message).
class ChatStarted extends ChatEvent {
  const ChatStarted();
}

/// User submitted a new message.
class ChatMessageSent extends ChatEvent {
  final String message;
  const ChatMessageSent(this.message);
  @override
  List<Object?> get props => [message];
}

/// Clear the conversation history.
class ChatCleared extends ChatEvent {
  const ChatCleared();
}
