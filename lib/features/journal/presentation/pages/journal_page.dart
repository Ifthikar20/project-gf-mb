import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/journal_bloc.dart';
import '../bloc/journal_event.dart';
import '../bloc/journal_state.dart';
import '../widgets/mood_calendar_heatmap.dart';
import '../widgets/mood_trend_chart.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/gratitude_prompt_card.dart';
import '../widgets/journal_entry_card.dart';
import '../widgets/journal_compose_sheet.dart';

/// Main journal page — the primary screen for the AI Wellness Journal.
///
/// Layout:
/// - Mood calendar heatmap (current month)
/// - 7-day mood trend chart
/// - Today's AI insight card + gratitude prompt
/// - Past entries list (scrollable)
/// - FAB to compose a new entry
class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  @override
  void initState() {
    super.initState();
    // Load journal data on first mount
    final bloc = context.read<JournalBloc>();
    if (bloc.state is JournalInitial) {
      bloc.add(LoadJournal());
    }
  }

  void _openComposeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<JournalBloc>(),
        child: const JournalComposeSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final isLight = themeState.isLight;
        final bgColor = ThemeColors.background(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);

        return Scaffold(
          backgroundColor: bgColor,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openComposeSheet,
            backgroundColor:
                isLight ? const Color(0xFF1A1A1A) : Colors.white,
            foregroundColor:
                isLight ? Colors.white : const Color(0xFF1A1A1A),
            elevation: 4,
            icon: const Icon(Icons.edit_rounded, size: 20),
            label: Text(
              'How are you?',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: BlocBuilder<JournalBloc, JournalState>(
            builder: (context, state) {
              if (state is JournalLoading) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              if (state is JournalError) {
                return _buildErrorState(state.message, textColor, textSecondary);
              }

              if (state is JournalLoaded) {
                return _buildLoadedState(
                    state, isLight, textColor, textSecondary);
              }

              // Initial — trigger load
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadedState(
    JournalLoaded state,
    bool isLight,
    Color textColor,
    Color textSecondary,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<JournalBloc>().add(RefreshJournal());
        // Wait for refresh to complete
        await context.read<JournalBloc>().stream.firstWhere(
              (s) => s is JournalLoaded || s is JournalError,
            );
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // ── App Bar ──
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isLight
                              ? Colors.grey.shade100
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: textColor,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wellness Journal',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          if (state.summary.streak.currentStreak > 0)
                            Text(
                              '🔥 ${state.summary.streak.currentStreak} day streak',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFFFF8A65),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Total entries badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isLight
                            ? Colors.grey.shade100
                            : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${state.summary.streak.totalEntries} entries',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Mood Calendar Heatmap ──
          SliverToBoxAdapter(
            child: MoodCalendarHeatmap(calendarData: state.calendar),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── 7-Day Mood Trend Chart ──
          SliverToBoxAdapter(
            child: MoodTrendChart(weeklyMoods: state.summary.weeklyMoods),
          ),

          // ── Today's AI Insight ──
          if (state.todayEntry != null && state.todayEntry!.hasInsight) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: AiInsightCard(entry: state.todayEntry!),
            ),
          ],

          // ── Gratitude Prompt ──
          if (state.todayEntry != null &&
              state.todayEntry!.gratitudePrompt.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: GratitudePromptCard(
                  prompt: state.todayEntry!.gratitudePrompt),
            ),
          ],

          // ── Empty state (no entries yet) ──
          if (state.entries.isEmpty && state.todayEntry == null)
            SliverToBoxAdapter(
              child: _buildEmptyState(isLight, textColor, textSecondary),
            ),

          // ── Past Entries ──
          if (state.entries.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  'Recent Entries',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return JournalEntryCard(entry: state.entries[index]);
                  },
                  childCount: state.entries.length,
                ),
              ),
            ),
          ],

          // Bottom spacing for FAB
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      bool isLight, Color textColor, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 60, 40, 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF81C784).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: Color(0xFF81C784),
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your Journal Awaits',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start logging your mood to receive personalized AI insights and track your emotional wellness journey.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openComposeSheet,
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: Text(
              'Write First Entry',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isLight ? const Color(0xFF1A1A1A) : Colors.white,
              foregroundColor:
                  isLight ? Colors.white : const Color(0xFF1A1A1A),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
      String message, Color textColor, Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFE57373), size: 48),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () =>
                  context.read<JournalBloc>().add(RefreshJournal()),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
