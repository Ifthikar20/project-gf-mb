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
import '../../../workouts/presentation/bloc/workout_bloc.dart';
import '../../../workouts/presentation/bloc/workout_event.dart';
import '../../../workouts/presentation/bloc/workout_state.dart';
import '../widgets/goals_section.dart';
import '../widgets/weekly_day_selector.dart';
import '../widgets/wellness_stats_card.dart';
import '../widgets/macro_tracking_cards.dart';
import '../widgets/recent_activity_section.dart';
import '../widgets/suggestions_feed.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/wellness_checkin_model.dart';
import 'wellness_checkin_page.dart';
import '../../../advisor/presentation/bloc/advisor_bloc.dart';
import '../../../advisor/presentation/bloc/advisor_event.dart';
import '../../../advisor/presentation/bloc/advisor_state.dart';
import '../../../advisor/presentation/widgets/advisor_suggestion_section.dart';
import '../widgets/water_reminder_card.dart';
import '../widgets/quick_access_bar.dart';
import '../widgets/content_recommendations.dart';

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

    // Auto-trigger wellness check-in if not done today
    _checkDailyCheckIn();

    // Load AI suggestions
    final advisorState = context.read<AdvisorBloc>().state;
    if (advisorState is AdvisorInitial) {
      context.read<AdvisorBloc>().add(LoadSuggestions());
    }
  }

  Future<void> _checkDailyCheckIn() async {
    try {
      final box = await Hive.openBox<WellnessCheckInModel>('wellness_checkins');
      final today = DateTime.now();
      final key = '${today.year}-${today.month}-${today.day}';
      final existing = box.get(key);

      if (existing == null && mounted) {
        // Delay slightly so the home page renders first
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const WellnessCheckInPage(),
              fullscreenDialog: true,
            ),
          );
        }
      }
    } catch (_) {
      // Silent fail
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

              // ── Quick Access Shortcuts ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: QuickAccessBar(),
                ),
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

              // ── Primary Wellness Stats Card ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: WellnessStatsCard(),
                ),
              ),

              // ── Macro Tracking Cards ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: MacroTrackingCards(),
                ),
              ),

              // ── Dot indicator (visual)  ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDot(true),
                      const SizedBox(width: 6),
                      _buildDot(false),
                    ],
                  ),
                ),
              ),

              // -- AI Suggestions ("For You") --
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: AdvisorSuggestionSection(tabFilter: 'home'),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFF97316)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '15',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
