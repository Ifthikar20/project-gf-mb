import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../workouts/presentation/bloc/workout_bloc.dart';
import '../../../workouts/presentation/bloc/workout_event.dart';
import '../../../workouts/presentation/bloc/workout_state.dart';
import '../../../workouts/data/models/workout_models.dart';
import '../../data/models/burn_goal_model.dart';

/// Goals section — shows weekly targets + food-linked burn goals.
class GoalsSection extends StatefulWidget {
  const GoalsSection({super.key});

  @override
  State<GoalsSection> createState() => _GoalsSectionState();
}

class _GoalsSectionState extends State<GoalsSection> {
  List<BurnGoal> _burnGoals = [];

  @override
  void initState() {
    super.initState();
    _loadBurnGoals();
  }

  Future<void> _loadBurnGoals() async {
    final goals = await BurnGoalStorage.instance.getActiveGoals();
    if (mounted) setState(() => _burnGoals = goals);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final isLight = themeState.isLight;
        final mode = themeState.mode;
        final text = ThemeColors.textPrimary(mode);
        final subtle = ThemeColors.textSecondary(mode);
        final primary = ThemeColors.primary(mode);
        final surface = ThemeColors.surface(mode);
        final border = isLight ? const Color(0xFFE8E8EC) : const Color(0xFF2A2A2A);

        return BlocBuilder<WorkoutBloc, WorkoutState>(
          builder: (context, ws) {
            if (ws is WorkoutInitial) {
              context.read<WorkoutBloc>().add(const LoadWorkoutData());
            }
            final weeklyGoals = ws is WorkoutLoaded ? ws.goals : <GoalProgress>[];
            final hasBurnGoals = _burnGoals.isNotEmpty;
            final hasWeeklyGoals = weeklyGoals.isNotEmpty;

            if (!hasBurnGoals && !hasWeeklyGoals) {
              return _buildEmpty(context, surface, text, subtle, primary, border, isLight);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Text('My Goals', style: GoogleFonts.inter(color: text, fontSize: 20, fontWeight: FontWeight.bold)),
                ),

                // Weekly goals
                if (hasWeeklyGoals) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Text('Weekly', style: GoogleFonts.inter(color: subtle, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: weeklyGoals.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => _weeklyCard(weeklyGoals[i], surface, text, subtle, border, isLight),
                    ),
                  ),
                ],

                // Burn goals
                if (hasBurnGoals) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        Text('Burn It Off', style: GoogleFonts.inter(color: subtle, fontSize: 12, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(
                          '${_burnGoals.where((g) => g.isComplete).length}/${_burnGoals.length} done',
                          style: GoogleFonts.inter(color: subtle, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: _burnGoals.take(5).map((g) => _burnGoalRow(g, surface, text, subtle, border, primary, isLight)).toList(),
                    ),
                  ),

                  // Daily summary
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: FutureBuilder(
                      future: BurnGoalStorage.instance.getDailySummary(),
                      builder: (_, snap) {
                        if (!snap.hasData) return const SizedBox.shrink();
                        final s = snap.data!;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isLight ? const Color(0xFFF8F8FA) : surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Image.asset('assets/images/fire-logo-calories.png', width: 14, height: 14, color: const Color(0xFFEF4444)),
                              const SizedBox(width: 6),
                              Text('Today: ${s.totalCompleted} / ${s.totalTarget} cal burned', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: text)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _weeklyCard(GoalProgress goal, Color surface, Color text, Color subtle, Color border, bool isLight) {
    final pct = (goal.progressPercent / 100.0).clamp(0.0, 1.0);
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(goal.icon, color: goal.color, size: 16),
              const Spacer(),
              Text('${goal.progressPercent}%', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: goal.isComplete ? const Color(0xFF22C55E) : goal.color)),
            ],
          ),
          const Spacer(),
          Text('${goal.currentValue}/${goal.targetValue}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
          const SizedBox(height: 2),
          Text('${goal.label} ${goal.unit}', style: GoogleFonts.inter(fontSize: 10, color: subtle)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                backgroundColor: goal.color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(goal.isComplete ? const Color(0xFF22C55E) : goal.color),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _burnGoalRow(BurnGoal goal, Color surface, Color text, Color subtle, Color border, Color primary, bool isLight) {
    IconData icon;
    switch (goal.icon) {
      case 'walking': icon = Icons.directions_walk; break;
      case 'running': icon = Icons.directions_run; break;
      case 'cycling': icon = Icons.directions_bike; break;
      case 'swimming': icon = Icons.pool; break;
      default: icon = Icons.fitness_center;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: goal.isComplete ? const Color(0xFF22C55E).withOpacity(0.3) : border),
      ),
      child: Row(
        children: [
          // Meal emoji + icon
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: goal.isComplete ? const Color(0xFF22C55E).withOpacity(0.1) : primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              goal.isComplete ? Icons.check_circle : icon,
              color: goal.isComplete ? const Color(0xFF22C55E) : primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${goal.mealName} → ${goal.activity}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: goal.isComplete ? subtle : text,
                          decoration: goal.isComplete ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      goal.isComplete ? 'Done' : '${goal.progressPercent}%',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: goal.isComplete ? const Color(0xFF22C55E) : primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: goal.progress),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (_, val, __) => LinearProgressIndicator(
                      value: val,
                      backgroundColor: (goal.isComplete ? const Color(0xFF22C55E) : primary).withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(goal.isComplete ? const Color(0xFF22C55E) : primary),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  goal.isComplete
                      ? 'Completed ${goal.targetMinutes} min'
                      : '${goal.remainingMinutes} min left · ${goal.remainingCalories} cal to burn',
                  style: GoogleFonts.inter(fontSize: 10, color: subtle),
                ),
              ],
            ),
          ),
          // Mark done button (if not complete)
          if (!goal.isComplete) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                HapticFeedback.lightImpact();
                await BurnGoalStorage.instance.markComplete(goal.id);
                _loadBurnGoals();
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check, color: Color(0xFF22C55E), size: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, Color surface, Color text, Color subtle, Color primary, Color border, bool isLight) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Goals', style: GoogleFonts.inter(color: text, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.emoji_events, color: primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No goals yet', style: GoogleFonts.inter(color: text, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Scan food and tap "Add" on burn suggestions to set goals', style: GoogleFonts.inter(color: subtle, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
