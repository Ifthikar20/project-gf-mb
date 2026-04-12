import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/presentation/widgets/mood_selector_widget.dart';
import '../bloc/journal_bloc.dart';
import '../bloc/journal_event.dart';
import '../bloc/journal_state.dart';
import '../widgets/journal_compose_sheet.dart';
import '../widgets/mood_calendar_heatmap.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/journal_entry_card.dart';

/// Main journal screen.
///
/// Layout:
/// - AppBar with streak counter
/// - Mood calendar heatmap (current month)
/// - Today's AI insight card (or prompt to check in)
/// - Past entries list
/// - FAB to compose new entry
class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  @override
  void initState() {
    super.initState();
    context.read<JournalBloc>().add(const JournalLoadRequested());
  }

  void _openComposeSheet({
    String? existingMood,
    int existingIntensity = 3,
    String existingReflection = '',
    bool isEditing = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => JournalComposeSheet(
        existingMood: existingMood,
        existingIntensity: existingIntensity,
        existingReflection: existingReflection,
        isEditing: isEditing,
        onSubmit: (data) {
          Navigator.pop(sheetContext);

          final bloc = context.read<JournalBloc>();
          final state = bloc.state;

          if (isEditing && state is JournalLoaded && state.todayEntry != null) {
            bloc.add(JournalEntryUpdated(
              entryId: state.todayEntry!.id,
              mood: data['mood'],
              moodIntensity: data['mood_intensity'],
              reflectionText: data['reflection_text'],
            ));
          } else {
            bloc.add(JournalEntrySubmitted(
              mood: data['mood'],
              moodIntensity: data['mood_intensity'],
              reflectionText: data['reflection_text'],
            ));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final bgColor = ThemeColors.background(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        final primaryColor = ThemeColors.primary(mode);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Wellness Journal',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: true,
            actions: [
              // Streak badge
              BlocBuilder<JournalBloc, JournalState>(
                builder: (context, state) {
                  final streak = state is JournalLoaded
                      ? (state.moodSummary?.streak.currentStreak ?? 0)
                      : 0;
                  if (streak == 0) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          '$streak',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          body: BlocBuilder<JournalBloc, JournalState>(
            builder: (context, state) {
              if (state is JournalLoading) {
                return Center(
                  child: CircularProgressIndicator(color: primaryColor),
                );
              }

              if (state is JournalError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: textSecondary, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load journal',
                        style: TextStyle(color: textSecondary, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () =>
                            context.read<JournalBloc>().add(const JournalLoadRequested()),
                        child: Text('Retry', style: TextStyle(color: primaryColor)),
                      ),
                    ],
                  ),
                );
              }

              if (state is JournalLoaded) {
                return _buildLoadedContent(state, mode, textColor, textSecondary, primaryColor);
              }

              return const SizedBox.shrink();
            },
          ),
          floatingActionButton: BlocBuilder<JournalBloc, JournalState>(
            builder: (context, state) {
              final hasToday = state is JournalLoaded && state.todayEntry != null;

              return FloatingActionButton.extended(
                onPressed: () {
                  if (hasToday) {
                    final entry = (state as JournalLoaded).todayEntry!;
                    _openComposeSheet(
                      existingMood: entry.mood,
                      existingIntensity: entry.moodIntensity,
                      existingReflection: entry.reflectionText,
                      isEditing: true,
                    );
                  } else {
                    _openComposeSheet();
                  }
                },
                backgroundColor: ThemeColors.primary(mode),
                icon: Icon(
                  hasToday ? Icons.edit_note : Icons.add_reaction_outlined,
                  color: Colors.white,
                ),
                label: Text(
                  hasToday ? 'Edit Today' : 'Check In',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadedContent(
    JournalLoaded state,
    ThemeMode mode,
    Color textColor,
    Color textSecondary,
    Color primaryColor,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<JournalBloc>().add(const JournalLoadRequested());
        // Wait for state change
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: primaryColor,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Mood Calendar Heatmap
          MoodCalendarHeatmap(
            calendarMonth: state.calendarMonth,
          ),
          const SizedBox(height: 16),

          // Submitting indicator
          if (state.isSubmitting)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Generating your AI insight...',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Today's AI Insight
          if (state.todayEntry != null && !state.isSubmitting) ...[
            AiInsightCard(
              entry: state.todayEntry!,
              onSuggestedActionTapped: () {
                final action = state.todayEntry!.suggestedAction;
                if (action.isNotEmpty) {
                  context.push(action);
                }
              },
            ),
            const SizedBox(height: 16),
          ],

          // Empty state — prompt to check in
          if (state.todayEntry == null && !state.isSubmitting) ...[
            _buildEmptyTodayCard(textColor, textSecondary, primaryColor),
            const SizedBox(height: 16),
          ],

          // Streak + Stats row
          if (state.moodSummary != null) ...[
            _buildStatsRow(state.moodSummary!, textColor, textSecondary),
            const SizedBox(height: 20),
          ],

          // Past Entries
          if (state.pastEntries.isNotEmpty) ...[
            Text(
              'Past Entries',
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            ...state.pastEntries.map((entry) => JournalEntryCard(entry: entry)),
          ],

          const SizedBox(height: 80), // FAB clearance
        ],
      ),
    );
  }

  Widget _buildEmptyTodayCard(Color textColor, Color textSecondary, Color primaryColor) {
    return GestureDetector(
      onTap: _openComposeSheet,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withOpacity(0.15),
              primaryColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.auto_awesome,
              color: primaryColor.withOpacity(0.7),
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              'How are you feeling today?',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Log your mood and get a personalized AI wellness insight',
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Start Check-In ✨',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(dynamic moodSummary, Color textColor, Color textSecondary) {
    final streak = moodSummary.streak;

    return Row(
      children: [
        _buildStatChip('🔥', '${streak.currentStreak}', 'Streak', Colors.orange),
        const SizedBox(width: 8),
        _buildStatChip('🏆', '${streak.longestStreak}', 'Best', Colors.amber),
        const SizedBox(width: 8),
        _buildStatChip('📝', '${streak.totalEntries}', 'Total', Colors.blue),
        const SizedBox(width: 8),
        if (moodSummary.dominantMood != null)
          Expanded(
            child: _buildDominantMoodChip(moodSummary.dominantMood!),
          ),
      ],
    );
  }

  Widget _buildStatChip(String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDominantMoodChip(String moodId) {
    final moodData = Moods.getById(moodId);
    final color = moodData?.color ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(moodData?.icon ?? Icons.mood, color: color, size: 18),
          const SizedBox(height: 2),
          Text(
            moodData?.label ?? moodId,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Top mood',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
