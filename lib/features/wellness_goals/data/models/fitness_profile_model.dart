import 'package:hive/hive.dart';

part 'fitness_profile_model.g.dart';

/// Body type categories
@HiveType(typeId: 22)
enum BodyType {
  @HiveField(0)
  lean,       // Ectomorph - naturally thin
  @HiveField(1)
  athletic,   // Mesomorph - muscular build
  @HiveField(2)
  stocky,     // Endomorph - wider build
}

/// Fitness goal categories
@HiveType(typeId: 23)
enum FitnessGoal {
  @HiveField(0)
  loseWeight,
  @HiveField(1)
  buildMuscle,
  @HiveField(2)
  stayActive,
  @HiveField(3)
  improveFlexibility,
}

/// Workout intensity preference
@HiveType(typeId: 24)
enum WorkoutIntensity {
  @HiveField(0)
  calm,
  @HiveField(1)
  moderate,
  @HiveField(2)
  aggressive,
}

/// User's fitness profile stored locally via Hive
@HiveType(typeId: 21)
class FitnessProfileModel extends HiveObject {
  @HiveField(0)
  final int bodyTypeIndex; // maps to BodyType enum

  @HiveField(1)
  final int fitnessGoalIndex; // maps to FitnessGoal enum

  @HiveField(2)
  final int intensityIndex; // maps to WorkoutIntensity enum

  @HiveField(3)
  final List<String> preferredWorkoutIds;

  @HiveField(4)
  final bool isSetUp;

  @HiveField(5)
  final DateTime updatedAt;

  FitnessProfileModel({
    required this.bodyTypeIndex,
    required this.fitnessGoalIndex,
    required this.intensityIndex,
    this.preferredWorkoutIds = const [],
    this.isSetUp = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  BodyType get bodyType => BodyType.values[bodyTypeIndex.clamp(0, 2)];
  FitnessGoal get fitnessGoal => FitnessGoal.values[fitnessGoalIndex.clamp(0, 3)];
  WorkoutIntensity get intensity => WorkoutIntensity.values[intensityIndex.clamp(0, 2)];

  String get bodyTypeLabel {
    switch (bodyType) {
      case BodyType.lean:
        return 'Lean';
      case BodyType.athletic:
        return 'Athletic';
      case BodyType.stocky:
        return 'Stocky';
    }
  }

  String get bodyTypeDescription {
    switch (bodyType) {
      case BodyType.lean:
        return 'Naturally thin, fast metabolism';
      case BodyType.athletic:
        return 'Muscular build, gains easily';
      case BodyType.stocky:
        return 'Wider build, strong frame';
    }
  }

  String get fitnessGoalLabel {
    switch (fitnessGoal) {
      case FitnessGoal.loseWeight:
        return 'Lose Weight';
      case FitnessGoal.buildMuscle:
        return 'Build Muscle';
      case FitnessGoal.stayActive:
        return 'Stay Active';
      case FitnessGoal.improveFlexibility:
        return 'Improve Flexibility';
    }
  }

  String get intensityLabel {
    switch (intensity) {
      case WorkoutIntensity.calm:
        return 'Calm';
      case WorkoutIntensity.moderate:
        return 'Moderate';
      case WorkoutIntensity.aggressive:
        return 'Aggressive';
    }
  }

  FitnessProfileModel copyWith({
    int? bodyTypeIndex,
    int? fitnessGoalIndex,
    int? intensityIndex,
    List<String>? preferredWorkoutIds,
    bool? isSetUp,
  }) {
    return FitnessProfileModel(
      bodyTypeIndex: bodyTypeIndex ?? this.bodyTypeIndex,
      fitnessGoalIndex: fitnessGoalIndex ?? this.fitnessGoalIndex,
      intensityIndex: intensityIndex ?? this.intensityIndex,
      preferredWorkoutIds: preferredWorkoutIds ?? this.preferredWorkoutIds,
      isSetUp: isSetUp ?? this.isSetUp,
      updatedAt: DateTime.now(),
    );
  }
}
