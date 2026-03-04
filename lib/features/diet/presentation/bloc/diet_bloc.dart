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
    on<DeleteMeal>(_onDeleteMeal);
    on<ChangeDateFilter>(_onChangeDateFilter);
  }

  Future<void> _onLoadMeals(LoadMeals event, Emitter<DietState> emit) async {
    emit(DietLoading());
    try {
      final meals = await _dataSource.getMealsForDate(event.date);
      final summary = DailyNutritionSummary.fromMeals(meals);
      emit(DietLoaded(
        meals: meals,
        summary: summary,
        tipOfTheDay: NutritionTipsData.getTipOfTheDay(),
        selectedDate: event.date,
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
    // Reload for the current date
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
}
