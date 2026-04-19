import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/coach_chat_service.dart';
import '../../data/models/coach_chat_models.dart';

// ─────────────────────────────────────────────
// Events
// ─────────────────────────────────────────────

abstract class CoachChatEvent extends Equatable {
  const CoachChatEvent();
  @override
  List<Object?> get props => [];
}

class LoadMyCoachChat extends CoachChatEvent {
  const LoadMyCoachChat();
}

class LoadMessages extends CoachChatEvent {
  final String chatId;
  const LoadMessages(this.chatId);
  @override
  List<Object?> get props => [chatId];
}

class SendMessage extends CoachChatEvent {
  final String chatId;
  final String text;
  const SendMessage(this.chatId, this.text);
  @override
  List<Object?> get props => [chatId, text];
}

class LoadWorkouts extends CoachChatEvent {
  final String chatId;
  const LoadWorkouts(this.chatId);
  @override
  List<Object?> get props => [chatId];
}

class StartWorkoutEvent extends CoachChatEvent {
  final String chatId;
  final String workoutId;
  const StartWorkoutEvent(this.chatId, this.workoutId);
  @override
  List<Object?> get props => [chatId, workoutId];
}

class ConfirmWorkoutEvent extends CoachChatEvent {
  final String chatId;
  final String workoutId;
  final String? feedback;
  final String? mood;
  const ConfirmWorkoutEvent(this.chatId, this.workoutId, {this.feedback, this.mood});
  @override
  List<Object?> get props => [chatId, workoutId, feedback, mood];
}

class SkipWorkoutEvent extends CoachChatEvent {
  final String chatId;
  final String workoutId;
  final String? reason;
  const SkipWorkoutEvent(this.chatId, this.workoutId, {this.reason});
  @override
  List<Object?> get props => [chatId, workoutId, reason];
}

/// Event to add a coach (creates a 1:1 chat)
class AddCoachEvent extends CoachChatEvent {
  final String coachId;
  const AddCoachEvent(this.coachId);
  @override
  List<Object?> get props => [coachId];
}

// ─────────────────────────────────────────────
// States
// ─────────────────────────────────────────────

abstract class CoachChatState extends Equatable {
  const CoachChatState();
  @override
  List<Object?> get props => [];
}

class CoachChatInitial extends CoachChatState {}

class CoachChatLoading extends CoachChatState {}

/// No coach assigned — show empty state
class CoachChatEmpty extends CoachChatState {}

/// Chat loaded with messages and workouts
class CoachChatLoaded extends CoachChatState {
  final CoachChatModel chat;
  final List<ChatMessageModel> messages;
  final List<AssignedWorkoutModel> workouts;
  final bool isSendingMessage;

  const CoachChatLoaded({
    required this.chat,
    required this.messages,
    required this.workouts,
    this.isSendingMessage = false,
  });

  @override
  List<Object?> get props => [chat, messages, workouts, isSendingMessage];

  CoachChatLoaded copyWith({
    CoachChatModel? chat,
    List<ChatMessageModel>? messages,
    List<AssignedWorkoutModel>? workouts,
    bool? isSendingMessage,
  }) {
    return CoachChatLoaded(
      chat: chat ?? this.chat,
      messages: messages ?? this.messages,
      workouts: workouts ?? this.workouts,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
    );
  }

  /// Active workouts (assigned or in-progress) for the workout section
  List<AssignedWorkoutModel> get activeWorkouts =>
      workouts.where((w) => w.isAssigned || w.isInProgress).toList();

  /// Recently completed workouts
  List<AssignedWorkoutModel> get completedWorkouts =>
      workouts.where((w) => w.isCompleted).toList();
}

class CoachChatError extends CoachChatState {
  final String message;
  const CoachChatError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Coach was successfully added
class CoachAdded extends CoachChatState {
  final CoachChatModel chat;
  const CoachAdded(this.chat);
  @override
  List<Object?> get props => [chat];
}

/// Adding coach in progress
class AddingCoach extends CoachChatState {}

// ─────────────────────────────────────────────
// BLoC
// ─────────────────────────────────────────────

class CoachChatBloc extends Bloc<CoachChatEvent, CoachChatState> {
  final CoachChatService _service = CoachChatService.instance;

  CoachChatBloc() : super(CoachChatInitial()) {
    on<LoadMyCoachChat>(_onLoadMyCoachChat);
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<LoadWorkouts>(_onLoadWorkouts);
    on<StartWorkoutEvent>(_onStartWorkout);
    on<ConfirmWorkoutEvent>(_onConfirmWorkout);
    on<SkipWorkoutEvent>(_onSkipWorkout);
    on<AddCoachEvent>(_onAddCoach);
  }

