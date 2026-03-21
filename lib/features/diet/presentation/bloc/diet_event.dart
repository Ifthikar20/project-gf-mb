import 'package:equatable/equatable.dart';
import '../../data/models/diet_models.dart';

abstract class DietEvent extends Equatable {
  const DietEvent();
  @override
  List<Object?> get props => [];
}

/// Load meals for a specific date
class LoadMeals extends DietEvent {
  final DateTime date;
  const LoadMeals({required this.date});
  @override
  List<Object?> get props => [date];
}

/// Load today's meals (convenience shorthand)
class LoadTodayMeals extends DietEvent {}

/// Log a new meal
class LogMeal extends DietEvent {
  final MealLog meal;
  const LogMeal({required this.meal});
  @override
  List<Object?> get props => [meal];
}

/// Log multiple meals at once (from a scan) — saves all, reloads once
class LogMealBatch extends DietEvent {
  final List<MealLog> meals;
  const LogMealBatch({required this.meals});
  @override
  List<Object?> get props => [meals];
}

/// Delete a meal by its Hive key
class DeleteMeal extends DietEvent {
  final int key;
  const DeleteMeal({required this.key});
  @override
  List<Object?> get props => [key];
}

/// Change displayed date
class ChangeDateFilter extends DietEvent {
  final DateTime date;
  const ChangeDateFilter({required this.date});
  @override
  List<Object?> get props => [date];
}

/// Load meals for a date range (for charts — 7D/14D/30D)
class LoadMealsForRange extends DietEvent {
  final int days;
  const LoadMealsForRange({required this.days});
  @override
  List<Object?> get props => [days];
}

/// Load meal list for a given time range (Today/1W/2W/1M)
class LoadMealList extends DietEvent {
  final int days; // 1=today, 7=week, 14=2weeks, 30=month
  const LoadMealList({required this.days});
  @override
  List<Object?> get props => [days];
}
