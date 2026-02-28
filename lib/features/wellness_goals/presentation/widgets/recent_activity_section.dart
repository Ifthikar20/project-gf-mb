import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../workouts/presentation/bloc/workout_bloc.dart';
import '../../../workouts/presentation/bloc/workout_state.dart';
import '../../../workouts/data/models/workout_models.dart';

/// "Recent Activity" section showing latest workouts, styled like Cal AI's
/// "Recently uploaded" food section.
class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<WorkoutBloc, WorkoutState>(
      builder: (context, state) {
        List<WorkoutLogModel> recents = [];
        if (state is WorkoutLoaded) {
          recents = state.recentWorkouts.take(5).toList();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Recent activity',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              if (recents.isEmpty)
                _buildEmptyState(isDark)
              else
                ...recents.map(
                  (workout) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RecentActivityTile(
                      workout: workout,
                      isDark: isDark,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center_rounded,
            color: isDark ? Colors.white24 : Colors.black12,
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            'No activity yet',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black38,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Log your first workout to see it here',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityTile extends StatelessWidget {
  final WorkoutLogModel workout;
  final bool isDark;

  const _RecentActivityTile({
    required this.workout,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor =
        workout.workoutType?.categoryColor ?? const Color(0xFF8B5CF6);
    final icon = workout.workoutType?.icon ?? Icons.fitness_center;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          // Icon thumbnail
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: categoryColor, size: 24),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        workout.workoutName,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatTime(workout.startedAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 14,
                      color: const Color(0xFFFF6B6B),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${workout.caloriesBurned} Calories',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${workout.durationMinutes}m',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    if (workout.hasMood) ...[
                      const SizedBox(width: 8),
                      Text(
                        workout.moodLabel,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12
        ? dt.hour - 12
        : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'pm' : 'am';
    return '$hour:${dt.minute.toString().padLeft(2, '0')}$amPm';
  }
}
