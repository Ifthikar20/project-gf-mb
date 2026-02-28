import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../bloc/workout_state.dart';
import '../../data/models/workout_models.dart';
import 'log_workout_sheet.dart';
import 'body_profile_page.dart';
import 'goals_setup_page.dart';

/// Workout Hub — main tab page showing weekly stats, daily chart, and recent workouts
class WorkoutHubPage extends StatefulWidget {
  const WorkoutHubPage({super.key});

  @override
  State<WorkoutHubPage> createState() => _WorkoutHubPageState();
}

class _WorkoutHubPageState extends State<WorkoutHubPage> {
  @override
  void initState() {
    super.initState();
    context.read<WorkoutBloc>().add(const LoadWorkoutData());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final isVintage = themeState.isVintage;
        final bgColor = ThemeColors.background(mode);
        final surfaceColor = ThemeColors.surface(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        final primaryColor = ThemeColors.primary(mode);

        return Scaffold(
          backgroundColor: bgColor,
          body: BlocBuilder<WorkoutBloc, WorkoutState>(
            builder: (context, state) {
              if (state is WorkoutLoading) {
                return Center(
                  child: CircularProgressIndicator(color: primaryColor),
                );
              }

              if (state is WorkoutError) {
                return _buildErrorState(state.message, textColor, textSecondary, primaryColor);
              }

              if (state is WorkoutLoaded) {
                return _buildLoadedState(
                  state, bgColor, surfaceColor, textColor, textSecondary, primaryColor, isVintage,
                );
              }

              // Initial state — trigger load
              return Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            },
          ),
          floatingActionButton: BlocBuilder<WorkoutBloc, WorkoutState>(
            builder: (context, state) {
              if (state is! WorkoutLoaded) return const SizedBox.shrink();
              return FloatingActionButton.extended(
                onPressed: () => _showLogWorkout(context, state),
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: Text(
                  'Log Workout',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                elevation: 4,
              );
            },
          ),
        );
      },
    );
  }

