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

  /// Multi-day data for charts (date → daily summary)
  final Map<DateTime, DailyNutritionSummary> rangeSummaries;
  final int chartDays; // 7, 14, or 30

  const DietLoaded({
    required this.meals,
    required this.summary,
    required this.tipOfTheDay,
    required this.selectedDate,
    this.rangeSummaries = const {},
    this.chartDays = 7,
  });

  @override
  List<Object?> get props => [meals, summary, tipOfTheDay, selectedDate, rangeSummaries, chartDays];

  /// Create a copy with updated range data (for chart updates without reloading meals)
  DietLoaded copyWithRange({
    Map<DateTime, DailyNutritionSummary>? rangeSummaries,
    int? chartDays,
  }) {
    return DietLoaded(
      meals: meals,
      summary: summary,
      tipOfTheDay: tipOfTheDay,
      selectedDate: selectedDate,
      rangeSummaries: rangeSummaries ?? this.rangeSummaries,
      chartDays: chartDays ?? this.chartDays,
    );
  }
}

class DietError extends DietState {
  final String message;
  const DietError(this.message);
  @override
  List<Object?> get props => [message];
}
