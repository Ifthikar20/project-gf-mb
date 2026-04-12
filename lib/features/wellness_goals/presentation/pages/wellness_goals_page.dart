import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../videos/presentation/bloc/videos_bloc.dart';
import '../../../videos/presentation/bloc/videos_event.dart';
import '../../../videos/presentation/bloc/videos_state.dart';
import '../../../meditation/presentation/bloc/meditation_bloc.dart';
import '../../../meditation/presentation/bloc/meditation_event.dart';
import '../../../meditation/presentation/bloc/meditation_state.dart';
import '../../../../core/services/healthkit_service.dart';
import '../../../workouts/presentation/bloc/workout_bloc.dart';
import '../../../workouts/presentation/bloc/workout_event.dart';
import '../../../workouts/presentation/bloc/workout_state.dart';
import '../../../diet/presentation/bloc/diet_bloc.dart';
import '../../../diet/presentation/bloc/diet_event.dart';
import '../../../diet/presentation/bloc/diet_state.dart';
import '../widgets/goals_section.dart';
import '../widgets/weekly_day_selector.dart';
import '../widgets/wellness_stats_card.dart';
import '../widgets/macro_tracking_cards.dart';
import '../widgets/recent_activity_section.dart';
import '../widgets/suggestions_feed.dart';
import '../../../advisor/presentation/bloc/advisor_bloc.dart';
import '../../../advisor/presentation/bloc/advisor_event.dart';
import '../../../advisor/presentation/bloc/advisor_state.dart';
import '../../../advisor/presentation/widgets/advisor_suggestion_section.dart';
import '../widgets/water_reminder_card.dart';
import '../widgets/suggestion_badge.dart';
import '../widgets/content_recommendations.dart';
// daily_activity_row removed — steps/calories now integrated into WellnessStatsCard

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    // Default to today's day-of-week index (Sunday = 0)
    _selectedDayIndex = DateTime.now().weekday % 7;

    // Load diet data so Home card shows eaten calories
    final dietState = context.read<DietBloc>().state;
    if (dietState is DietInitial) {
      context.read<DietBloc>().add(LoadTodayMeals());
    }

    // Load data if not already loaded
    final workoutState = context.read<WorkoutBloc>().state;
    if (workoutState is WorkoutInitial) {
      context.read<WorkoutBloc>().add(const LoadWorkoutData());
    }

    final videosState = context.read<VideosBloc>().state;
    if (videosState is VideosInitial) {
      context.read<VideosBloc>().add(const LoadVideos());
    }

    final meditationState = context.read<MeditationBloc>().state;
    if (meditationState is MeditationInitial) {
      context.read<MeditationBloc>().add(LoadMeditationAudios());
    }

    // Load AI suggestions
    final advisorState = context.read<AdvisorBloc>().state;
    if (advisorState is AdvisorInitial) {
      context.read<AdvisorBloc>().add(LoadSuggestions());
    }
  }



  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
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
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Header ──
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.spa_rounded,
                                  color: textColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Great Feel',
                                  style: isLight
                                      ? GoogleFonts.inter(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        )
                                      : GoogleFonts.inter(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Streak badge
                        _buildStreakBadge(),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Smart Suggestions ──
              const SliverToBoxAdapter(
                child: SuggestionBadge(),
              ),

              // ── Weekly Day Selector ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: WeeklyDaySelector(
                    selectedDayIndex: _selectedDayIndex,
                    onDaySelected: (index) {
                      setState(() => _selectedDayIndex = index);
                    },
                  ),
                ),
              ),

              // ── Water Reminder ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: WaterReminderCard(),
                ),
              ),

              // ── Primary Wellness Stats Card (includes calories + goals) ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: WellnessStatsCard(),
                ),
              ),

              // -- Content Recommendations (Videos & Audio) --
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: ContentRecommendations(),
                ),
              ),

              // -- Suggestions Feed (recovery/nutrition) --
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: SuggestionsFeed(),
                ),
              ),

              // -- Recent Activity --
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: RecentActivitySection(),
                ),
              ),

              // ── Wellness Goals (kept at bottom) ──
              const SliverToBoxAdapter(
                child: GoalsSection(),
              ),

              // Bottom spacing
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStreakBadge() {
    return BlocBuilder<WorkoutBloc, WorkoutState>(
      builder: (context, ws) {
        final totalBurned = ws is WorkoutLoaded ? (ws.stats?.thisWeekCalories ?? 0) : 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF97316)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/fire-logo-calories.png', width: 16, height: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text('$totalBurned', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              Text(' cal', style: GoogleFonts.inter(color: Colors.white70, fontSize: 10)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDot(bool active) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 8 : 6,
      height: active ? 8 : 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? (isDark ? Colors.white : Colors.black)
            : (isDark ? Colors.white24 : Colors.black12),
      ),
    );
  }
}
