import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/presentation/widgets/mood_selector_widget.dart';
import '../../domain/entities/journal_entry.dart';

/// A card displaying a past journal entry in the entry list.
///
/// Shows mood icon + label, date, reflection preview, and tags.
class JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback? onTap;

  const JournalEntryCard({
    super.key,
    required this.entry,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final moodData = Moods.getById(entry.mood);
    final moodColor = moodData?.color ?? Colors.grey;

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final surfaceColor = ThemeColors.surface(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mood circle
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: moodColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      moodData?.icon ?? Icons.sentiment_neutral,
                      color: moodColor,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mood label + date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.moodLabel,
                            style: TextStyle(
                              color: moodColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatDate(entry.entryDate),
                            style: TextStyle(
                              color: textSecondary.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      // Intensity dots
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (i) {
                          return Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 3),
                            decoration: BoxDecoration(
                              color: i < entry.moodIntensity
                                  ? moodColor
                                  : moodColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),

                      // Reflection preview
                      if (entry.hasReflection) ...[
                        const SizedBox(height: 8),
                        Text(
                          entry.reflectionText.length > 100
                              ? '${entry.reflectionText.substring(0, 100)}...'
                              : entry.reflectionText,
                          style: TextStyle(
                            color: textColor.withOpacity(0.7),
                            fontSize: 13,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Tags
                      if (entry.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: entry.tags.take(3).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: moodColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: moodColor.withOpacity(0.8),
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      return '${months[month]} $day';
    } catch (_) {
      return dateStr;
    }
  }
}
