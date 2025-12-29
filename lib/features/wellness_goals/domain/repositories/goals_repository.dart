import '../entities/goal_entity.dart';

abstract class GoalsRepository {
  Future<List<GoalEntity>> getAllGoals();
  Future<GoalEntity?> getGoalById(String id);
  Future<void> addGoal(GoalEntity goal);
  Future<void> updateGoal(GoalEntity goal);
  Future<void> deleteGoal(String id);
}
