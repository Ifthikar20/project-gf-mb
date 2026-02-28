import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/workout_models.dart';
import '../../data/services/workout_service.dart';
import 'workout_event.dart';
import 'workout_state.dart';

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final WorkoutService _service;

  WorkoutBloc({WorkoutService? service})
      : _service = service ?? WorkoutService.instance,
        super(WorkoutInitial()) {
    on<LoadWorkoutData>(_onLoadData);
    on<RefreshWorkoutData>(_onRefreshData);
    on<EstimateCalories>(_onEstimateCalories);
    on<LogManualWorkout>(_onLogManualWorkout);
    on<UpdateBodyProfile>(_onUpdateBodyProfile);
    on<SetWorkoutGoal>(_onSetGoal);
    on<DeleteWorkoutGoal>(_onDeleteGoal);
  }

  /// Helper: try an async call, return fallback on failure (e.g. 404)
  Future<T> _tryOr<T>(Future<T> Function() fn, T fallback) async {
    try {
      return await fn();
    } catch (e) {
      debugPrint('⚠️ WorkoutBloc: endpoint skipped — $e');
      return fallback;
    }
  }

  /// Load all initial data for the Workout Hub
  /// Each endpoint is individually fault-tolerant so the hub shows
  /// a usable empty state even when the backend isn't deployed yet.
  Future<void> _onLoadData(
    LoadWorkoutData event,
    Emitter<WorkoutState> emit,
  ) async {
    emit(WorkoutLoading());

    // Fetch all in parallel — each call falls back to empty on 404
    final types = await _tryOr(() => _service.getWorkoutTypes(), <WorkoutTypeModel>[]);
    final stats = await _tryOr(() => _service.getStats(), null);
    final history = await _tryOr(() => _service.getHistory(limit: 10), <WorkoutLogModel>[]);
    final goals = await _tryOr(() => _service.getGoals(), <GoalProgress>[]);
    final profile = await _tryOr(() => _service.getBodyProfile(), null);

    emit(WorkoutLoaded(
      workoutTypes: types,
      stats: stats,
      recentWorkouts: history,
      goals: goals,
      bodyProfile: profile,
    ));
    debugPrint('✅ WorkoutBloc: Data loaded (${types.length} types, ${history.length} workouts)');
  }

  /// Refresh stats, history, and goals (after logging a workout)
  Future<void> _onRefreshData(
    RefreshWorkoutData event,
    Emitter<WorkoutState> emit,
  ) async {
    final currentState = state;
    try {
      final results = await Future.wait([
        _service.getStats(),
        _service.getHistory(limit: 10),
        _service.getGoals(),
      ]);

      if (currentState is WorkoutLoaded) {
        emit(currentState.copyWith(
          stats: results[0] as WorkoutStats?,
          recentWorkouts: results[1] as List<WorkoutLogModel>,
          goals: results[2] as List<GoalProgress>,
          clearEstimate: true,
        ));
      } else {
        // If we weren't in loaded state, do a full load
        add(const LoadWorkoutData());
      }
    } catch (e) {
      debugPrint('❌ WorkoutBloc: Refresh failed - $e');
      // Keep current state on refresh failure
    }
  }

  /// Get calorie estimate for a workout
  Future<void> _onEstimateCalories(
    EstimateCalories event,
    Emitter<WorkoutState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkoutLoaded) return;

    try {
      final estimate = await _service.estimateCalories(
        workoutTypeId: event.workoutTypeId,
        durationMinutes: event.durationMinutes,
      );
      emit(currentState.copyWith(currentEstimate: estimate));
    } catch (e) {
      debugPrint('⚠️ Estimate failed: $e');
      // Don't emit error — just clear estimate silently
      emit(currentState.copyWith(clearEstimate: true));
    }
  }

  /// Log a manual workout
  Future<void> _onLogManualWorkout(
    LogManualWorkout event,
    Emitter<WorkoutState> emit,
  ) async {
    try {
      final workout = await _service.logManualWorkout(
        workoutTypeId: event.workoutTypeId,
        durationMinutes: event.durationMinutes,
        startedAt: event.startedAt,
        note: event.note,
        mood: event.mood,
      );

      // Fetch updated goals to show progress
      List goals = [];
      try {
        goals = await _service.getGoals();
      } catch (_) {}

      emit(WorkoutLogSuccess(
        workout: workout,
        updatedGoals: goals.cast(),
      ));
      debugPrint('✅ Workout logged: ${workout.workoutName} (${workout.caloriesBurned} cal)');
    } catch (e) {
      debugPrint('❌ Log workout failed: $e');
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('body_profile_required') || errStr.contains('weight')) {
        emit(const WorkoutError(
          'Set your weight first to calculate calories.',
          errorCode: 'BODY_PROFILE_REQUIRED',
        ));
      } else {
        emit(WorkoutError('Failed to log workout. Please try again.'));
      }
    }
  }

  /// Update body profile
  Future<void> _onUpdateBodyProfile(
    UpdateBodyProfile event,
    Emitter<WorkoutState> emit,
  ) async {
    final currentState = state;
    try {
      final profile = await _service.setBodyProfile(
        weightKg: event.weightKg,
        heightCm: event.heightCm,
      );

      if (currentState is WorkoutLoaded) {
        emit(currentState.copyWith(bodyProfile: profile));
      }
      debugPrint('✅ Body profile updated: ${profile.weightKg} kg');
    } catch (e) {
      debugPrint('❌ Body profile update failed: $e');
      emit(const WorkoutError('Failed to save body profile.'));
    }
  }

  /// Set a weekly goal
  Future<void> _onSetGoal(
    SetWorkoutGoal event,
    Emitter<WorkoutState> emit,
  ) async {
    final currentState = state;
    try {
      await _service.setGoal(
        goalType: event.goalType,
        targetValue: event.targetValue,
      );
      // Refresh goals
      final goals = await _service.getGoals();
      if (currentState is WorkoutLoaded) {
        emit(currentState.copyWith(goals: goals));
      }
    } catch (e) {
      debugPrint('❌ Set goal failed: $e');
    }
  }

  /// Delete a weekly goal
  Future<void> _onDeleteGoal(
    DeleteWorkoutGoal event,
    Emitter<WorkoutState> emit,
  ) async {
    final currentState = state;
    try {
      await _service.deleteGoal(event.goalType);
      final goals = await _service.getGoals();
      if (currentState is WorkoutLoaded) {
        emit(currentState.copyWith(goals: goals));
      }
    } catch (e) {
      debugPrint('❌ Delete goal failed: $e');
    }
  }
}
