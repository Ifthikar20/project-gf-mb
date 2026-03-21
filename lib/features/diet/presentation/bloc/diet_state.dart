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

  /// Meal list (can span multiple days when using time range filter)
  final List<MealLog> mealListItems;
  final int mealListDays; // 1=today, 7=week, 14=2weeks, 30=month

  const DietLoaded({
    required this.meals,
    required this.summary,
    required this.tipOfTheDay,
    required this.selectedDate,
    this.rangeSummaries = const {},
    this.chartDays = 7,
    this.mealListItems = const [],
    this.mealListDays = 1,
  });

  @override
  List<Object?> get props => [
        meals, summary, tipOfTheDay, selectedDate,
        rangeSummaries, chartDays, mealListItems, mealListDays,
      ];

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
      mealListItems: mealListItems,
      mealListDays: mealListDays,
    );
  }

  /// Create a copy with updated meal list data
  DietLoaded copyWithMealList({
    required List<MealLog> mealListItems,
    required int mealListDays,
  }) {
    return DietLoaded(
      meals: meals,
      summary: summary,
      tipOfTheDay: tipOfTheDay,
      selectedDate: selectedDate,
      rangeSummaries: rangeSummaries,
      chartDays: chartDays,
      mealListItems: mealListItems,
      mealListDays: mealListDays,
    );
  }
}

class DietError extends DietState {
  final String message;
  const DietError(this.message);
  @override
  List<Object?> get props => [message];
}
