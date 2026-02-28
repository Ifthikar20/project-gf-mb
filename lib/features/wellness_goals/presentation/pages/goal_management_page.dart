import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/fitness_profile_model.dart';
import '../../data/recovery_suggestions.dart';
import '../../../workouts/presentation/bloc/workout_bloc.dart';
import '../../../workouts/presentation/bloc/workout_event.dart';
import '../../../workouts/presentation/bloc/workout_state.dart';
import '../widgets/goals_section.dart';
import 'fitness_goal_setup_page.dart';

/// Goal Management page -- replaces WorkoutHubPage in Progress tab.
/// Shows setup onboarding on first load, then goal summary + management.
class GoalManagementPage extends StatefulWidget {
  const GoalManagementPage({super.key});

  @override
  State<GoalManagementPage> createState() => _GoalManagementPageState();
}

class _GoalManagementPageState extends State<GoalManagementPage> {
  FitnessProfileModel? _profile;
  bool _isLoading = true;
  bool _showSetup = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    context.read<WorkoutBloc>().add(const LoadWorkoutData());
  }

  Future<void> _loadProfile() async {
    final box = await Hive.openBox<FitnessProfileModel>('fitness_profile');
    final profile = box.get('profile');

    setState(() {
      _profile = profile;
      _isLoading = false;
      _showSetup = profile == null || !profile.isSetUp;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFBFBFB);

    if (_showSetup) {
      return Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: FitnessGoalSetupPage(
            onComplete: () {
              _loadProfile();
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: _buildGoalDashboard(isDark),
    );
  }

  Widget _buildGoalDashboard(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleColor = isDark ? Colors.white38 : Colors.black38;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final profile = _profile!;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Goals',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showSetup = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Edit',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: subtleColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Profile summary card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.04),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Profile',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _profileChip(
                        icon: Icons.accessibility_new_rounded,
                        label: profile.bodyTypeLabel,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 10),
                      _profileChip(
                        icon: Icons.flag_rounded,
                        label: profile.fitnessGoalLabel,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _profileChip(
                    icon: Icons.speed_rounded,
                    label: '${profile.intensityLabel} intensity',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Nutrition tip based on goal
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _buildNutritionTip(profile, isDark, textColor, subtleColor),
          ),
        ),

        // Existing goals section
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 8),
            child: GoalsSection(),
          ),
        ),

        // Bottom spacing
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _profileChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16,
              color: isDark ? Colors.white54 : Colors.black45),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionTip(
      FitnessProfileModel profile, bool isDark, Color textColor, Color subtleColor) {
    String tip;
    IconData icon;
    Color color;

    switch (profile.fitnessGoal) {
      case FitnessGoal.loseWeight:
        tip = 'Focus on a slight calorie deficit with high protein to preserve muscle while losing fat.';
        icon = Icons.trending_down_rounded;
        color = const Color(0xFFEF4444);
        break;
      case FitnessGoal.buildMuscle:
        tip = 'Aim for 1.6-2.2g protein per kg body weight. Eat in a slight calorie surplus.';
        icon = Icons.fitness_center_rounded;
        color = const Color(0xFF3B82F6);
        break;
      case FitnessGoal.stayActive:
        tip = 'Balanced nutrition with plenty of whole foods. Stay hydrated and eat regularly.';
        icon = Icons.restaurant_rounded;
        color = const Color(0xFF10B981);
        break;
      case FitnessGoal.improveFlexibility:
        tip = 'Anti-inflammatory foods help flexibility: berries, leafy greens, fatty fish, and nuts.';
        icon = Icons.eco_rounded;
        color = const Color(0xFF8B5CF6);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nutrition tip',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: textColor.withOpacity(0.75),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
