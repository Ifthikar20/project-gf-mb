import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/antigravity_chat_service.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final AntiGravityChatService _service;

  ChatBloc({AntiGravityChatService? service})
      : _service = service ?? AntiGravityChatService.instance,
        super(const ChatInitial()) {
    on<ChatStarted>(_onStarted);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatCleared>(_onCleared);
  }

  void _onStarted(ChatStarted event, Emitter<ChatState> emit) {
    emit(ChatReady(
      messages: [
        ChatMessage(
          text:
              "Hi! I'm your AntiGravity wellness assistant. Ask me anything about fitness, nutrition, meditation, or your wellness journey.",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
    ));
  }

  Future<void> _onMessageSent(
      ChatMessageSent event, Emitter<ChatState> emit) async {
    if (state is! ChatReady) return;
    final current = state as ChatReady;
    if (current.isLoading) return; // Prevent duplicate sends

    final userMsg = ChatMessage(
      text: event.message.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Add user message and show loading
    emit(current.copyWith(
      messages: [...current.messages, userMsg],
      isLoading: true,
      clearError: true,
    ));

    try {
      final reply = await _service.sendMessage(
        message: userMsg.text,
        history: current.messages,
      );

      final ready = state as ChatReady;
      emit(ready.copyWith(
        messages: [
          ...ready.messages,
          ChatMessage(
            text: reply,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
        isLoading: false,
      ));
    } on ChatException catch (e) {
      final ready = state as ChatReady;
      emit(ready.copyWith(
        isLoading: false,
        errorMessage: e.message,
      ));
    } catch (_) {
      final ready = state as ChatReady;
      emit(ready.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
      ));
    }
  }

  void _onCleared(ChatCleared event, Emitter<ChatState> emit) {
    add(const ChatStarted());
  }
}
