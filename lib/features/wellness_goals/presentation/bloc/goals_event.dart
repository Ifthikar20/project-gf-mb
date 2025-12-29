import 'package:equatable/equatable.dart';
import '../../domain/entities/goal_entity.dart';

abstract class GoalsEvent extends Equatable {
  const GoalsEvent();

  @override
  List<Object?> get props => [];
}

class LoadGoals extends GoalsEvent {}

class AddGoal extends GoalsEvent {
  final GoalEntity goal;

  const AddGoal(this.goal);

  @override
  List<Object?> get props => [goal];
}

class UpdateGoal extends GoalsEvent {
  final GoalEntity goal;

  const UpdateGoal(this.goal);

  @override
  List<Object?> get props => [goal];
}

class DeleteGoal extends GoalsEvent {
  final String goalId;

  const DeleteGoal(this.goalId);

  @override
  List<Object?> get props => [goalId];
}

class UpdateGoalProgress extends GoalsEvent {
  final String goalId;
  final int newProgress;

  const UpdateGoalProgress(this.goalId, this.newProgress);

  @override
  List<Object?> get props => [goalId, newProgress];
}
