import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/fitness_profile_model.dart';
import '../../../workouts/presentation/bloc/workout_bloc.dart';

import '../../../workouts/presentation/bloc/workout_state.dart';
import '../../../workouts/data/models/workout_models.dart';

/// Multi-step fitness goal setup (shown on first load of Progress tab).
/// Step 1: Body type  |  Step 2: Goal  |  Step 3: Intensity  |  Step 4: Preferred workouts
class FitnessGoalSetupPage extends StatefulWidget {
  final VoidCallback? onComplete;

  const FitnessGoalSetupPage({super.key, this.onComplete});

  @override
  State<FitnessGoalSetupPage> createState() => _FitnessGoalSetupPageState();
}

class _FitnessGoalSetupPageState extends State<FitnessGoalSetupPage> {
  int _step = 0;
  int _bodyType = -1;
  int _fitnessGoal = -1;
  int _intensity = -1;
  final Set<String> _selectedWorkouts = {};

  final _bodyTypes = [
    _SetupOption(
      index: 0,
      label: 'Lean',
      subtitle: 'Naturally thin, fast metabolism',
      icon: Icons.accessibility_new_rounded,
    ),
    _SetupOption(
      index: 1,
      label: 'Athletic',
      subtitle: 'Muscular build, gains easily',
      icon: Icons.fitness_center_rounded,
    ),
    _SetupOption(
      index: 2,
      label: 'Stocky',
      subtitle: 'Wider build, strong frame',
      icon: Icons.shield_rounded,
    ),
  ];

  final _goals = [
    _SetupOption(
      index: 0,
      label: 'Lose Weight',
      subtitle: 'Burn fat, get leaner',
      icon: Icons.trending_down_rounded,
    ),
    _SetupOption(
      index: 1,
      label: 'Build Muscle',
      subtitle: 'Gain strength, grow muscle',
      icon: Icons.fitness_center_rounded,
    ),
    _SetupOption(
      index: 2,
      label: 'Stay Active',
      subtitle: 'Maintain health, stay fit',
      icon: Icons.directions_run_rounded,
    ),
    _SetupOption(
      index: 3,
      label: 'Improve Flexibility',
      subtitle: 'Stretch, yoga, mobility',
      icon: Icons.self_improvement_rounded,
    ),
  ];

  final _intensities = [
    _SetupOption(
      index: 0,
      label: 'Calm',
      subtitle: 'Light sessions, gentle recovery',
      icon: Icons.spa_rounded,
    ),
    _SetupOption(
      index: 1,
      label: 'Moderate',
      subtitle: 'Balanced effort, steady progress',
      icon: Icons.speed_rounded,
    ),
    _SetupOption(
      index: 2,
      label: 'Aggressive',
      subtitle: 'Push hard, fast results',
      icon: Icons.bolt_rounded,
    ),
  ];

  bool get _canContinue {
    switch (_step) {
      case 0:
        return _bodyType >= 0;
      case 1:
        return _fitnessGoal >= 0;
      case 2:
        return _intensity >= 0;
      case 3:
        return true; // workout selection is optional
      default:
        return false;
    }
  }

  Future<void> _save() async {
    final box = await Hive.openBox<FitnessProfileModel>('fitness_profile');
    final profile = FitnessProfileModel(
      bodyTypeIndex: _bodyType,
      fitnessGoalIndex: _fitnessGoal,
      intensityIndex: _intensity,
      preferredWorkoutIds: _selectedWorkouts.toList(),
      isSetUp: true,
    );
    await box.put('profile', profile);

    if (mounted) {
      widget.onComplete?.call();
    }
  }

  void _next() {
    if (!_canContinue) return;
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _save();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleColor = isDark ? Colors.white38 : Colors.black38;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_step > 0)
                GestureDetector(
                  onTap: _back,
                  child: Icon(Icons.arrow_back_rounded, color: textColor),
                )
              else
                const SizedBox(width: 24),
              // Step indicator
              Text(
                'Step ${_step + 1} of 4',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: subtleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
        ),

        // Progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: LinearProgressIndicator(
            value: (_step + 1) / 4,
            backgroundColor:
                isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
            valueColor: AlwaysStoppedAnimation<Color>(textColor),
            minHeight: 3,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        const SizedBox(height: 28),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildStepContent(isDark, textColor, subtleColor),
          ),
        ),

        // Continue button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _canContinue ? _next : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                disabledBackgroundColor: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.06),
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                _step < 3 ? 'Continue' : 'Get Started',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(bool isDark, Color textColor, Color subtleColor) {
    switch (_step) {
      case 0:
        return _buildSelectionStep(
          title: 'What\'s your\nbody type?',
          subtitle: 'This helps us tailor workout recommendations',
          options: _bodyTypes,
          selectedIndex: _bodyType,
          onSelect: (i) => setState(() => _bodyType = i),
          isDark: isDark,
          textColor: textColor,
          subtleColor: subtleColor,
        );
      case 1:
        return _buildSelectionStep(
          title: 'What\'s your\nfitness goal?',
          subtitle: 'We\'ll focus your plan around this',
          options: _goals,
          selectedIndex: _fitnessGoal,
          onSelect: (i) => setState(() => _fitnessGoal = i),
          isDark: isDark,
          textColor: textColor,
          subtleColor: subtleColor,
        );
      case 2:
        return _buildSelectionStep(
          title: 'How hard do\nyou want to go?',
          subtitle: 'This affects your recovery suggestions',
          options: _intensities,
          selectedIndex: _intensity,
          onSelect: (i) => setState(() => _intensity = i),
          isDark: isDark,
          textColor: textColor,
          subtleColor: subtleColor,
        );
      case 3:
        return _buildWorkoutStep(isDark, textColor, subtleColor);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSelectionStep({
    required String title,
    required String subtitle,
    required List<_SetupOption> options,
    required int selectedIndex,
    required ValueChanged<int> onSelect,
    required bool isDark,
    required Color textColor,
    required Color subtleColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: textColor,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 14, color: subtleColor),
        ),
        const SizedBox(height: 28),
        ...options.map((o) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _optionCard(
                option: o,
                isSelected: selectedIndex == o.index,
                onTap: () => onSelect(o.index),
                isDark: isDark,
              ),
            )),
      ],
    );
  }

  Widget _buildWorkoutStep(bool isDark, Color textColor, Color subtleColor) {
    return BlocBuilder<WorkoutBloc, WorkoutState>(
      builder: (context, state) {
        List<WorkoutTypeModel> types = [];
        if (state is WorkoutLoaded) {
          types = state.workoutTypes;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pick your\nworkouts',
              style: GoogleFonts.inter(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Select the types you enjoy (optional)',
              style: GoogleFonts.inter(fontSize: 14, color: subtleColor),
            ),
            const SizedBox(height: 28),
            if (types.isEmpty)
              Text(
                'Workout types will be available once data loads',
                style: GoogleFonts.inter(fontSize: 13, color: subtleColor),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: types.map((type) {
                  final selected = _selectedWorkouts.contains(type.id);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selectedWorkouts.remove(type.id);
                        } else {
                          _selectedWorkouts.add(type.id);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark
                                ? const Color(0xFF1A1A1A)
                                : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: selected
                            ? null
                            : Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.black.withOpacity(0.06),
                              ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type.icon,
                            size: 18,
                            color: selected
                                ? (isDark ? Colors.black : Colors.white)
                                : type.categoryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type.name,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? (isDark ? Colors.black : Colors.white)
                                  : textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _optionCard({
    required _SetupOption option,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                ),
        ),
        child: Row(
          children: [
            Icon(
              option.icon,
              color: isSelected
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark ? Colors.white54 : Colors.black45),
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isSelected
                          ? (isDark ? Colors.black54 : Colors.white54)
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: isDark ? Colors.black : Colors.white,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _SetupOption {
  final int index;
  final String label;
  final String subtitle;
  final IconData icon;

  const _SetupOption({
    required this.index,
    required this.label,
    required this.subtitle,
    required this.icon,
  });
}
