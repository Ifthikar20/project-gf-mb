import 'package:equatable/equatable.dart';

/// Events for the WorkoutBloc
abstract class WorkoutEvent extends Equatable {
  const WorkoutEvent();

  @override
  List<Object?> get props => [];
}

/// Load initial data: workout types, stats, history, goals, body profile
class LoadWorkoutData extends WorkoutEvent {
  const LoadWorkoutData();
}

/// Refresh stats and history after a workout is logged
class RefreshWorkoutData extends WorkoutEvent {
  const RefreshWorkoutData();
}

/// Estimate calories for a workout type and duration
class EstimateCalories extends WorkoutEvent {
  final String workoutTypeId;
  final int durationMinutes;

  const EstimateCalories({
    required this.workoutTypeId,
    required this.durationMinutes,
  });

  @override
  List<Object?> get props => [workoutTypeId, durationMinutes];
}

/// Log a manual workout
class LogManualWorkout extends WorkoutEvent {
  final String workoutTypeId;
  final int durationMinutes;
  final DateTime startedAt;
  final String? note;
  final String? mood;

  const LogManualWorkout({
    required this.workoutTypeId,
    required this.durationMinutes,
    required this.startedAt,
    this.note,
    this.mood,
  });

  @override
  List<Object?> get props => [workoutTypeId, durationMinutes, startedAt, note, mood];
}

/// Update body profile (weight/height)
class UpdateBodyProfile extends WorkoutEvent {
  final double weightKg;
  final double? heightCm;

  const UpdateBodyProfile({
    required this.weightKg,
    this.heightCm,
  });

  @override
  List<Object?> get props => [weightKg, heightCm];
}

/// Set a weekly goal
class SetWorkoutGoal extends WorkoutEvent {
  final String goalType;
  final int targetValue;

  const SetWorkoutGoal({
    required this.goalType,
    required this.targetValue,
  });

  @override
  List<Object?> get props => [goalType, targetValue];
}

/// Delete a weekly goal
class DeleteWorkoutGoal extends WorkoutEvent {
  final String goalType;

  const DeleteWorkoutGoal({required this.goalType});

  @override
  List<Object?> get props => [goalType];
}
