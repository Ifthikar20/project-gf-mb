import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/presentation/widgets/mood_selector_widget.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/mood_summary.dart';

/// Calendar heatmap showing mood-colored dots for each day of the month.
///
/// Each day that has a journal entry is colored by the mood's color.
/// Empty days are muted/grey. Tapping a day calls [onDayTapped].
class MoodCalendarHeatmap extends StatelessWidget {
  final CalendarData calendarData;
  final ValueChanged<String>? onDayTapped;

  const MoodCalendarHeatmap({
    super.key,
    required this.calendarData,
    this.onDayTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final isLight = themeState.isLight;
        final textColor = ThemeColors.textPrimary(themeState.mode);
        final textSecondary = ThemeColors.textSecondary(themeState.mode);

        // Parse month
        final now = DateTime.now();
        int year = now.year;
        int month = now.month;
        if (calendarData.month.isNotEmpty) {
          final parts = calendarData.month.split('-');
          if (parts.length == 2) {
            year = int.tryParse(parts[0]) ?? year;
            month = int.tryParse(parts[1]) ?? month;
          }
        }

        final firstDay = DateTime(year, month, 1);
        final daysInMonth =
            DateTime(year, month + 1, 0).day;
        final startWeekday = firstDay.weekday % 7; // Sunday = 0

        // Build mood lookup: date string → DailyMood
        final moodMap = <String, DailyMood>{};
        for (final day in calendarData.days) {
          moodMap[day.date] = day;
        }

        final weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isLight
                ? Colors.white
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLight
                  ? Colors.grey.shade200
                  : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month title
              Row(
                children: [
                  Icon(Icons.calendar_month_rounded,
                      color: textColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _monthName(month) + ' $year',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Weekday headers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: weekDays.map((d) {
                  return SizedBox(
                    width: 36,
                    child: Center(
                      child: Text(
                        d,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              // Calendar grid
              ..._buildWeeks(
                year, month, daysInMonth, startWeekday,
                moodMap, isLight, textColor, now,
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildWeeks(
    int year,
    int month,
    int daysInMonth,
    int startWeekday,
    Map<String, DailyMood> moodMap,
    bool isLight,
    Color textColor,
    DateTime now,
  ) {
    final weeks = <Widget>[];
    int day = 1;

    for (int week = 0; week < 6; week++) {
      if (day > daysInMonth) break;

      final cells = <Widget>[];
      for (int weekday = 0; weekday < 7; weekday++) {
        if ((week == 0 && weekday < startWeekday) || day > daysInMonth) {
          cells.add(const SizedBox(width: 36, height: 36));
        } else {
          final dateStr =
              '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
          final mood = moodMap[dateStr];
          final isToday =
              now.year == year && now.month == month && now.day == day;
          final dayNum = day;

          cells.add(_buildDayCell(
            dayNum, dateStr, mood, isToday, isLight, textColor,
          ));
          day++;
        }
      }

      weeks.add(Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: cells,
        ),
      ));
    }

    return weeks;
  }

  Widget _buildDayCell(
    int day,
    String dateStr,
    DailyMood? mood,
    bool isToday,
    bool isLight,
    Color textColor,
  ) {
    final moodColor = mood != null
        ? Moods.getById(mood.mood)?.color ?? Colors.grey
        : null;

    return GestureDetector(
      onTap: mood != null ? () => onDayTapped?.call(dateStr) : null,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: moodColor?.withOpacity(0.2),
              shape: BoxShape.circle,
              border: isToday
                  ? Border.all(
                      color: moodColor ?? textColor.withOpacity(0.4),
                      width: 2,
                    )
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (moodColor != null)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: moodColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    '$day',
                    style: GoogleFonts.inter(
                      fontSize: moodColor != null ? 9 : 11,
                      fontWeight:
                          isToday ? FontWeight.w700 : FontWeight.w400,
                      color: moodColor ?? textColor.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month];
  }
}
