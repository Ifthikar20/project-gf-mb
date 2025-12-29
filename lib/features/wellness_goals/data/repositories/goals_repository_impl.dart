import '../../domain/entities/goal_entity.dart';
import '../../domain/repositories/goals_repository.dart';
import '../datasources/goals_local_datasource.dart';
import '../models/goal_model.dart';

class GoalsRepositoryImpl implements GoalsRepository {
  final GoalsLocalDataSource localDataSource;

  GoalsRepositoryImpl({required this.localDataSource});

  @override
  Future<List<GoalEntity>> getAllGoals() async {
    final models = await localDataSource.getAllGoals();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<GoalEntity?> getGoalById(String id) async {
    final model = await localDataSource.getGoalById(id);
    return model?.toEntity();
  }

  @override
  Future<void> addGoal(GoalEntity goal) async {
    final model = GoalModel.fromEntity(goal);
    await localDataSource.addGoal(model);
  }

  @override
  Future<void> updateGoal(GoalEntity goal) async {
    final model = GoalModel.fromEntity(goal);
    await localDataSource.updateGoal(model);
  }

  @override
  Future<void> deleteGoal(String id) async {
    await localDataSource.deleteGoal(id);
  }
}
