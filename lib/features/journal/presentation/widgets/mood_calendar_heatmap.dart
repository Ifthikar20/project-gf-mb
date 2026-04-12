import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/presentation/widgets/mood_selector_widget.dart';
import '../../domain/entities/mood_summary.dart';

/// Calendar heatmap showing mood-colored dots for each day of the month.
///
/// Each day circle is colored based on the mood logged that day.
/// Empty days appear as muted gray circles.
class MoodCalendarHeatmap extends StatelessWidget {
  final CalendarMonth? calendarMonth;
  final ValueChanged<int>? onDayTapped;

  const MoodCalendarHeatmap({
    super.key,
    this.calendarMonth,
    this.onDayTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        final surfaceColor = ThemeColors.surface(mode);

        final now = DateTime.now();
        final year = calendarMonth != null
            ? int.tryParse(calendarMonth!.month.split('-')[0]) ?? now.year
            : now.year;
        final month = calendarMonth != null
            ? int.tryParse(calendarMonth!.month.split('-')[1]) ?? now.month
            : now.month;
        final daysInMonth = DateTime(year, month + 1, 0).day;
        final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon, 7=Sun

        final monthNames = [
          '', 'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December',
        ];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month header
              Row(
                children: [
                  Icon(Icons.calendar_today, color: textSecondary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${monthNames[month]} $year',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Day labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
                  return SizedBox(
                    width: 36,
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          color: textSecondary.withOpacity(0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              // Calendar grid
              _buildGrid(daysInMonth, firstWeekday, textSecondary, now, year, month),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrid(int daysInMonth, int firstWeekday, Color textSecondary, DateTime now, int year, int month) {
    final cells = <Widget>[];

    // Empty cells for days before the 1st
    for (int i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox(width: 36, height: 36));
    }

    // Day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final moodData = calendarMonth?.getMoodForDay(day);
      final isToday = day == now.day && month == now.month && year == now.year;
      final isFuture = DateTime(year, month, day).isAfter(now);

      Color circleColor;
      if (moodData != null) {
        final moodOption = Moods.getById(moodData.mood);
        circleColor = moodOption?.color ?? Colors.grey;
      } else if (isFuture) {
        circleColor = Colors.transparent;
      } else {
        circleColor = textSecondary.withOpacity(0.1);
      }

      cells.add(
        GestureDetector(
          onTap: moodData != null ? () => onDayTapped?.call(day) : null,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: moodData != null ? circleColor.withOpacity(0.8) : circleColor,
                  shape: BoxShape.circle,
                  border: isToday
                      ? Border.all(color: Colors.white.withOpacity(0.6), width: 2)
                      : null,
                  boxShadow: moodData != null
                      ? [
                          BoxShadow(
                            color: circleColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: moodData != null
                          ? Colors.white
                          : (isFuture
                              ? textSecondary.withOpacity(0.2)
                              : textSecondary.withOpacity(0.4)),
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 0,
      runSpacing: 4,
      children: cells,
    );
  }
}
