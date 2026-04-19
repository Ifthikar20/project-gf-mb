import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';
import '../bloc/coach_chat_bloc.dart';
import '../../data/models/coach_chat_models.dart';

class MyCoachPage extends StatefulWidget {
  const MyCoachPage({super.key});

  @override
  State<MyCoachPage> createState() => _MyCoachPageState();
}

class _MyCoachPageState extends State<MyCoachPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<CoachChatBloc>().add(const LoadMyCoachChat());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
        final surfaceColor = ThemeColors.surface(mode);
        final borderColor = ThemeColors.border(mode);
        final primaryColor = ThemeColors.primary(mode);

        return Scaffold(
          backgroundColor: bgColor,
          body: BlocBuilder<CoachChatBloc, CoachChatState>(
            builder: (context, state) {
              if (state is CoachChatLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    color: primaryColor,
                    strokeWidth: 2,
                  ),
                );
              }

              if (state is CoachChatEmpty) {
                return _buildEmptyState(
                  textColor: textColor,
                  textSecondary: textSecondary,
                  primaryColor: primaryColor,
                  isLight: isLight,
                );
              }

              if (state is CoachChatError) {
                return _buildErrorState(
                  state.message,
                  textColor: textColor,
                  textSecondary: textSecondary,
                  primaryColor: primaryColor,
                );
              }

              if (state is CoachChatLoaded) {
                return _buildCoachView(
                  state: state,
                  isLight: isLight,
                  bgColor: bgColor,
                  surfaceColor: surfaceColor,
                  textColor: textColor,
                  textSecondary: textSecondary,
                  borderColor: borderColor,
                  primaryColor: primaryColor,
                );
              }

              // Adding coach — show loading
              if (state is AddingCoach || state is CoachAdded) {
                return Center(
                  child: CircularProgressIndicator(
                    color: primaryColor,
                    strokeWidth: 2,
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // Empty state — coach discovery & setup
  // ─────────────────────────────────────────
  Widget _buildEmptyState({
    required Color textColor,
    required Color textSecondary,
    required Color primaryColor,
    required bool isLight,
  }) {
    final surfaceColor = isLight ? Colors.white : const Color(0xFF1A1A1A);
    final borderColor = isLight
        ? Colors.black.withOpacity(0.06)
        : Colors.white.withOpacity(0.08);

    final journeyCategories = [
      _JourneyCategory('💪', 'Strength', 'Build muscle & power'),
      _JourneyCategory('🏃', 'Cardio', 'Endurance & stamina'),
      _JourneyCategory('🧘', 'Yoga', 'Flexibility & mindfulness'),
      _JourneyCategory('🔥', 'HIIT', 'High intensity intervals'),
      _JourneyCategory('🏋️', 'CrossFit', 'Functional fitness'),
      _JourneyCategory('🥗', 'Nutrition', 'Meal plans & diet'),
      _JourneyCategory('⚖️', 'Weight Loss', 'Fat loss programs'),
      _JourneyCategory('🧠', 'Wellness', 'Holistic health'),
    ];

    final steps = [
      _SetupStep(1, 'Browse Coaches', 'See who\'s available and what they offer', Icons.search_rounded),
      _SetupStep(2, 'Pick Your Focus', 'Strength, cardio, yoga — whatever fits you', Icons.route_rounded),
      _SetupStep(3, 'Start Training', 'Get workouts, track progress, and chat directly', Icons.trending_up_rounded),
    ];

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Coach',
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You don\'t have a coach yet',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Hero Card ──
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLight
                      ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                      : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.sports_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Find a Coach',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Personal training, your way',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => context.push(AppRouter.coaches),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Browse Coaches',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── How It Works ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
              child: Text(
                'How It Works',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: steps.map((step) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '${step.number}',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.title,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                step.subtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(step.icon, color: textSecondary, size: 20),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Fitness Journeys ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
              child: Text(
                'Explore Fitness Journeys',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: journeyCategories.map((cat) {
                  return GestureDetector(
                    onTap: () => context.push(AppRouter.coaches),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                cat.title,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                cat.subtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── What You Get ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
              child: Text(
                'What You Get',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildFeatureRow(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Direct Messaging',
                    subtitle: 'Chat with your coach anytime',
                    textColor: textColor,
                    textSecondary: textSecondary,
                    primaryColor: primaryColor,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                  ),
                  _buildFeatureRow(
                    icon: Icons.fitness_center_rounded,
                    title: 'Custom Workouts',
                    subtitle: 'Personalized workout plans pushed to you',
                    textColor: textColor,
                    textSecondary: textSecondary,
                    primaryColor: primaryColor,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                  ),
                  _buildFeatureRow(
                    icon: Icons.bar_chart_rounded,
                    title: 'Progress Tracking',
                    subtitle: 'Complete workouts, track calories & streaks',
                    textColor: textColor,
                    textSecondary: textSecondary,
                    primaryColor: primaryColor,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                  ),
                  _buildFeatureRow(
                    icon: Icons.lightbulb_outline_rounded,
                    title: 'Smart Suggestions',
                    subtitle: 'Your coach suggests your next best workout',
                    textColor: textColor,
                    textSecondary: textSecondary,
                    primaryColor: primaryColor,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom CTA ──
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: GestureDetector(
                onTap: () => context.push(AppRouter.coaches),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isLight ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Get Started',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isLight ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom safe area
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color textSecondary,
    required Color primaryColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: textSecondary, size: 20),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Error state
  // ─────────────────────────────────────────
  Widget _buildErrorState(
    String message, {
    required Color textColor,
    required Color textSecondary,
    required Color primaryColor,
  }) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: textSecondary, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.inter(color: textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => context.read<CoachChatBloc>().add(const LoadMyCoachChat()),
              child: Text(
                'Retry',
                style: GoogleFonts.inter(
                  color: primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Main coach view — Airbnb-style messaging
  // ─────────────────────────────────────────
  int _selectedTab = 0; // 0 = Messages, 1 = Workouts

  Widget _buildCoachView({
    required CoachChatLoaded state,
    required bool isLight,
    required Color bgColor,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    final coach = state.chat.coach;

    return Column(
      children: [
        // ── Top bar: coach info ──
        SafeArea(
          bottom: false,
          child: GestureDetector(
            onTap: () => context.push(
              '${AppRouter.coachDetail}?id=${coach.id}',
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  bottom: BorderSide(
                    color: borderColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Coach avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.12),
                    ),
                    child: coach.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              coach.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  coach.name.isNotEmpty ? coach.name[0] : 'C',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              coach.name.isNotEmpty ? coach.name[0] : 'C',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Name + status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coach.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        if (coach.title != null)
                          Text(
                            coach.title!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Chevron to profile
                  Icon(
                    Icons.chevron_right_rounded,
                    color: textSecondary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Tab bar: Messages | Workouts | Progress | Settings ──
        Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          color: bgColor,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTab(
                  label: 'Messages',
                  isSelected: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                  textColor: textColor,
                  textSecondary: textSecondary,
                  primaryColor: primaryColor,
                  isLight: isLight,
                  badge: state.chat.unreadCount,
                ),
                const SizedBox(width: 24),
                _buildTab(
                  label: 'Workouts',
                  isSelected: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                  textColor: textColor,
                  textSecondary: textSecondary,
                  primaryColor: primaryColor,
                  isLight: isLight,
                  badge: state.activeWorkouts.length,
                ),
                const SizedBox(width: 24),
                _buildTab(
                  label: 'Progress',
                  isSelected: _selectedTab == 2,
                  onTap: () => setState(() => _selectedTab = 2),
                  textColor: textColor,
                  textSecondary: textSecondary,
                  primaryColor: primaryColor,
                  isLight: isLight,
                  badge: state.completedWorkouts.length,
                ),
                const SizedBox(width: 24),
                _buildTab(
                  label: 'Settings',
                  isSelected: _selectedTab == 3,
                  onTap: () => setState(() => _selectedTab = 3),
                  textColor: textColor,
                  textSecondary: textSecondary,
                  primaryColor: primaryColor,
                  isLight: isLight,
                ),
              ],
            ),
          ),
        ),

        // ── Content ──
        Expanded(
          child: _selectedTab == 0
              ? _buildMessagesTab(
                  state: state,
                  coach: coach,
                  isLight: isLight,
                  bgColor: bgColor,
                  surfaceColor: surfaceColor,
                  textColor: textColor,
                  textSecondary: textSecondary,
                  borderColor: borderColor,
                  primaryColor: primaryColor,
                )
              : _selectedTab == 1
                  ? _buildWorkoutsTab(
                      state: state,
                      isLight: isLight,
                      surfaceColor: surfaceColor,
                      textColor: textColor,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                      primaryColor: primaryColor,
                    )
                  : _selectedTab == 2
                      ? _buildProgressTab(
                          state: state,
                          isLight: isLight,
                          surfaceColor: surfaceColor,
                          textColor: textColor,
                          textSecondary: textSecondary,
                          borderColor: borderColor,
                          primaryColor: primaryColor,
                        )
                      : _buildSettingsTab(
                          isLight: isLight,
                          surfaceColor: surfaceColor,
                          textColor: textColor,
                          textSecondary: textSecondary,
                          borderColor: borderColor,
                          primaryColor: primaryColor,
                        ),
        ),

        // ── Message Input (only on Messages tab) ──
        if (_selectedTab == 0)
          _buildMessageInput(
            chatId: state.chat.id,
            isSending: state.isSendingMessage,
            isLight: isLight,
            surfaceColor: surfaceColor,
            textColor: textColor,
            textSecondary: textSecondary,
            borderColor: borderColor,
            primaryColor: primaryColor,
          ),
      ],
    );
  }

  // ── Tab widget ──
  Widget _buildTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color textColor,
    required Color textSecondary,
    required Color primaryColor,
    required bool isLight,
    int badge = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? (isLight ? Colors.black : Colors.white)
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? textColor : textSecondary,
              ),
            ),
            if (badge > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isLight ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$badge',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isLight ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Messages Tab ──
  Widget _buildMessagesTab({
    required CoachChatLoaded state,
    required ChatCoachInfo coach,
    required bool isLight,
    required Color bgColor,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    if (state.messages.isEmpty) {
      // Welcome message
      return ListView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Date divider
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Today',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: textSecondary.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // Coach welcome bubble
          Padding(
            padding: const EdgeInsets.only(right: 60, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Small avatar
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8, bottom: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.12),
                  ),
                  child: Center(
                    child: Text(
                      coach.name.isNotEmpty ? coach.name[0] : 'C',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(18),
                      ),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      'Hey! Welcome aboard 👋\nI\'m ${coach.name}, and I\'ll be your coach. Tell me about your goals and I\'ll put together a plan for you.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: textColor,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              'Just now',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: textSecondary.withOpacity(0.4),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final msg = state.messages[index];
        final isMe = msg.sender.id == state.chat.user.id;
        return _buildChatBubble(
          message: msg,
          isMe: isMe,
          coach: coach,
          isLight: isLight,
          surfaceColor: surfaceColor,
          textColor: textColor,
          textSecondary: textSecondary,
          borderColor: borderColor,
          primaryColor: primaryColor,
        );
      },
    );
  }

  // ── Clean chat bubble (Airbnb style) ──
  Widget _buildChatBubble({
    required ChatMessageModel message,
    required bool isMe,
    required ChatCoachInfo coach,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 60 : 0,
        right: isMe ? 0 : 60,
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.12),
              ),
              child: Center(
                child: Text(
                  coach.name.isNotEmpty ? coach.name[0] : 'C',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? (isLight ? Colors.black : Colors.white)
                    : surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                border: isMe ? null : Border.all(color: borderColor),
              ),
              child: Text(
                message.text,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: isMe
                      ? (isLight ? Colors.white : Colors.black)
                      : textColor,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Workouts Tab ──
  // Track which week we're viewing and which day is selected
  DateTime _calendarWeekStart = _getWeekStart(DateTime.now());
  DateTime? _selectedDay;

  static DateTime _getWeekStart(DateTime d) {
    final diff = d.weekday - DateTime.monday;
    return DateTime(d.year, d.month, d.day - diff);
  }

  Widget _buildWorkoutsTab({
    required CoachChatLoaded state,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    final all = [...state.activeWorkouts, ...state.completedWorkouts];
    final today = DateTime.now();
    final days = List.generate(
        7, (i) => _calendarWeekStart.add(Duration(days: i)));

    // Map workouts to days (using assignedAt date)
    Map<int, List<AssignedWorkoutModel>> byDay = {};
    for (final w in all) {
      try {
        final d = DateTime.parse(w.assignedAt);
        final key = d.year * 10000 + d.month * 100 + d.day;
        byDay.putIfAbsent(key, () => []).add(w);
      } catch (_) {}
    }

    // Also assign active workouts to today if no date
    for (final w in state.activeWorkouts) {
      final key = today.year * 10000 + today.month * 100 + today.day;
      if (!byDay.values.any((list) => list.contains(w))) {
        byDay.putIfAbsent(key, () => []).add(w);
      }
    }

    return Column(
      children: [
        // ── Week header with navigation ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _calendarWeekStart = _calendarWeekStart
                      .subtract(const Duration(days: 7));
                  _selectedDay = null;
                }),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Icon(Icons.chevron_left_rounded,
                      color: textSecondary, size: 20),
                ),
              ),
              Text(
                _formatWeekRange(days.first, days.last),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _calendarWeekStart =
                      _calendarWeekStart.add(const Duration(days: 7));
                  _selectedDay = null;
                }),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Icon(Icons.chevron_right_rounded,
                      color: textSecondary, size: 20),
                ),
              ),
            ],
          ),
        ),

        // ── Calendar day grid ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: days.map((day) {
              final key = day.year * 10000 + day.month * 100 + day.day;
              final todayKey =
                  today.year * 10000 + today.month * 100 + today.day;
              final isToday = key == todayKey;
              final isSelected = _selectedDay != null &&
                  _selectedDay!.year == day.year &&
                  _selectedDay!.month == day.month &&
                  _selectedDay!.day == day.day;
              final hasWorkout = byDay.containsKey(key);
              final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedDay = isSelected ? null : day;
                  }),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isLight ? Colors.black : Colors.white)
                          : isToday
                              ? primaryColor.withOpacity(0.1)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday && !isSelected
                          ? Border.all(
                              color: primaryColor.withOpacity(0.3))
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          dayNames[day.weekday - 1],
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? (isLight
                                    ? Colors.white60
                                    : Colors.black54)
                                : textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight:
                                isToday ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? (isLight ? Colors.white : Colors.black)
                                : isToday
                                    ? primaryColor
                                    : textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Dot indicator
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasWorkout
                                ? (isSelected
                                    ? (isLight
                                        ? Colors.white
                                        : Colors.black)
                                    : primaryColor)
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 8),
        Divider(color: borderColor, height: 1),

        // ── Selected day workouts or default view ──
        Expanded(
          child: _buildDayContent(
            day: _selectedDay ?? today,
            byDay: byDay,
            chatId: state.chat.id,
            isLight: isLight,
            surfaceColor: surfaceColor,
            textColor: textColor,
            textSecondary: textSecondary,
            borderColor: borderColor,
            primaryColor: primaryColor,
          ),
        ),
      ],
    );
  }

  String _formatWeekRange(DateTime start, DateTime end) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (start.month == end.month) {
      return '${months[start.month]} ${start.day}–${end.day}';
    }
    return '${months[start.month]} ${start.day} – ${months[end.month]} ${end.day}';
  }

  Widget _buildDayContent({
    required DateTime day,
    required Map<int, List<AssignedWorkoutModel>> byDay,
    required String chatId,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    final key = day.year * 10000 + day.month * 100 + day.day;
    final workouts = byDay[key] ?? [];
    final dayNames = [
      '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];

    if (workouts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wb_sunny_rounded,
                  color: textSecondary.withOpacity(0.3), size: 40),
              const SizedBox(height: 12),
              Text(
                'Rest Day',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'No workouts scheduled for ${dayNames[day.weekday]}.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            dayNames[day.weekday],
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
        ...workouts.map((w) => _buildWorkoutCard(
              workout: w,
              chatId: chatId,
              isLight: isLight,
              surfaceColor: surfaceColor,
              textColor: textColor,
              textSecondary: textSecondary,
              borderColor: borderColor,
              primaryColor: primaryColor,
            )),
      ],
    );
  }

  // ─────────────────────────────────────────
  // Progress Tab — completed workout history
  // ─────────────────────────────────────────
  Widget _buildProgressTab({
    required CoachChatLoaded state,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    final completed = state.completedWorkouts;

    if (completed.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFF22C55E),
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No progress yet',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Complete your first workout to start\ntracking your progress.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final totalMinutes = completed.fold<int>(
        0, (sum, w) => sum + w.durationMinutes);
    final totalCalories = completed.fold<int>(
        0, (sum, w) => sum + (w.caloriesBurned ?? 0));

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.fitness_center_rounded,
                value: '${completed.length}',
                label: 'Workouts',
                color: primaryColor,
                surfaceColor: surfaceColor,
                textColor: textColor,
                textSecondary: textSecondary,
                borderColor: borderColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.timer_rounded,
                value: '${totalMinutes}m',
                label: 'Total Time',
                color: const Color(0xFF3B82F6),
                surfaceColor: surfaceColor,
                textColor: textColor,
                textSecondary: textSecondary,
                borderColor: borderColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_fire_department_rounded,
                value: '$totalCalories',
                label: 'Calories',
                color: const Color(0xFFEF4444),
                surfaceColor: surfaceColor,
                textColor: textColor,
                textSecondary: textSecondary,
                borderColor: borderColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Completed Workouts',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
        ...completed.map((w) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF22C55E),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w.workoutName,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${w.durationMinutes} min  •  ${w.intensityEmoji} ${w.intensity}  •  ${w.caloriesBurned ?? 0} cal',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Settings Tab — coach visibility controls
  // ─────────────────────────────────────────
  bool _shareFood = true;
  bool _shareExercise = true;
  bool _shareReps = true;
  bool _shareRecommendations = false;
  bool _shareGoals = true;

  Widget _buildSettingsTab({
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            'Coach Visibility',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Choose what your coach can see about your activity.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: textSecondary,
              height: 1.4,
            ),
          ),
        ),
        _buildVisibilityToggle(
          icon: Icons.restaurant_rounded,
          title: 'Food Scans & Nutrition',
          subtitle: 'Meal photos, calorie counts, macro breakdown',
          value: _shareFood,
          onChanged: (v) => setState(() => _shareFood = v),
          surfaceColor: surfaceColor,
          textColor: textColor,
          textSecondary: textSecondary,
          borderColor: borderColor,
          primaryColor: primaryColor,
        ),
        _buildVisibilityToggle(
          icon: Icons.fitness_center_rounded,
          title: 'Exercise Completions',
          subtitle: 'Which workouts you finished and when',
          value: _shareExercise,
          onChanged: (v) => setState(() => _shareExercise = v),
          surfaceColor: surfaceColor,
          textColor: textColor,
          textSecondary: textSecondary,
          borderColor: borderColor,
          primaryColor: primaryColor,
        ),
        _buildVisibilityToggle(
          icon: Icons.repeat_rounded,
          title: 'Rep Counts & Sets',
          subtitle: 'Detailed sets, reps, and weights used',
          value: _shareReps,
          onChanged: (v) => setState(() => _shareReps = v),
          surfaceColor: surfaceColor,
          textColor: textColor,
          textSecondary: textSecondary,
          borderColor: borderColor,
          primaryColor: primaryColor,
        ),
        _buildVisibilityToggle(
          icon: Icons.lightbulb_outline_rounded,
          title: 'AI Recommendations',
          subtitle: 'Suggestions from the wellness advisor',
          value: _shareRecommendations,
          onChanged: (v) => setState(() => _shareRecommendations = v),
          surfaceColor: surfaceColor,
          textColor: textColor,
          textSecondary: textSecondary,
          borderColor: borderColor,
          primaryColor: primaryColor,
        ),
        _buildVisibilityToggle(
          icon: Icons.flag_rounded,
          title: 'Goals & Targets',
          subtitle: 'Your wellness goals and weekly targets',
          value: _shareGoals,
          onChanged: (v) => setState(() => _shareGoals = v),
          surfaceColor: surfaceColor,
          textColor: textColor,
          textSecondary: textSecondary,
          borderColor: borderColor,
          primaryColor: primaryColor,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  color: primaryColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your coach can only see data you choose to share. You can change these settings anytime.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: textColor.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilityToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Coach Info Card
  // ─────────────────────────────────────────
  Widget _buildCoachInfoCard({
    required ChatCoachInfo coach,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLight
              ? [
                  const Color(0xFFF8F9FF),
                  const Color(0xFFF0F3FF),
                ]
              : [
                  const Color(0xFF1A1D2E),
                  const Color(0xFF161929),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.2),
                  primaryColor.withOpacity(0.1),
                ],
              ),
            ),
            child: coach.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      coach.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          coach.name.isNotEmpty ? coach.name[0] : 'C',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      coach.name.isNotEmpty ? coach.name[0] : 'C',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coach.name,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                if (coach.title != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    coach.title!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
                if (coach.specialties.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: coach.specialties.take(3).map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          // Status dot
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Active Workout Card
  // ─────────────────────────────────────────
  Widget _buildWorkoutCard({
    required AssignedWorkoutModel workout,
    required String chatId,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: workout.isInProgress
              ? primaryColor.withOpacity(0.4)
              : borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isLight ? 0.03 : 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                workout.intensityEmoji,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.workoutName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '${workout.durationMinutes} min  •  ${workout.intensity}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: workout.isInProgress
                      ? primaryColor.withOpacity(0.12)
                      : (isLight
                          ? Colors.black.withOpacity(0.05)
                          : Colors.white.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  workout.statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: workout.isInProgress
                        ? primaryColor
                        : textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (workout.coachNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '📝 ${workout.coachNotes}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: textSecondary,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          // Action buttons
          Row(
            children: [
              if (workout.canStart)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.read<CoachChatBloc>().add(
                            StartWorkoutEvent(chatId, workout.id),
                          );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isLight ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '▶  Start Workout',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isLight ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (workout.canComplete)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      context.read<CoachChatBloc>().add(
                            ConfirmWorkoutEvent(
                              chatId,
                              workout.id,
                              mood: 'good',
                            ),
                          );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '✓  Complete',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (!workout.isCompleted && !workout.isSkipped) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.read<CoachChatBloc>().add(
                          SkipWorkoutEvent(chatId, workout.id),
                        );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isLight
                          ? Colors.black.withOpacity(0.05)
                          : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Completed Workout Card (compact)
  // ─────────────────────────────────────────
  Widget _buildCompletedWorkoutCard({
    required AssignedWorkoutModel workout,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              workout.workoutName,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          Text(
            '${workout.durationMinutes}m',
            style: GoogleFonts.inter(fontSize: 12, color: textSecondary),
          ),
          if (workout.caloriesBurned != null) ...[
            const SizedBox(width: 8),
            Text(
              '🔥 ${workout.caloriesBurned}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF97316),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Message Bubble
  // ─────────────────────────────────────────
  Widget _buildMessageBubble({
    required ChatMessageModel message,
    required bool isMe,
    required String coachName,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    // Special card for workout assignments
    if (message.isWorkoutAssignment) {
      return _buildWorkoutAssignmentBubble(
        message: message,
        isLight: isLight,
        textColor: textColor,
        textSecondary: textSecondary,
        borderColor: borderColor,
        primaryColor: primaryColor,
      );
    }

    // Special card for workout completions
    if (message.isWorkoutCompletion) {
      return _buildWorkoutCompletionBubble(
        message: message,
        isLight: isLight,
        textColor: textColor,
        textSecondary: textSecondary,
      );
    }

    // Special card for coach suggestions
    if (message.isCoachSuggestion) {
      return _buildSuggestionBubble(
        message: message,
        isLight: isLight,
        textColor: textColor,
        textSecondary: textSecondary,
        primaryColor: primaryColor,
      );
    }

    // Regular text message
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMe ? 60 : 20,
        4,
        isMe ? 20 : 60,
        4,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 3),
                child: Text(
                  coachName,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? (isLight ? Colors.black : Colors.white)
                    : surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe
                    ? null
                    : Border.all(color: borderColor),
              ),
              child: Text(
                message.text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isMe
                      ? (isLight ? Colors.white : Colors.black)
                      : textColor,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutAssignmentBubble({
    required ChatMessageModel message,
    required bool isLight,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    final meta = message.metadata;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withOpacity(0.08),
              primaryColor.withOpacity(0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🏋️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  'Workout Assigned',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              meta['workout_name'] ?? 'Workout',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${meta['duration_minutes'] ?? 0} min  •  ${meta['intensity'] ?? 'moderate'}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: textSecondary,
              ),
            ),
            if ((meta['coach_notes'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '📝 ${meta['coach_notes']}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCompletionBubble({
    required ChatMessageModel message,
    required bool isLight,
    required Color textColor,
    required Color textSecondary,
  }) {
    final meta = message.metadata;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF22C55E).withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${meta['workout_name'] ?? 'Workout'} Completed',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    '⏱ ${meta['duration_minutes'] ?? 0}m  •  🔥 ${meta['calories_burned'] ?? 0} cal',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionBubble({
    required ChatMessageModel message,
    required bool isLight,
    required Color textColor,
    required Color textSecondary,
    required Color primaryColor,
  }) {
    final meta = message.metadata;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF97316).withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  'Coach Suggestion',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF97316),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Next: ${meta['next_workout'] ?? 'Workout'}',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            Text(
              '⏱ ${meta['suggested_duration'] ?? 0}m  •  ⚡ ${meta['suggested_intensity'] ?? 'moderate'}',
              style: GoogleFonts.inter(fontSize: 12, color: textSecondary),
            ),
            if ((meta['reason'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                meta['reason'],
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Message Input Bar
  // ─────────────────────────────────────────
  Widget _buildMessageInput({
    required String chatId,
    required bool isSending,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        12,
        MediaQuery.of(context).padding.bottom + 80,
      ),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF111111),
        border: Border(
          top: BorderSide(color: borderColor, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isLight
                    ? const Color(0xFFF7F7F7)
                    : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isLight
                      ? const Color(0xFFE0E0E0)
                      : const Color(0xFF2A2A2A),
                ),
              ),
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: textColor,
                  height: 1.35,
                ),
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 16,
                    color: textSecondary.withOpacity(0.5),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(chatId),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: GestureDetector(
              onTap: isSending ? null : () => _sendMessage(chatId),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isLight ? Colors.black : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: isSending
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          color: isLight ? Colors.white : Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        Icons.arrow_upward_rounded,
                        color: isLight ? Colors.white : Colors.black,
                        size: 22,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String chatId) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    HapticFeedback.lightImpact();
    context.read<CoachChatBloc>().add(SendMessage(chatId, text));
  }
}

// ─────────────────────────────────────────
// Helper data classes for empty state
// ─────────────────────────────────────────

class _SetupStep {
  final int number;
  final String title;
  final String subtitle;
  final IconData icon;
  const _SetupStep(this.number, this.title, this.subtitle, this.icon);
}

class _JourneyCategory {
  final String emoji;
  final String title;
  final String subtitle;
  const _JourneyCategory(this.emoji, this.title, this.subtitle);
}
