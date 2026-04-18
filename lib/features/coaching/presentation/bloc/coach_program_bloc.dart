import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/coach_program_service.dart';
import '../../data/models/coach_program_models.dart';

// ─────────────────────────────────────────────────────────
// Events
// ─────────────────────────────────────────────────────────

abstract class CoachProgramEvent extends Equatable {
  const CoachProgramEvent();
  @override
  List<Object?> get props => [];
}

class LoadCoachPrograms extends CoachProgramEvent {
  final String? coachId;
  final String? category;
  final int? durationWeeks;
  const LoadCoachPrograms({this.coachId, this.category, this.durationWeeks});
  @override
  List<Object?> get props => [coachId, category, durationWeeks];
}

class LoadProgramDetail extends CoachProgramEvent {
  final String programId;
  const LoadProgramDetail({required this.programId});
  @override
  List<Object?> get props => [programId];
}

class EnrollInProgram extends CoachProgramEvent {
  final String programId;
  const EnrollInProgram({required this.programId});
  @override
  List<Object?> get props => [programId];
}

class LoadMyEnrollments extends CoachProgramEvent {
  const LoadMyEnrollments();
}

class MarkDayComplete extends CoachProgramEvent {
  final String programId;
  final String dayId;
  const MarkDayComplete({required this.programId, required this.dayId});
  @override
  List<Object?> get props => [programId, dayId];
}

// ─────────────────────────────────────────────────────────
// States
// ─────────────────────────────────────────────────────────

abstract class CoachProgramState extends Equatable {
  const CoachProgramState();
  @override
  List<Object?> get props => [];
}

class CoachProgramInitial extends CoachProgramState {}

class CoachProgramLoading extends CoachProgramState {}

class CoachProgramsLoaded extends CoachProgramState {
  final List<CoachProgram> programs;
  const CoachProgramsLoaded({required this.programs});
  @override
  List<Object?> get props => [programs.length];
}

class CoachProgramDetailLoaded extends CoachProgramState {
  final CoachProgram program;
  const CoachProgramDetailLoaded({required this.program});
  @override
  List<Object?> get props => [program.id, program.isEnrolled];
}

class CoachProgramEnrollmentSuccess extends CoachProgramState {
  final String programId;
  final String message;
  const CoachProgramEnrollmentSuccess({
    required this.programId,
    required this.message,
  });
  @override
  List<Object?> get props => [programId];
}

class MyEnrollmentsLoaded extends CoachProgramState {
  final List<CoachProgram> programs;
  const MyEnrollmentsLoaded({required this.programs});
  @override
  List<Object?> get props => [programs.length];
}

class CoachProgramDayCompleted extends CoachProgramState {
  final String programId;
  final String dayId;
  const CoachProgramDayCompleted({
    required this.programId,
    required this.dayId,
  });
  @override
  List<Object?> get props => [programId, dayId];
}

class CoachProgramError extends CoachProgramState {
  final String message;
  const CoachProgramError({required this.message});
  @override
  List<Object?> get props => [message];
}

// ─────────────────────────────────────────────────────────
// BLoC
// ─────────────────────────────────────────────────────────

class CoachProgramBloc extends Bloc<CoachProgramEvent, CoachProgramState> {
  final CoachProgramService _service = CoachProgramService.instance;

  CoachProgramBloc() : super(CoachProgramInitial()) {
    on<LoadCoachPrograms>(_onLoadPrograms);
    on<LoadProgramDetail>(_onLoadDetail);
    on<EnrollInProgram>(_onEnroll);
    on<LoadMyEnrollments>(_onLoadMyEnrollments);
    on<MarkDayComplete>(_onMarkDayComplete);
  }

  Future<void> _onLoadPrograms(
    LoadCoachPrograms event,
    Emitter<CoachProgramState> emit,
  ) async {
    emit(CoachProgramLoading());
    try {
      final programs = await _service.getPrograms(
        coachId: event.coachId,
        category: event.category,
        durationWeeks: event.durationWeeks,
      );
      emit(CoachProgramsLoaded(programs: programs));
    } on CoachProgramException catch (e) {
      emit(CoachProgramError(message: e.message));
    } catch (e) {
      emit(const CoachProgramError(message: 'Failed to load programs'));
    }
  }

  Future<void> _onLoadDetail(
    LoadProgramDetail event,
    Emitter<CoachProgramState> emit,
  ) async {
    emit(CoachProgramLoading());
    try {
      final program = await _service.getProgramDetail(event.programId);
      emit(CoachProgramDetailLoaded(program: program));
    } on CoachProgramException catch (e) {
      emit(CoachProgramError(message: e.message));
    } catch (e) {
      emit(const CoachProgramError(message: 'Failed to load program'));
    }
  }

  Future<void> _onEnroll(
    EnrollInProgram event,
    Emitter<CoachProgramState> emit,
  ) async {
    emit(CoachProgramLoading());
    try {
      final result = await _service.enrollInProgram(event.programId);
      emit(CoachProgramEnrollmentSuccess(
        programId: event.programId,
        message: result['message'] ?? 'Enrolled!',
      ));
    } on CoachProgramException catch (e) {
      emit(CoachProgramError(message: e.message));
    } catch (e) {
      emit(const CoachProgramError(message: 'Enrollment failed'));
    }
  }

  Future<void> _onLoadMyEnrollments(
    LoadMyEnrollments event,
    Emitter<CoachProgramState> emit,
  ) async {
    emit(CoachProgramLoading());
    try {
      final programs = await _service.getMyEnrollments();
      emit(MyEnrollmentsLoaded(programs: programs));
    } on CoachProgramException catch (e) {
      emit(CoachProgramError(message: e.message));
    } catch (e) {
      emit(
          const CoachProgramError(message: 'Failed to load your programs'));
    }
  }

  Future<void> _onMarkDayComplete(
    MarkDayComplete event,
    Emitter<CoachProgramState> emit,
  ) async {
    try {
      await _service.markDayComplete(event.programId, event.dayId);
      emit(CoachProgramDayCompleted(
        programId: event.programId,
        dayId: event.dayId,
      ));
    } on CoachProgramException catch (e) {
      emit(CoachProgramError(message: e.message));
    } catch (e) {
      emit(const CoachProgramError(message: 'Failed to mark day complete'));
    }
  }
}
