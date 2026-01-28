import 'package:hive_flutter/hive_flutter.dart';
import '../models/goal_model.dart';

class GoalsLocalDataSource {
  static const String _boxName = 'goals_box';
  
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      if (!Hive.isBoxOpen(_boxName)) {
        await Hive.openBox<GoalModel>(_boxName);
      }
      _initialized = true;
    }
  }

  Future<Box<GoalModel>> get _box async {
    await _ensureInitialized();
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
