import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cal AI-inspired weekly day selector showing Sun–Sat with dates
class WeeklyDaySelector extends StatelessWidget {
  final int selectedDayIndex;
  final ValueChanged<int> onDaySelected;

  const WeeklyDaySelector({
    super.key,
    required this.selectedDayIndex,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Find the start of the current week (Sunday)
    final weekStart = now.subtract(Duration(days: now.weekday % 7));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final day = weekStart.add(Duration(days: index));
          final isSelected = index == selectedDayIndex;
          final isToday = day.day == now.day &&
              day.month == now.month &&
              day.year == now.year;

          return GestureDetector(
            onTap: () => onDaySelected(index),
            child: _DayCircle(
              dayLabel: _dayLabels[index],
              date: day.day,
              isSelected: isSelected,
              isToday: isToday,
            ),
          );
        }),
      ),
    );
  }

  static const List<String> _dayLabels = [
    'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat',
  ];
}

class _DayCircle extends StatelessWidget {
  final String dayLabel;
  final int date;
  final bool isSelected;
  final bool isToday;

  const _DayCircle({
    required this.dayLabel,
    required this.date,
    required this.isSelected,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colors
    final selectedBg = isDark ? Colors.white : Colors.black;
    final selectedText = isDark ? Colors.black : Colors.white;
    final todayBg = isDark
        ? Colors.white.withOpacity(0.15)
        : Colors.black.withOpacity(0.08);
    final defaultText = isDark ? Colors.white70 : Colors.black54;
    final activeText = isDark ? Colors.white : Colors.black;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Day label
        Text(
          dayLabel,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? activeText : defaultText,
          ),
        ),
        const SizedBox(height: 6),
        // Date circle
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isSelected
                ? selectedBg
                : (isToday ? todayBg : Colors.transparent),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$date',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? selectedText : activeText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
