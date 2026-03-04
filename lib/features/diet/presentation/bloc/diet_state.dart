import 'package:equatable/equatable.dart';
import '../../data/models/diet_models.dart';
import '../../data/nutrition_tips.dart';

abstract class DietState extends Equatable {
  const DietState();
  @override
  List<Object?> get props => [];
}

class DietInitial extends DietState {}

class DietLoading extends DietState {}

class DietLoaded extends DietState {
  final List<MealLog> meals;
  final DailyNutritionSummary summary;
  final NutritionTip tipOfTheDay;
  final DateTime selectedDate;

  const DietLoaded({
    required this.meals,
    required this.summary,
    required this.tipOfTheDay,
    required this.selectedDate,
  });

  @override
  List<Object?> get props => [meals, summary, tipOfTheDay, selectedDate];
}

class DietError extends DietState {
  final String message;
  const DietError(this.message);
  @override
  List<Object?> get props => [message];
}
