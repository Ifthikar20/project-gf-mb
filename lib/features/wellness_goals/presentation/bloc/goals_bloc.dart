import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/goals_repository.dart';
import 'goals_event.dart';
import 'goals_state.dart';

class GoalsBloc extends Bloc<GoalsEvent, GoalsState> {
  final GoalsRepository repository;

  GoalsBloc({required this.repository}) : super(GoalsInitial()) {
    on<LoadGoals>(_onLoadGoals);
    on<AddGoal>(_onAddGoal);
    on<UpdateGoal>(_onUpdateGoal);
    on<DeleteGoal>(_onDeleteGoal);
    on<UpdateGoalProgress>(_onUpdateGoalProgress);
  }

  Future<void> _onLoadGoals(LoadGoals event, Emitter<GoalsState> emit) async {
    emit(GoalsLoading());
    try {
      final goals = await repository.getAllGoals();
      emit(GoalsLoaded(goals));
    } catch (e) {
      emit(GoalsError(e.toString()));
    }
  }

  Future<void> _onAddGoal(AddGoal event, Emitter<GoalsState> emit) async {
    try {
      await repository.addGoal(event.goal);
      final goals = await repository.getAllGoals();
      emit(GoalsLoaded(goals));
    } catch (e) {
      emit(GoalsError(e.toString()));
    }
  }

  Future<void> _onUpdateGoal(UpdateGoal event, Emitter<GoalsState> emit) async {
    try {
      await repository.updateGoal(event.goal);
      final goals = await repository.getAllGoals();
      emit(GoalsLoaded(goals));
    } catch (e) {
      emit(GoalsError(e.toString()));
    }
  }

  Future<void> _onDeleteGoal(DeleteGoal event, Emitter<GoalsState> emit) async {
    try {
      await repository.deleteGoal(event.goalId);
      final goals = await repository.getAllGoals();
      emit(GoalsLoaded(goals));
    } catch (e) {
      emit(GoalsError(e.toString()));
    }
  }

  Future<void> _onUpdateGoalProgress(
      UpdateGoalProgress event, Emitter<GoalsState> emit) async {
    try {
      final goal = await repository.getGoalById(event.goalId);
      if (goal != null) {
        final updatedGoal = goal.copyWith(
          currentValue: event.newProgress,
          isCompleted: event.newProgress >= goal.targetValue,
        );
        await repository.updateGoal(updatedGoal);
        final goals = await repository.getAllGoals();
        emit(GoalsLoaded(goals));
      }
    } catch (e) {
      emit(GoalsError(e.toString()));
    }
  }
}
