import 'package:hive_flutter/hive_flutter.dart';
import '../models/goal_model.dart';

class GoalsLocalDataSource {
  static const String _boxName = 'goals_box';
  
  Future<Box<GoalModel>> get _box async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<GoalModel>(_boxName);
    }
    return Hive.box<GoalModel>(_boxName);
  }

  Future<List<GoalModel>> getAllGoals() async {
    final box = await _box;
    return box.values.toList();
  }

  Future<GoalModel?> getGoalById(String id) async {
    final box = await _box;
    return box.get(id);
  }

  Future<void> addGoal(GoalModel goal) async {
    final box = await _box;
    await box.put(goal.id, goal);
  }

  Future<void> updateGoal(GoalModel goal) async {
    final box = await _box;
    await box.put(goal.id, goal);
  }

  Future<void> deleteGoal(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  Future<void> clearAllGoals() async {
    final box = await _box;
    await box.clear();
  }
}
