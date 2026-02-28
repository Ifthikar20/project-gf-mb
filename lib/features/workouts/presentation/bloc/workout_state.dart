import 'package:equatable/equatable.dart';
import '../../data/models/workout_models.dart';

/// States for the WorkoutBloc
abstract class WorkoutState extends Equatable {
  const WorkoutState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
class WorkoutInitial extends WorkoutState {}

/// Loading state
class WorkoutLoading extends WorkoutState {}

/// All data loaded and ready to display
class WorkoutLoaded extends WorkoutState {
  final List<WorkoutTypeModel> workoutTypes;
  final WorkoutStats? stats;
  final List<WorkoutLogModel> recentWorkouts;
  final List<GoalProgress> goals;
  final BodyProfile? bodyProfile;
  final CalorieEstimate? currentEstimate;

  const WorkoutLoaded({
    required this.workoutTypes,
    this.stats,
    this.recentWorkouts = const [],
    this.goals = const [],
    this.bodyProfile,
    this.currentEstimate,
  });

  @override
  List<Object?> get props => [
        workoutTypes,
        stats,
        recentWorkouts,
        goals,
        bodyProfile,
        currentEstimate,
      ];

  WorkoutLoaded copyWith({
    List<WorkoutTypeModel>? workoutTypes,
    WorkoutStats? stats,
    List<WorkoutLogModel>? recentWorkouts,
    List<GoalProgress>? goals,
    BodyProfile? bodyProfile,
    CalorieEstimate? currentEstimate,
    bool clearEstimate = false,
  }) {
    return WorkoutLoaded(
      workoutTypes: workoutTypes ?? this.workoutTypes,
      stats: stats ?? this.stats,
      recentWorkouts: recentWorkouts ?? this.recentWorkouts,
      goals: goals ?? this.goals,
      bodyProfile: bodyProfile ?? this.bodyProfile,
      currentEstimate:
          clearEstimate ? null : (currentEstimate ?? this.currentEstimate),
    );
  }

  bool get hasBodyProfile => bodyProfile != null;
  bool get hasGoals => goals.isNotEmpty;
}

/// A workout was just logged successfully
class WorkoutLogSuccess extends WorkoutState {
  final WorkoutLogModel workout;
  final List<GoalProgress> updatedGoals;

  const WorkoutLogSuccess({
    required this.workout,
    this.updatedGoals = const [],
  });

  @override
  List<Object?> get props => [workout, updatedGoals];
}

/// Error state
class WorkoutError extends WorkoutState {
  final String message;
  final String? errorCode;

  const WorkoutError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}
