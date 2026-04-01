import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/diet_local_datasource.dart';
import '../../data/models/diet_models.dart';
import '../../data/nutrition_tips.dart';
import 'diet_event.dart';
import 'diet_state.dart';

class DietBloc extends Bloc<DietEvent, DietState> {
  final DietLocalDataSource _dataSource;

  DietBloc({DietLocalDataSource? dataSource})
      : _dataSource = dataSource ?? DietLocalDataSource(),
        super(DietInitial()) {
    on<LoadMeals>(_onLoadMeals);
    on<LoadTodayMeals>(_onLoadTodayMeals);
    on<LogMeal>(_onLogMeal);
    on<LogMealBatch>(_onLogMealBatch);
    on<DeleteMeal>(_onDeleteMeal);
    on<ChangeDateFilter>(_onChangeDateFilter);
    on<LoadMealsForRange>(_onLoadMealsForRange);
    on<LoadMealList>(_onLoadMealList);
    on<SetCalorieGoal>(_onSetCalorieGoal);
  }

  Future<void> _onSetCalorieGoal(
      SetCalorieGoal event, Emitter<DietState> emit) async {
    await _dataSource.setCalorieGoal(event.goal);
    // Reload to reflect new goal
    final currentDate =
        state is DietLoaded ? (state as DietLoaded).selectedDate : DateTime.now();
    add(LoadMeals(date: currentDate));
  }

  Future<void> _onLoadMeals(LoadMeals event, Emitter<DietState> emit) async {
    // Preserve values from previous state BEFORE emitting DietLoading
    final prevChartDays = state is DietLoaded ? (state as DietLoaded).chartDays : 7;
    final prevMealListDays = state is DietLoaded ? (state as DietLoaded).mealListDays : 1;

    emit(DietLoading());
    try {
      final calorieGoal = await _dataSource.getCalorieGoal();
      final meals = await _dataSource.getMealsForDate(event.date);
      final summary = DailyNutritionSummary.fromMeals(meals, calorieGoal: calorieGoal);

      // Load chart range data
      final rangeData = await _dataSource.getMealsForRange(prevChartDays);
      final rangeSummaries = <DateTime, DailyNutritionSummary>{};
      for (final entry in rangeData.entries) {
        rangeSummaries[entry.key] = DailyNutritionSummary.fromMeals(entry.value);
      }

      // Load meal list items
      final mealListItems = prevMealListDays == 1
          ? meals
          : await _getMealsForDayRange(prevMealListDays);

      emit(DietLoaded(
        meals: meals,
        summary: summary,
        tipOfTheDay: NutritionTipsData.getTipOfTheDay(),
        selectedDate: event.date,
        rangeSummaries: rangeSummaries,
        chartDays: prevChartDays,
        mealListItems: mealListItems,
        mealListDays: prevMealListDays,
      ));
    } catch (e) {
      emit(DietError('Failed to load meals: $e'));
    }
  }

  Future<void> _onLoadTodayMeals(
      LoadTodayMeals event, Emitter<DietState> emit) async {
    add(LoadMeals(date: DateTime.now()));
  }

  Future<void> _onLogMeal(LogMeal event, Emitter<DietState> emit) async {
    await _dataSource.logMeal(event.meal);
    // Lightweight reload — just today's meals, no range data
    final currentDate =
        state is DietLoaded ? (state as DietLoaded).selectedDate : DateTime.now();
    add(LoadMeals(date: currentDate));
  }

  /// Log multiple meals at once (from a scan) — saves all, reloads ONCE
  Future<void> _onLogMealBatch(
      LogMealBatch event, Emitter<DietState> emit) async {
    for (final meal in event.meals) {
      await _dataSource.logMeal(meal);
    }
    final currentDate =
        state is DietLoaded ? (state as DietLoaded).selectedDate : DateTime.now();
    add(LoadMeals(date: currentDate));
  }

  Future<void> _onDeleteMeal(DeleteMeal event, Emitter<DietState> emit) async {
    await _dataSource.deleteMeal(event.key);
    final currentDate =
        state is DietLoaded ? (state as DietLoaded).selectedDate : DateTime.now();
    add(LoadMeals(date: currentDate));
  }

  Future<void> _onChangeDateFilter(
      ChangeDateFilter event, Emitter<DietState> emit) async {
    add(LoadMeals(date: event.date));
  }

  Future<void> _onLoadMealsForRange(
      LoadMealsForRange event, Emitter<DietState> emit) async {
    if (state is! DietLoaded) return;
    final current = state as DietLoaded;

    try {
      final rangeData = await _dataSource.getMealsForRange(event.days);
      final rangeSummaries = <DateTime, DailyNutritionSummary>{};
      for (final entry in rangeData.entries) {
        rangeSummaries[entry.key] = DailyNutritionSummary.fromMeals(entry.value);
      }

      emit(current.copyWithRange(
        rangeSummaries: rangeSummaries,
        chartDays: event.days,
      ));
    } catch (e) {
      // Keep current state on range load failure
    }
  }

  /// Load meal list for a given time range (Today/1W/2W/1M)
  Future<void> _onLoadMealList(
      LoadMealList event, Emitter<DietState> emit) async {
    if (state is! DietLoaded) return;
    final current = state as DietLoaded;

    try {
      final meals = event.days == 1
          ? current.meals
          : await _getMealsForDayRange(event.days);

      emit(current.copyWithMealList(
        mealListItems: meals,
        mealListDays: event.days,
      ));
    } catch (e) {
      // Keep current state on failure
    }
  }

  /// Get all meals for the last N days as a flat list (newest first)
  Future<List<MealLog>> _getMealsForDayRange(int days) async {
    final rangeData = await _dataSource.getMealsForRange(days);
    final allMeals = <MealLog>[];
    for (final entry in rangeData.entries) {
      allMeals.addAll(entry.value);
    }
    allMeals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allMeals;
  }
}
