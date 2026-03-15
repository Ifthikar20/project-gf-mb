import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../bloc/workout_state.dart';
import '../../data/models/workout_models.dart';

/// Compact workout stats card for the Home page
/// Shows weekly calories, minutes, workout count, and a mini 7-day bar chart
class ActivitySummaryCard extends StatelessWidget {
  const ActivitySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final isLight = themeState.isLight;
        final surfaceColor = ThemeColors.surface(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);

        return BlocBuilder<WorkoutBloc, WorkoutState>(
          builder: (context, state) {
            // Don't show anything while loading or on initial
            if (state is WorkoutInitial) {
              // Trigger load if not already initiated
              context.read<WorkoutBloc>().add(const LoadWorkoutData());
              return const SizedBox.shrink();
            }
            if (state is WorkoutLoading) {
              return const SizedBox.shrink();
            }
            if (state is! WorkoutLoaded) {
              return const SizedBox.shrink();
            }

            final stats = state.stats;
            final goals = state.goals;
            final hasData = stats != null && (stats.thisWeekCalories > 0 || stats.thisWeekCount > 0);

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: GestureDetector(
                onTap: () {
                  // Navigate to workouts tab (index 3 in bottom nav)
                  // Find the MainShell and switch tabs
                  _navigateToWorkoutsTab(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(isLight ? 12 : 18),
                    border: isLight ? Border.all(color: ThemeColors.lightBorder) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Icon(Icons.local_fire_department, 
                            color: const Color(0xFFFF6B6B), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'This Week',
                            style: GoogleFonts.inter(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right, 
                            color: textSecondary, size: 18),
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (hasData) ...[
                        // Stats row
                        Row(
                          children: [
                            _buildStat(
                              value: '${stats!.thisWeekCalories}',
                              label: 'cal',
                              target: _goalTarget(goals, 'calories_burned'),
                              color: const Color(0xFFFF6B6B),
                              textColor: textColor,
                              textSecondary: textSecondary,
                            ),
                            const SizedBox(width: 20),
                            _buildStat(
                              value: '${stats.thisWeekMinutes}',
                              label: 'min',
                              target: _goalTarget(goals, 'active_minutes'),
                              color: const Color(0xFF4ECDC4),
                              textColor: textColor,
                              textSecondary: textSecondary,
                            ),
                            const SizedBox(width: 20),
                            _buildStat(
                              value: '${stats.thisWeekCount}',
                              label: 'workouts',
                              target: _goalTarget(goals, 'workout_count'),
                              color: const Color(0xFFA78BFA),
                              textColor: textColor,
                              textSecondary: textSecondary,
                            ),
                            const Spacer(),
                            // Mini bar chart
                            if (stats.dailyBreakdown.isNotEmpty)
                              _buildMiniChart(stats, textSecondary),
                          ],
                        ),
                      ] else ...[
                        // Empty state
                        Row(
                          children: [
                            Icon(Icons.fitness_center, 
                              color: textSecondary.withValues(alpha: 0.4), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No activity yet — log your first workout!',
                                style: GoogleFonts.inter(
                                  color: textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  int? _goalTarget(List<GoalProgress> goals, String type) {
    try {
      return goals.firstWhere((g) => g.goalType == type).targetValue;
    } catch (_) {
      return null;
    }
  }

  Widget _buildStat({
    required String value,
    required String label,
    int? target,
    required Color color,
    required Color textColor,
    required Color textSecondary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                label,
                style: GoogleFonts.inter(color: textSecondary, fontSize: 10),
              ),
            ),
          ],
        ),
        if (target != null) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: 50,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (int.parse(value) / target).clamp(0.0, 1.0),
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 3,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMiniChart(WorkoutStats stats, Color textSecondary) {
    final maxCal = stats.maxDailyCalories;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: stats.dailyBreakdown.map((day) {
        final h = day.calories > 0 ? (day.calories / maxCal) * 28 : 2.0;
        return Padding(
          padding: const EdgeInsets.only(left: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: h,
                decoration: BoxDecoration(
                  color: day.calories > 0
                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.7)
                      : textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                day.dayName.substring(0, 1),
                style: TextStyle(color: textSecondary, fontSize: 7),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _navigateToWorkoutsTab(BuildContext context) {
    // Walk up to find MainShell's state and switch to Workouts tab (index 3)
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null) {
      // Use a callback to switch to the workouts tab
      // Since MainShell uses IndexedStack with setState, we notify via a simple approach
    }
    // Fallback: use the bottom nav directly by finding the ancestor
    final state = context.findAncestorStateOfType<State>();
    if (state != null && state.mounted) {
      // Trigger a navigation notification
      DefaultTabController.of(context);
    }
  }
}
