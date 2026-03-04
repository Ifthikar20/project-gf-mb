import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/diet_models.dart';

/// Individual meal card with meal type emoji, name, time, and macro badges
class MealTimelineCard extends StatelessWidget {
  final MealLog meal;
  final VoidCallback? onDelete;

  const MealTimelineCard({super.key, required this.meal, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleColor = isDark ? Colors.white38 : Colors.black38;

    final hour = meal.timestamp.hour > 12
        ? meal.timestamp.hour - 12
        : (meal.timestamp.hour == 0 ? 12 : meal.timestamp.hour);
    final amPm = meal.timestamp.hour >= 12 ? 'PM' : 'AM';
    final timeStr =
        '$hour:${meal.timestamp.minute.toString().padLeft(2, '0')} $amPm';

    return Dismissible(
      key: ValueKey(meal.key ?? meal.timestamp.millisecondsSinceEpoch),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded,
            color: Color(0xFFEF4444), size: 22),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.04),
          ),
        ),
        child: Row(
          children: [
            // Meal type emoji
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  meal.mealType.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name, type, time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${meal.mealType.label} · $timeStr',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: subtleColor,
                    ),
                  ),
                ],
              ),
            ),

            // Calories + macro badges
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${meal.calories} cal',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _macroBadge('P', meal.proteinGrams,
                        const Color(0xFF3B82F6), isDark),
                    const SizedBox(width: 4),
                    _macroBadge(
                        'C', meal.carbsGrams, const Color(0xFFF59E0B), isDark),
                    const SizedBox(width: 4),
                    _macroBadge(
                        'F', meal.fatGrams, const Color(0xFFEC4899), isDark),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroBadge(String label, int grams, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label${grams}g',
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
