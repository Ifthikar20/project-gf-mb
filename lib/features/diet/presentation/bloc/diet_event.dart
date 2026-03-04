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