  void _showLogWorkout(BuildContext context, WorkoutLoaded state) {
    if (!state.hasBodyProfile) {
      // Need body profile first
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BodyProfilePage()),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<WorkoutBloc>(),
        child: LogWorkoutSheet(workoutTypes: state.workoutTypes),
      ),
    );
  }

  Widget _buildErrorState(String message, Color textColor, Color textSecondary, Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: textSecondary, size: 48),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: textColor, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<WorkoutBloc>().add(const LoadWorkoutData()),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedState(
    WorkoutLoaded state,
    Color bgColor,
    Color surfaceColor,
    Color textColor,
    Color textSecondary,
    Color primaryColor,
    bool isVintage,
  ) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Workouts',
                    style: isVintage
                        ? GoogleFonts.playfairDisplay(color: textColor, fontSize: 28, fontWeight: FontWeight.bold)
                        : GoogleFonts.poppins(color: textColor, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.tune, color: textSecondary),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => BlocProvider.value(
                        value: context.read<WorkoutBloc>(),
                        child: const GoalsSetupPage(),
                      )),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Weekly Summary Card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _buildWeeklySummary(state, surfaceColor, textColor, textSecondary, isVintage),
          ),
        ),

        // Daily Bar Chart
        if (state.stats != null && state.stats!.dailyBreakdown.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _buildDailyChart(state.stats!, surfaceColor, textColor, textSecondary, isVintage),
            ),
          ),

        // Body profile prompt
        if (!state.hasBodyProfile)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _buildBodyProfilePrompt(surfaceColor, textColor, textSecondary),
            ),
          ),

        // Recent Workouts header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text(
              'Recent Workouts',
              style: isVintage
                  ? GoogleFonts.playfairDisplay(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)
                  : GoogleFonts.poppins(color: textColor, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        // Workout history list
        if (state.recentWorkouts.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _buildEmptyState(surfaceColor, textColor, textSecondary),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: EdgeInsets.fromLTRB(20, index == 0 ? 0 : 8, 20, 0),
                child: _buildWorkoutCard(state.recentWorkouts[index], surfaceColor, textColor, textSecondary, isVintage),
              ),
              childCount: state.recentWorkouts.length,
            ),
          ),

        // Bottom padding for FAB
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _buildWeeklySummary(WorkoutLoaded state, Color surfaceColor, Color textColor, Color textSecondary, bool isVintage) {
    final stats = state.stats;
    final goals = state.goals;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(isVintage ? 12 : 20),
        border: isVintage ? Border.all(color: Colors.white10) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department, color: const Color(0xFFFF6B6B), size: 20),
              const SizedBox(width: 6),
              Text(
                'This Week',
                style: GoogleFonts.inter(color: textColor, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 3 progress bars
          Row(
            children: [
              Expanded(child: _buildProgressStat(
                label: 'Calories',
                current: stats?.thisWeekCalories ?? 0,
                target: _getGoalTarget(goals, 'calories_burned'),
                unit: 'cal',
                color: const Color(0xFFFF6B6B),
                textColor: textColor,
                textSecondary: textSecondary,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildProgressStat(
                label: 'Minutes',
                current: stats?.thisWeekMinutes ?? 0,
                target: _getGoalTarget(goals, 'active_minutes'),
                unit: 'min',
                color: const Color(0xFF4ECDC4),
                textColor: textColor,
                textSecondary: textSecondary,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildProgressStat(
                label: 'Workouts',
                current: stats?.thisWeekCount ?? 0,
                target: _getGoalTarget(goals, 'workout_count'),
                unit: '',
                color: const Color(0xFFA78BFA),
                textColor: textColor,
                textSecondary: textSecondary,
              )),
            ],
          ),
        ],
      ),
    );
  }

  int? _getGoalTarget(List<GoalProgress> goals, String type) {
    try {
      return goals.firstWhere((g) => g.goalType == type).targetValue;
    } catch (_) {
      return null;
    }
  }

  Widget _buildProgressStat({
    required String label,
    required int current,
    int? target,
    required String unit,
    required Color color,
    required Color textColor,
    required Color textSecondary,
  }) {
    final progress = target != null && target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$current${unit.isNotEmpty ? ' $unit' : ''}',
          style: GoogleFonts.inter(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (target != null) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '/ $target',
            style: GoogleFonts.inter(color: textSecondary, fontSize: 10),
          ),
        ] else
          Text(label, style: GoogleFonts.inter(color: textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildDailyChart(WorkoutStats stats, Color surfaceColor, Color textColor, Color textSecondary, bool isVintage) {
    final maxCal = stats.maxDailyCalories;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(isVintage ? 12 : 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: stats.dailyBreakdown.map((day) {
          final height = day.calories > 0 ? (day.calories / maxCal) * 48 : 2.0;
          final isToday = _isToday(day.date);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (day.calories > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${day.calories}',
                    style: GoogleFonts.inter(color: textSecondary, fontSize: 8),
                  ),
                ),
              Container(
                width: 28,
                height: height.toDouble(),
                decoration: BoxDecoration(
                  color: day.calories > 0
                      ? (isToday ? const Color(0xFF8B5CF6) : const Color(0xFF8B5CF6).withValues(alpha: 0.4))
                      : textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                day.dayName.substring(0, 2),
                style: GoogleFonts.inter(
                  color: isToday ? textColor : textSecondary,
                  fontSize: 10,
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  bool _isToday(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      return date.year == now.year && date.month == now.month && date.day == now.day;
    } catch (_) {
      return false;
    }
  }

  Widget _buildBodyProfilePrompt(Color surfaceColor, Color textColor, Color textSecondary) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BodyProfilePage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.monitor_weight_outlined, color: Color(0xFF8B5CF6), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set Your Weight', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('Required for calorie calculations', style: TextStyle(color: textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF8B5CF6), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color surfaceColor, Color textColor, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.fitness_center, color: textSecondary.withValues(alpha: 0.3), size: 48),
          const SizedBox(height: 12),
          Text('No workouts yet', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('Tap the button below to log your first workout!', style: TextStyle(color: textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(WorkoutLogModel workout, Color surfaceColor, Color textColor, Color textSecondary, bool isVintage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(isVintage ? 10 : 14),
      ),
      child: Row(
        children: [
          // Type icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (workout.workoutType?.categoryColor ?? const Color(0xFF8B5CF6)).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              workout.workoutType?.icon ?? Icons.fitness_center,
              color: workout.workoutType?.categoryColor ?? const Color(0xFF8B5CF6),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.workoutName,
                  style: GoogleFonts.inter(color: textColor, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _formatTime(workout.startedAt),
                      style: GoogleFonts.inter(color: textSecondary, fontSize: 12),
                    ),
                    Text(' · ', style: TextStyle(color: textSecondary)),
                    Text(
                      '${workout.durationMinutes} min',
                      style: GoogleFonts.inter(color: textSecondary, fontSize: 12),
                    ),
                    if (workout.hasMood) ...[
                      Text(' · ', style: TextStyle(color: textSecondary)),
                      Text(workout.moodEmoji, style: const TextStyle(fontSize: 12)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  workout.isManual ? 'Manual entry' : 'Apple Health',
                  style: GoogleFonts.inter(color: textSecondary.withValues(alpha: 0.6), fontSize: 10),
                ),
              ],
            ),
          ),
          // Calories
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${workout.caloriesBurned}',
                style: GoogleFonts.inter(color: const Color(0xFFFF6B6B), fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'cal',
                style: GoogleFonts.inter(color: textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour:${dt.minute.toString().padLeft(2, '0')} $amPm';

    if (date == today) return 'Today $time';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday $time';
    return '${dt.month}/${dt.day} $time';
  }
}
