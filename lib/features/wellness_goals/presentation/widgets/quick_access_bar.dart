import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../workouts/presentation/pages/workout_check_page.dart';
import '../../presentation/pages/wellness_checkin_page.dart';

/// Quick-access shortcuts bar for fast navigation to key features.
class QuickAccessBar extends StatelessWidget {
  /// Optional callback to switch the bottom nav tab index.
  final void Function(int tabIndex)? onSwitchTab;

  const QuickAccessBar({super.key, this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black54;

    return SizedBox(
      height: 86,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          _ShortcutItem(
            icon: Icons.self_improvement_rounded,
            label: 'Meditate',
            color: const Color(0xFF8B5CF6),
            textColor: textColor,
            onTap: () => onSwitchTab?.call(2),
          ),
          _ShortcutItem(
            icon: Icons.play_circle_rounded,
            label: 'Videos',
            color: const Color(0xFFEF4444),
            textColor: textColor,
            onTap: () => context.push(AppRouter.videos),
          ),
          _ShortcutItem(
            icon: Icons.fitness_center_rounded,
            label: 'Workout',
            color: const Color(0xFF22C55E),
            textColor: textColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WorkoutCheckPage()),
              );
            },
          ),
          _ShortcutItem(
            icon: Icons.favorite_rounded,
            label: 'Check In',
            color: const Color(0xFFF59E0B),
            textColor: textColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WellnessCheckInPage()),
              );
            },
          ),
          _ShortcutItem(
            icon: Icons.air_rounded,
            label: 'Breathe',
            color: const Color(0xFF06B6D4),
            textColor: textColor,
            onTap: () => context.push(AppRouter.breathingExercise),
          ),
          _ShortcutItem(
            icon: Icons.auto_stories_rounded,
            label: 'Learn',
            color: const Color(0xFF3B82F6),
            textColor: textColor,
            onTap: () => onSwitchTab?.call(3),
          ),
        ],
      ),
    );
  }
}

class _ShortcutItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ShortcutItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
