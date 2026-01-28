import 'package:flutter/foundation.dart';
import '../../../features/wellness_goals/domain/entities/goal_entity.dart';
import '../../../features/wellness_goals/data/models/goal_model.dart';
import '../../../features/wellness_goals/data/datasources/goals_local_datasource.dart';

/// Service for automatically tracking goal progress based on user activity.
/// 
/// This service listens for content completion events and updates
/// matching goals automatically.
class GoalTrackingService {
  static final GoalTrackingService _instance = GoalTrackingService._internal();
  static GoalTrackingService get instance => _instance;
  
  GoalTrackingService._internal();

  GoalsLocalDataSource? _dataSource;
  
  /// Maximum number of active goals allowed
  static const int maxActiveGoals = 5;
  
  /// Minimum percentage of content to watch to count as "complete"
  static const double completionThreshold = 0.80; // 80%
  
  /// Initialize with data source
  void initialize(GoalsLocalDataSource dataSource) {
    _dataSource = dataSource;
  }

  /// Track video completion
  /// Called when user completes watching a video (>80% watched)
  Future<void> trackVideoCompletion({
    required String videoId,
    required String category,
    required int durationSeconds,
  }) async {
    debugPrint('GoalTrackingService: Video completed - $videoId');
    
    await _updateMatchingGoals(
      type: GoalType.videoCompletion,
      contentId: videoId,
      category: category,
      durationSeconds: durationSeconds,
    );
    
    // Also update streak goals
    await _updateStreakGoals();
  }

  /// Track audio/meditation completion
  /// Called when user completes listening to audio (>80% played)
  Future<void> trackAudioCompletion({
    required String audioId,
    required String category,
    required int durationSeconds,
  }) async {
    debugPrint('GoalTrackingService: Audio completed - $audioId');
    
    await _updateMatchingGoals(
      type: GoalType.audioCompletion,
      contentId: audioId,
      category: category,
      durationSeconds: durationSeconds,
    );
    
    // Also update streak goals
    await _updateStreakGoals();
  }

  /// Track category exploration
  /// Called when user views a new category
  Future<void> trackCategoryView({
    required String categoryId,
  }) async {
    debugPrint('GoalTrackingService: Category viewed - $categoryId');
    
    await _updateMatchingGoals(
      type: GoalType.categoryExplore,
      contentId: categoryId,
    );
  }

  /// Track daily app usage
  /// Called on app open to maintain streak
  Future<void> trackDailyUsage() async {
    debugPrint('GoalTrackingService: Tracking daily usage');
    await _updateStreakGoals();
  }

  /// Update all goals matching the given type
  Future<void> _updateMatchingGoals({
    required GoalType type,
    String? contentId,
    String? category,
    int? durationSeconds,
  }) async {
    if (_dataSource == null) {
      debugPrint('GoalTrackingService: DataSource not initialized');
      return;
    }

    try {
      final goals = await _dataSource!.getAllGoals();
      final now = DateTime.now();
      
      for (final goal in goals) {
        // Skip if goal type doesn't match
        if (goal.type != type) continue;
        
        // Skip if already completed
        if (goal.isCompleted) continue;
        
        // Check if period needs reset
        if (goal.needsPeriodReset(now)) {
          final resetGoal = goal.resetForNewPeriod(now);
          await _dataSource!.updateGoal(GoalModel.fromEntity(resetGoal));
          continue; // After reset, don't increment in the same call
        }
        
        // Skip if content already tracked (prevent double counting)
        if (contentId != null && goal.trackedIds.contains(contentId)) {
          debugPrint('GoalTrackingService: Content $contentId already tracked for goal ${goal.id}');
          continue;
        }
        
        // Calculate increment
        int increment = 1;
        if (type == GoalType.watchTime && durationSeconds != null) {
          increment = (durationSeconds / 60).round(); // Convert to minutes
        }
        
        // Update the goal
        final newValue = goal.currentValue + increment;
        final isNowCompleted = newValue >= goal.targetValue;
        
        // Add content ID to tracked set
        Set<String> newTrackedIds = Set.from(goal.trackedIds);
        if (contentId != null) {
          newTrackedIds.add(contentId);
        }
        
        final updatedGoal = goal.copyWith(
          currentValue: newValue,
          isCompleted: isNowCompleted,
          trackedIds: newTrackedIds,
          lastActivityDate: now,
        );
        
        await _dataSource!.updateGoal(GoalModel.fromEntity(updatedGoal));
        debugPrint('GoalTrackingService: Updated goal ${goal.title} to $newValue/${goal.targetValue}');
      }
    } catch (e) {
      debugPrint('GoalTrackingService: Error updating goals - $e');
    }
  }

  /// Update streak goals based on daily activity
  Future<void> _updateStreakGoals() async {
    if (_dataSource == null) return;

    try {
      final goals = await _dataSource!.getAllGoals();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      for (final goal in goals) {
        // Only process streak goals
        if (goal.type != GoalType.dailyStreak && goal.type != GoalType.weeklyUsage) {
          continue;
        }
        
        // Skip if already completed
        if (goal.isCompleted) continue;
        
        // Check if we already tracked activity today
        if (goal.lastActivityDate != null) {
          final lastDate = DateTime(
            goal.lastActivityDate!.year,
            goal.lastActivityDate!.month,
            goal.lastActivityDate!.day,
          );
          if (lastDate.isAtSameMomentAs(today)) {
            // Already tracked today
            continue;
          }
        }
        
        int newStreakDays = goal.streakDays;
        int newCurrentValue = goal.currentValue;
        
        if (goal.type == GoalType.dailyStreak) {
          // Check if streak is still valid (with 1-day forgiveness)
          if (!goal.isStreakValid(now)) {
            // Streak broken - reset
            newStreakDays = 1;
            newCurrentValue = 1;
          } else {
            // Continue streak
            newStreakDays = goal.streakDays + 1;
            newCurrentValue = newStreakDays;
          }
        } else if (goal.type == GoalType.weeklyUsage) {
          // Check if we need to reset for new week
          if (goal.needsPeriodReset(now)) {
            final resetGoal = goal.resetForNewPeriod(now);
            await _dataSource!.updateGoal(GoalModel.fromEntity(resetGoal.copyWith(
              currentValue: 1,
              lastActivityDate: now,
            )));
            continue;
          }
          
          // Increment days used this week
          newCurrentValue = goal.currentValue + 1;
        }
        
        final isNowCompleted = newCurrentValue >= goal.targetValue;
        
        final updatedGoal = goal.copyWith(
          currentValue: newCurrentValue,
          streakDays: newStreakDays,
          lastActivityDate: now,
          isCompleted: isNowCompleted,
        );
        
        await _dataSource!.updateGoal(GoalModel.fromEntity(updatedGoal));
        debugPrint('GoalTrackingService: Updated streak goal ${goal.title} - streak: $newStreakDays, value: $newCurrentValue');
      }
    } catch (e) {
      debugPrint('GoalTrackingService: Error updating streak goals - $e');
    }
  }

  /// Get active goals count
  Future<int> getActiveGoalsCount() async {
    if (_dataSource == null) return 0;
    final goals = await _dataSource!.getAllGoals();
    return goals.where((g) => !g.isCompleted).length;
  }

  /// Check if user can add more goals
  Future<bool> canAddMoreGoals() async {
    final count = await getActiveGoalsCount();
    return count < maxActiveGoals;
  }
}