  Future<void> _onLoadMyCoachChat(
    LoadMyCoachChat event,
    Emitter<CoachChatState> emit,
  ) async {
    emit(CoachChatLoading());
    try {
      final chats = await _service.getMyChats();
      if (chats.isEmpty) {
        emit(CoachChatEmpty());
        return;
      }

      // Use the first (most recent) chat
      final chat = chats.first;
      final messages = await _service.getMessages(chat.id);
      final workouts = await _service.getWorkouts(chat.id);

      emit(CoachChatLoaded(
        chat: chat,
        messages: messages,
        workouts: workouts,
      ));
    } on CoachChatException catch (e) {
      emit(CoachChatError(e.message));
    } catch (e) {
      emit(const CoachChatError('Failed to load coach chat'));
    }
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<CoachChatState> emit,
  ) async {
    if (state is! CoachChatLoaded) return;
    final current = state as CoachChatLoaded;

    try {
      final messages = await _service.getMessages(event.chatId);
      emit(current.copyWith(messages: messages));
    } catch (_) {
      // Silently fail — keep existing messages
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<CoachChatState> emit,
  ) async {
    if (state is! CoachChatLoaded) return;
    final current = state as CoachChatLoaded;

    emit(current.copyWith(isSendingMessage: true));

    try {
      final newMsg = await _service.sendMessage(event.chatId, event.text);
      final updatedMessages = [newMsg, ...current.messages];
      emit(current.copyWith(
        messages: updatedMessages,
        isSendingMessage: false,
      ));
    } catch (_) {
      emit(current.copyWith(isSendingMessage: false));
    }
  }

  Future<void> _onLoadWorkouts(
    LoadWorkouts event,
    Emitter<CoachChatState> emit,
  ) async {
    if (state is! CoachChatLoaded) return;
    final current = state as CoachChatLoaded;

    try {
      final workouts = await _service.getWorkouts(event.chatId);
      emit(current.copyWith(workouts: workouts));
    } catch (_) {}
  }

  Future<void> _onStartWorkout(
    StartWorkoutEvent event,
    Emitter<CoachChatState> emit,
  ) async {
    if (state is! CoachChatLoaded) return;
    final current = state as CoachChatLoaded;

    try {
      final updated = await _service.startWorkout(event.chatId, event.workoutId);
      final workouts = current.workouts
          .map((w) => w.id == updated.id ? updated : w)
          .toList();
      emit(current.copyWith(workouts: workouts));
    } on CoachChatException catch (e) {
      emit(CoachChatError(e.message));
      emit(current); // restore
    }
  }

  Future<void> _onConfirmWorkout(
    ConfirmWorkoutEvent event,
    Emitter<CoachChatState> emit,
  ) async {
    if (state is! CoachChatLoaded) return;
    final current = state as CoachChatLoaded;

    try {
      final result = await _service.confirmWorkout(
        event.chatId,
        event.workoutId,
        feedback: event.feedback,
        mood: event.mood,
      );
      final updatedWorkout = result['workout'] as AssignedWorkoutModel;
      final workouts = current.workouts
          .map((w) => w.id == updatedWorkout.id ? updatedWorkout : w)
          .toList();

      // Refresh messages to show the completion message
      final messages = await _service.getMessages(current.chat.id);
      emit(current.copyWith(workouts: workouts, messages: messages));
    } on CoachChatException catch (e) {
      emit(CoachChatError(e.message));
      emit(current);
    }
  }

  Future<void> _onSkipWorkout(
    SkipWorkoutEvent event,
    Emitter<CoachChatState> emit,
  ) async {
    if (state is! CoachChatLoaded) return;
    final current = state as CoachChatLoaded;

    try {
      final updated = await _service.skipWorkout(
        event.chatId,
        event.workoutId,
        reason: event.reason,
      );
      final workouts = current.workouts
          .map((w) => w.id == updated.id ? updated : w)
          .toList();

      final messages = await _service.getMessages(current.chat.id);
      emit(current.copyWith(workouts: workouts, messages: messages));
    } on CoachChatException catch (e) {
      emit(CoachChatError(e.message));
      emit(current);
    }
  }

  Future<void> _onAddCoach(
    AddCoachEvent event,
    Emitter<CoachChatState> emit,
  ) async {
    emit(AddingCoach());
    try {
      final chat = await _service.addCoach(event.coachId);
      emit(CoachAdded(chat));
      // Auto reload the coach chat view
      add(const LoadMyCoachChat());
    } on CoachChatException catch (e) {
      emit(CoachChatError(e.message));
    } catch (e) {
      emit(const CoachChatError('Could not add coach. Please try again.'));
    }
  }
}
