import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/program_service.dart';
import '../../data/models/program_model.dart';
import '../../data/models/enrollment_model.dart';

// ─────────────────────────────────────
// Events
// ─────────────────────────────────────

abstract class ProgramEvent extends Equatable {
  const ProgramEvent();
  @override
  List<Object?> get props => [];
}

/// Browse / search programs
class LoadPrograms extends ProgramEvent {
  final String? categoryId;
  final String? coachId;
  final String? search;
  final String? difficulty;
  final int? durationWeeks;
  final bool? freeOnly;

  const LoadPrograms({
    this.categoryId,
    this.coachId,
    this.search,
    this.difficulty,
    this.durationWeeks,
    this.freeOnly,
  });

  @override
  List<Object?> get props =>
      [categoryId, coachId, search, difficulty, durationWeeks, freeOnly];
}

/// Load a single program detail
class LoadProgramDetail extends ProgramEvent {
  final String programId;
  const LoadProgramDetail({required this.programId});
  @override
  List<Object?> get props => [programId];
}

/// Enroll in a program
class EnrollInProgram extends ProgramEvent {
  final String programId;
  const EnrollInProgram({required this.programId});
  @override
  List<Object?> get props => [programId];
}

/// Load user's enrollments
class LoadMyEnrollments extends ProgramEvent {
  final String? statusFilter; // active, completed, paused
  const LoadMyEnrollments({this.statusFilter});
  @override
  List<Object?> get props => [statusFilter];
}

/// Load a specific enrollment detail (with full schedule)
class LoadEnrollmentDetail extends ProgramEvent {
  final String enrollmentId;
  const LoadEnrollmentDetail({required this.enrollmentId});
  @override
  List<Object?> get props => [enrollmentId];
}

/// Mark a schedule day as complete
class CompleteScheduleDay extends ProgramEvent {
  final String enrollmentId;
  final String dayId;
  final String? watchHistoryId;

  const CompleteScheduleDay({
    required this.enrollmentId,
    required this.dayId,
    this.watchHistoryId,
  });

  @override
  List<Object?> get props => [enrollmentId, dayId];
}

// ─────────────────────────────────────
// States
// ─────────────────────────────────────

abstract class ProgramState extends Equatable {
  const ProgramState();
  @override
  List<Object?> get props => [];
}

class ProgramInitial extends ProgramState {}

class ProgramLoading extends ProgramState {}

class ProgramsLoaded extends ProgramState {
  final List<Program> programs;
  const ProgramsLoaded({required this.programs});
  @override
  List<Object?> get props => [programs.length];
}

class ProgramDetailLoaded extends ProgramState {
  final Program program;
  const ProgramDetailLoaded({required this.program});
  @override
  List<Object?> get props => [program.id];
}

class EnrollmentSuccess extends ProgramState {
  final String enrollmentId;
  final bool isFree;
  final String? clientSecret; // for paid programs (Stripe)
  final String? amount;

  const EnrollmentSuccess({
    required this.enrollmentId,
    required this.isFree,
    this.clientSecret,
    this.amount,
  });

  @override
  List<Object?> get props => [enrollmentId, isFree];
}

class MyEnrollmentsLoaded extends ProgramState {
  final List<Enrollment> enrollments;
  const MyEnrollmentsLoaded({required this.enrollments});
  @override
  List<Object?> get props => [enrollments.length];
}

class EnrollmentDetailLoaded extends ProgramState {
  final Enrollment enrollment;
  const EnrollmentDetailLoaded({required this.enrollment});
  @override
  List<Object?> get props => [enrollment.id, enrollment.progress.percent];
}

class ScheduleDayCompleted extends ProgramState {
  final String dayId;
  const ScheduleDayCompleted({required this.dayId});
  @override
  List<Object?> get props => [dayId];
}

class ProgramError extends ProgramState {
  final String message;
  final bool isPremiumRequired;
  const ProgramError({required this.message, this.isPremiumRequired = false});
  @override
  List<Object?> get props => [message];
}

// ─────────────────────────────────────
// BLoC
// ─────────────────────────────────────

