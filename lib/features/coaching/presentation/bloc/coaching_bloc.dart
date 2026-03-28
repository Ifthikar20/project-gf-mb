import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/coaching_service.dart';

// Events
abstract class CoachingEvent extends Equatable {
  const CoachingEvent();
  @override
  List<Object?> get props => [];
}

class LoadCoaches extends CoachingEvent {
  final String? specialty;
  final double? maxPrice;
  const LoadCoaches({this.specialty, this.maxPrice});
  @override
  List<Object?> get props => [specialty, maxPrice];
}

class LoadCoachDetail extends CoachingEvent {
  final String coachId;
  const LoadCoachDetail({required this.coachId});
  @override
  List<Object?> get props => [coachId];
}

class LoadSessions extends CoachingEvent {
  final String role;
  const LoadSessions({this.role = 'client'});
  @override
  List<Object?> get props => [role];
}

class JoinSession extends CoachingEvent {
  final String sessionId;
  const JoinSession({required this.sessionId});
  @override
  List<Object?> get props => [sessionId];
}

class CancelSession extends CoachingEvent {
  final String sessionId;
  final String? reason;
  const CancelSession({required this.sessionId, this.reason});
  @override
  List<Object?> get props => [sessionId, reason];
}

class GetBookingUrl extends CoachingEvent {
  final String coachId;
  const GetBookingUrl({required this.coachId});
  @override
  List<Object?> get props => [coachId];
}

// States
abstract class CoachingState extends Equatable {
  const CoachingState();
  @override
  List<Object?> get props => [];
}

class CoachingInitial extends CoachingState {}

class CoachingLoading extends CoachingState {}

class CoachesLoaded extends CoachingState {
  final List<Coach> coaches;
  const CoachesLoaded({required this.coaches});
  @override
  List<Object?> get props => [coaches.length];
}

class CoachDetailLoaded extends CoachingState {
  final Coach coach;
  const CoachDetailLoaded({required this.coach});
  @override
  List<Object?> get props => [coach.id];
}

class CoachingSessionsLoaded extends CoachingState {
  final List<CoachingSession> sessions;
  const CoachingSessionsLoaded({required this.sessions});

  List<CoachingSession> get upcoming =>
      sessions.where((s) => s.isUpcoming).toList();
  List<CoachingSession> get past =>
      sessions.where((s) => s.isPast).toList();

  @override
  List<Object?> get props => [sessions.length];
}

class CoachingBookingUrlReady extends CoachingState {
  final String bookingUrl;
  final Map<String, dynamic> coach;
  const CoachingBookingUrlReady({
    required this.bookingUrl,
    required this.coach,
  });
  @override
  List<Object?> get props => [bookingUrl];
}

class CoachingSessionJoined extends CoachingState {
  final String token;
  final String livekitUrl;
  final String roomName;
  final String role;
  const CoachingSessionJoined({
    required this.token,
    required this.livekitUrl,
    required this.roomName,
    required this.role,
  });
  @override
  List<Object?> get props => [token, roomName];
}

class CoachingSessionCancelled extends CoachingState {
  final String status;
  final String refundAmount;
  const CoachingSessionCancelled({
    required this.status,
    required this.refundAmount,
  });
  @override
  List<Object?> get props => [status, refundAmount];
}

class CoachingError extends CoachingState {
  final String message;
  const CoachingError({required this.message});
  @override
  List<Object?> get props => [message];
}

// BLoC
class CoachingBloc extends Bloc<CoachingEvent, CoachingState> {
  final CoachingService _service = CoachingService.instance;

  CoachingBloc() : super(CoachingInitial()) {
    on<LoadCoaches>(_onLoadCoaches);
    on<LoadCoachDetail>(_onLoadDetail);
    on<LoadSessions>(_onLoadSessions);
    on<JoinSession>(_onJoinSession);
    on<CancelSession>(_onCancelSession);
    on<GetBookingUrl>(_onGetBookingUrl);
  }

  Future<void> _onLoadCoaches(
    LoadCoaches event,
    Emitter<CoachingState> emit,
  ) async {
    emit(CoachingLoading());
    try {
      final coaches = await _service.getCoaches(
        specialty: event.specialty,
        maxPrice: event.maxPrice,
      );
      emit(CoachesLoaded(coaches: coaches));
    } on CoachingException catch (e) {
      emit(CoachingError(message: e.message));
    } catch (e) {
      emit(const CoachingError(message: 'Failed to load coaches'));
    }
  }

  Future<void> _onLoadDetail(
    LoadCoachDetail event,
    Emitter<CoachingState> emit,
  ) async {
    emit(CoachingLoading());
    try {
      final coach = await _service.getCoachDetail(event.coachId);
      emit(CoachDetailLoaded(coach: coach));
    } on CoachingException catch (e) {
      emit(CoachingError(message: e.message));
    } catch (e) {
      emit(const CoachingError(message: 'Failed to load coach'));
    }
  }

  Future<void> _onLoadSessions(
    LoadSessions event,
    Emitter<CoachingState> emit,
  ) async {
    emit(CoachingLoading());
    try {
      final sessions = await _service.getSessions(role: event.role);
      emit(CoachingSessionsLoaded(sessions: sessions));
    } on CoachingException catch (e) {
      emit(CoachingError(message: e.message));
    } catch (e) {
      emit(const CoachingError(message: 'Failed to load sessions'));
    }
  }

  Future<void> _onJoinSession(
    JoinSession event,
    Emitter<CoachingState> emit,
  ) async {
    emit(CoachingLoading());
    try {
      final result = await _service.joinSession(event.sessionId);
      emit(CoachingSessionJoined(
        token: result['token'],
        livekitUrl: result['livekit_url'],
        roomName: result['room_name'],
        role: result['role'],
      ));
    } on CoachingException catch (e) {
      emit(CoachingError(message: e.message));
    } catch (e) {
      emit(const CoachingError(message: 'Failed to join session'));
    }
  }

  Future<void> _onCancelSession(
    CancelSession event,
    Emitter<CoachingState> emit,
  ) async {
    emit(CoachingLoading());
    try {
      final result = await _service.cancelSession(
        event.sessionId,
        reason: event.reason,
      );
      emit(CoachingSessionCancelled(
        status: result['status'],
        refundAmount: result['refund_amount'],
      ));
    } on CoachingException catch (e) {
      emit(CoachingError(message: e.message));
    } catch (e) {
      emit(const CoachingError(message: 'Failed to cancel session'));
    }
  }

  Future<void> _onGetBookingUrl(
    GetBookingUrl event,
    Emitter<CoachingState> emit,
  ) async {
    emit(CoachingLoading());
    try {
      final result = await _service.getBookingUrl(event.coachId);
      emit(CoachingBookingUrlReady(
        bookingUrl: result['booking_url'],
        coach: result['coach'] ?? {},
      ));
    } on CoachingException catch (e) {
      emit(CoachingError(message: e.message));
    } catch (e) {
      emit(const CoachingError(message: 'Failed to get booking URL'));
    }
  }
}
