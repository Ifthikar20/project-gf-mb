import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/goal_entity.dart';
import '../bloc/goals_bloc.dart';
import '../bloc/goals_state.dart';
import 'goal_picker_sheet.dart';

/// Home page section showing active goals with progress
class GoalsSection extends StatelessWidget {
  const GoalsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final isVintage = themeState.isVintage;
        final mode = themeState.mode;
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        final primaryColor = ThemeColors.primary(mode);
        final surfaceColor = ThemeColors.surface(mode);

        return BlocBuilder<GoalsBloc, GoalsState>(
          builder: (context, state) {
            List<GoalEntity> activeGoals = [];
            
            if (state is GoalsLoaded) {
              activeGoals = state.goals.where((g) => !g.isCompleted).take(3).toList();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'My Goals',
                            style: isVintage
                                ? GoogleFonts.playfairDisplay(
                                    color: textColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  )
                                : TextStyle(
                                    color: isVintage ? textColor : Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                          ),
                          if (activeGoals.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            _buildStreakBadge(activeGoals, primaryColor),
                          ],
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _showGoalPicker(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.add, color: primaryColor, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Add',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Goals content
                if (activeGoals.isEmpty)
                  _buildEmptyState(context, surfaceColor, textColor, textSecondary, primaryColor, isVintage)
                else
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: activeGoals.length,
                      itemBuilder: (context, index) {
                        return _buildGoalCard(
                          context,
                          activeGoals[index],
                          surfaceColor,
                          textColor,
                          textSecondary,
                          isVintage,
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStreakBadge(List<GoalEntity> goals, Color primaryColor) {
    // Find the highest streak among all goals
    int maxStreak = 0;
    for (final goal in goals) {
      if (goal.type == GoalType.dailyStreak && goal.streakDays > maxStreak) {
        maxStreak = goal.streakDays;
      }
    }
    
    if (maxStreak == 0) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFF97316)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            '$maxStreak',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    Color surfaceColor,
    Color textColor,
    Color textSecondary,
    Color primaryColor,
    bool isVintage,
  ) {
    return GestureDetector(
      onTap: () => _showGoalPicker(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isVintage ? primaryColor.withOpacity(0.2) : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.2), primaryColor.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.emoji_events, color: primaryColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set your first goal',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your wellness journey with smart goals',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(
    BuildContext context,
    GoalEntity goal,
    Color surfaceColor,
    Color textColor,
    Color textSecondary,
    bool isVintage,
  ) {
    final progress = goal.progress;
    final progressColor = _getGoalColor(goal);
    
    return GestureDetector(
      onTap: () {
        // Show progress feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${goal.title}: ${goal.currentValue}/${goal.targetValue} ${_getGoalUnit(goal)}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isVintage ? Colors.grey.withOpacity(0.2) : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getGoalIcon(goal),
                    color: progressColor,
                    size: 20,
                  ),
                ),
                // Circular progress
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 3,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                      Center(
                        child: Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Title
            Text(
              goal.title,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Progress text
            Text(
              '${goal.currentValue}/${goal.targetValue} ${_getGoalUnit(goal)}',
              style: TextStyle(
                color: textSecondary,
                fontSize: 12,
              ),
            ),
            // Streak indicator for streak goals
            if (goal.type == GoalType.dailyStreak && goal.streakDays > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Color(0xFFEF4444), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '${goal.streakDays} day streak',
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getGoalColor(GoalEntity goal) {
    switch (goal.type) {
      case GoalType.videoCompletion:
        return const Color(0xFF7C3AED);
      case GoalType.audioCompletion:
        return const Color(0xFF8B5CF6);
      case GoalType.dailyStreak:
        return const Color(0xFFEF4444);
      case GoalType.weeklyUsage:
        return const Color(0xFF3B82F6);
      case GoalType.categoryExplore:
        return const Color(0xFF06B6D4);
      case GoalType.watchTime:
        return const Color(0xFF10B981);
      case GoalType.manual:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getGoalIcon(GoalEntity goal) {
    switch (goal.type) {
      case GoalType.videoCompletion:
        return Icons.play_circle_filled;
      case GoalType.audioCompletion:
        return Icons.self_improvement;
      case GoalType.dailyStreak:
        return Icons.local_fire_department;
      case GoalType.weeklyUsage:
        return Icons.calendar_today;
      case GoalType.categoryExplore:
        return Icons.explore;
      case GoalType.watchTime:
        return Icons.timer;
      case GoalType.manual:
        return Icons.emoji_events;
    }
  }

  String _getGoalUnit(GoalEntity goal) {
    switch (goal.type) {
      case GoalType.videoCompletion:
        return 'videos';
      case GoalType.audioCompletion:
        return 'sessions';
      case GoalType.dailyStreak:
        return 'days';
      case GoalType.weeklyUsage:
        return 'days';
      case GoalType.categoryExplore:
        return 'categories';
      case GoalType.watchTime:
        return 'minutes';
      case GoalType.manual:
        return '';
    }
  }

  void _showGoalPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GoalPickerSheet(),
    );
  }
}