class ProgramBloc extends Bloc<ProgramEvent, ProgramState> {
  final ProgramService _service = ProgramService.instance;

  ProgramBloc() : super(ProgramInitial()) {
    on<LoadPrograms>(_onLoadPrograms);
    on<LoadProgramDetail>(_onLoadDetail);
    on<EnrollInProgram>(_onEnroll);
    on<LoadMyEnrollments>(_onLoadEnrollments);
    on<LoadEnrollmentDetail>(_onLoadEnrollmentDetail);
    on<CompleteScheduleDay>(_onCompleteDay);
  }

  Future<void> _onLoadPrograms(
    LoadPrograms event,
    Emitter<ProgramState> emit,
  ) async {
    emit(ProgramLoading());
    try {
      final programs = await _service.getPrograms(
        categoryId: event.categoryId,
        coachId: event.coachId,
        search: event.search,
        difficulty: event.difficulty,
        durationWeeks: event.durationWeeks,
        freeOnly: event.freeOnly,
      );
      emit(ProgramsLoaded(programs: programs));
    } on ProgramException catch (e) {
      emit(ProgramError(
          message: e.message, isPremiumRequired: e.isPremiumRequired));
    } catch (e) {
      emit(const ProgramError(message: 'Failed to load programs'));
    }
  }

  Future<void> _onLoadDetail(
    LoadProgramDetail event,
    Emitter<ProgramState> emit,
  ) async {
    emit(ProgramLoading());
    try {
      final program = await _service.getProgramDetail(event.programId);
      emit(ProgramDetailLoaded(program: program));
    } on ProgramException catch (e) {
      emit(ProgramError(message: e.message));
    } catch (e) {
      emit(const ProgramError(message: 'Failed to load program'));
    }
  }

  Future<void> _onEnroll(
    EnrollInProgram event,
    Emitter<ProgramState> emit,
  ) async {
    emit(ProgramLoading());
    try {
      final result = await _service.enrollInProgram(event.programId);
      emit(EnrollmentSuccess(
        enrollmentId: result['enrollment_id'] ?? '',
        isFree: result['is_free'] ?? false,
        clientSecret: result['client_secret'],
        amount: result['amount'],
      ));
    } on ProgramException catch (e) {
      emit(ProgramError(
          message: e.message, isPremiumRequired: e.isPremiumRequired));
    } catch (e) {
      emit(const ProgramError(message: 'Enrollment failed'));
    }
  }

  Future<void> _onLoadEnrollments(
    LoadMyEnrollments event,
    Emitter<ProgramState> emit,
  ) async {
    emit(ProgramLoading());
    try {
      final enrollments =
          await _service.getMyEnrollments(status: event.statusFilter);
      emit(MyEnrollmentsLoaded(enrollments: enrollments));
    } on ProgramException catch (e) {
      emit(ProgramError(message: e.message));
    } catch (e) {
      emit(const ProgramError(message: 'Failed to load enrollments'));
    }
  }

  Future<void> _onLoadEnrollmentDetail(
    LoadEnrollmentDetail event,
    Emitter<ProgramState> emit,
  ) async {
    emit(ProgramLoading());
    try {
      final enrollment =
          await _service.getEnrollmentDetail(event.enrollmentId);
      emit(EnrollmentDetailLoaded(enrollment: enrollment));
    } on ProgramException catch (e) {
      emit(ProgramError(message: e.message));
    } catch (e) {
      emit(const ProgramError(message: 'Failed to load enrollment'));
    }
  }

  Future<void> _onCompleteDay(
    CompleteScheduleDay event,
    Emitter<ProgramState> emit,
  ) async {
    try {
      await _service.completeScheduleDay(
        event.enrollmentId,
        event.dayId,
        watchHistoryId: event.watchHistoryId,
      );
      emit(ScheduleDayCompleted(dayId: event.dayId));
      // Reload enrollment to refresh progress
      add(LoadEnrollmentDetail(enrollmentId: event.enrollmentId));
    } on ProgramException catch (e) {
      emit(ProgramError(message: e.message));
    } catch (e) {
      emit(const ProgramError(message: 'Failed to mark complete'));
    }
  }
}
