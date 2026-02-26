import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/personalization_service.dart';
import '../navigation/app_router.dart';
import 'auth_bloc.dart';

/// 5-step onboarding flow shown after first login/register
/// Fetches options dynamically from the backend
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  // Options from backend
  Map<String, dynamic>? _options;

  // User selections
  List<String> _selectedGoals = [];
  String _experienceLevel = '';
  String _sessionDuration = '';
  List<String> _selectedInterests = [];
  String _timeOfDay = '';

  // Theme colors
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color darkBg = Color(0xFF0A0A0A);
  static const Color cardBg = Color(0xFF1A1A1A);
  static const Color cardBorder = Color(0xFF2A2A2A);

  // Step configuration
  static const _stepTitles = [
    'What are your goals?',
    'Your experience level',
    'Session duration',
    'What interests you?',
    'Preferred time',
  ];

  static const _stepSubtitles = [
    'Select all that apply — we\'ll personalize your experience',
    'This helps us recommend the right content',
    'How long do you prefer your sessions?',
    'Choose topics you\'d like to explore',
    'When do you usually practice?',
  ];

  static const _stepIcons = [
    Icons.flag_outlined,
    Icons.trending_up,
    Icons.timer_outlined,
    Icons.explore_outlined,
    Icons.schedule_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final data = await PersonalizationService.instance.getOnboardingOptions();
      setState(() {
        _options = data['options'];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load onboarding options: $e');
      setState(() {
        _isLoading = false;
        _error = 'Could not load options. Please try again.';
      });
    }
  }

  Future<void> _submitOnboarding() async {
    setState(() => _isSubmitting = true);

    try {
      await PersonalizationService.instance.submitOnboarding(
        fitnessGoals: _selectedGoals,
        experienceLevel: _experienceLevel,
        preferredSessionDuration: _sessionDuration,
        interests: _selectedInterests,
        preferredTimeOfDay: _timeOfDay,
      );

      if (!mounted) return;

      // Mark onboarding complete in auth state and navigate home
      context.read<AuthBloc>().add(AuthOnboardingCompleted());
      context.go(AppRouter.home);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  void _skipOnboarding() {
    context.read<AuthBloc>().add(AuthOnboardingCompleted());
    context.go(AppRouter.home);
  }

  void _nextStep() {
    if (_currentStep < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _submitOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _selectedGoals.isNotEmpty;
      case 1:
        return _experienceLevel.isNotEmpty;
      case 2:
        return _sessionDuration.isNotEmpty;
      case 3:
        return _selectedInterests.isNotEmpty;
      case 4:
        return _timeOfDay.isNotEmpty;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _error != null && _options == null
                ? _buildErrorState()
                : _buildOnboardingFlow(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryPurple),
          SizedBox(height: 16),
          Text(
            'Preparing your experience…',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadOptions();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('Retry'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _skipOnboarding,
              child: const Text(
                'Skip for now',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingFlow() {
    return Column(
      children: [
        // Top bar: back + progress + skip
        _buildTopBar(),

        // Step header
        _buildStepHeader(),

        // Page content
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentStep = index),
            children: [
              _buildGoalsStep(),
              _buildExperienceLevelStep(),
              _buildSessionDurationStep(),
              _buildInterestsStep(),
              _buildTimeOfDayStep(),
            ],
          ),
        ),

        // Error message
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade300, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Bottom: Next / Get Started button
        _buildBottomButton(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          // Back button (hidden on first step)
          if (_currentStep > 0)
            IconButton(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
            )
          else
            const SizedBox(width: 48),

          // Progress bar
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: (_currentStep + 1) / 5),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 4,
                    backgroundColor: cardBg,
                    valueColor: const AlwaysStoppedAnimation<Color>(primaryPurple),
                  ),
                ),
              ),
            ),
          ),

          // Skip button
          TextButton(
            onPressed: _skipOnboarding,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Skip',
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
      child: Column(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primaryPurple.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _stepIcons[_currentStep],
              color: primaryPurple,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            _stepTitles[_currentStep],
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Subtitle
          Text(
            _stepSubtitles[_currentStep],
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    final isLastStep = _currentStep == 4;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _canProceed ? (_isSubmitting ? null : _nextStep) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPurple,
            disabledBackgroundColor: primaryPurple.withValues(alpha: 0.3),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            elevation: 0,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  isLastStep ? 'Get Started' : 'Continue',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  // ============================================
  // Step 1: Fitness Goals (multi-select)
  // ============================================
  Widget _buildGoalsStep() {
    final goals = _options?['fitness_goals'] as List<dynamic>? ?? [];

    return _buildChipGrid(
      items: goals.cast<String>(),
      selected: _selectedGoals,
      onToggle: (goal) {
        setState(() {
          if (_selectedGoals.contains(goal)) {
            _selectedGoals.remove(goal);
          } else {
            _selectedGoals.add(goal);
          }
        });
      },
      iconMapper: _goalIcon,
    );
  }

  // ============================================
  // Step 2: Experience Level (single-select)
  // ============================================
  Widget _buildExperienceLevelStep() {
    final levels = _options?['experience_levels'] as List<dynamic>? ?? [];

    return _buildCardList(
      items: levels,
      selectedValue: _experienceLevel,
      onSelect: (value) => setState(() => _experienceLevel = value),
      iconMapper: _levelIcon,
      descriptionMapper: _levelDescription,
    );
  }

  // ============================================
  // Step 3: Session Duration (single-select)
  // ============================================
  Widget _buildSessionDurationStep() {
    final durations = _options?['session_durations'] as List<dynamic>? ?? [];

    return _buildCardList(
      items: durations,
      selectedValue: _sessionDuration,
      onSelect: (value) => setState(() => _sessionDuration = value),
      iconMapper: _durationIcon,
    );
  }

  // ============================================
  // Step 4: Interests (multi-select)
  // ============================================
  Widget _buildInterestsStep() {
    final interests = _options?['interests'] as List<dynamic>? ?? [];

    return _buildChipGrid(
      items: interests.cast<String>(),
      selected: _selectedInterests,
      onToggle: (interest) {
        setState(() {
          if (_selectedInterests.contains(interest)) {
            _selectedInterests.remove(interest);
          } else {
            _selectedInterests.add(interest);
          }
        });
      },
      iconMapper: _interestIcon,
    );
  }

  // ============================================
  // Step 5: Time of Day (single-select)
  // ============================================
  Widget _buildTimeOfDayStep() {
    final times = _options?['times_of_day'] as List<dynamic>? ?? [];

    return _buildCardList(
      items: times,
      selectedValue: _timeOfDay,
      onSelect: (value) => setState(() => _timeOfDay = value),
      iconMapper: _timeIcon,
    );
  }

  // ============================================
  // Reusable Builders
  // ============================================

  /// Multi-select chip grid (for goals + interests)
  Widget _buildChipGrid({
    required List<String> items,
    required List<String> selected,
    required void Function(String) onToggle,
    IconData Function(String)? iconMapper,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items.map((item) {
          final isSelected = selected.contains(item);
          final label = _formatLabel(item);

          return GestureDetector(
            onTap: () => onToggle(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryPurple.withValues(alpha: 0.2)
                    : cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? primaryPurple : cardBorder,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (iconMapper != null) ...[
                    Icon(
                      iconMapper(item),
                      size: 18,
                      color: isSelected ? primaryPurple : Colors.white54,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.check_circle, size: 16, color: primaryPurple),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Single-select card list (for level, duration, time)
  Widget _buildCardList({
    required List<dynamic> items,
    required String selectedValue,
    required void Function(String) onSelect,
    IconData Function(String)? iconMapper,
    String Function(String)? descriptionMapper,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        children: items.map((item) {
          final value = item is Map ? item['value'] as String : item.toString();
          final label = item is Map
              ? item['label'] as String
              : _formatLabel(item.toString());
          final isSelected = selectedValue == value;
          final description = descriptionMapper?.call(value);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => onSelect(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryPurple.withValues(alpha: 0.15)
                      : cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? primaryPurple : cardBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (iconMapper != null) ...[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryPurple.withValues(alpha: 0.2)
                              : cardBorder.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          iconMapper(value),
                          size: 22,
                          color: isSelected ? primaryPurple : Colors.white54,
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          if (description != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              description,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Radio indicator
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? primaryPurple : Colors.white30,
                          width: 2,
                        ),
                        color: isSelected
                            ? primaryPurple
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================
  // Icon Mappers
  // ============================================

  String _formatLabel(String raw) {
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  IconData _goalIcon(String goal) {
    switch (goal) {
      case 'reduce_stress':
        return Icons.spa;
      case 'better_sleep':
        return Icons.bedtime_outlined;
      case 'build_strength':
        return Icons.fitness_center;
      case 'lose_weight':
        return Icons.monitor_weight_outlined;
      case 'improve_focus':
        return Icons.center_focus_strong;
      case 'increase_flexibility':
        return Icons.accessibility_new;
      case 'boost_energy':
        return Icons.bolt;
      case 'manage_anxiety':
        return Icons.self_improvement;
      case 'build_habit':
        return Icons.calendar_today;
      case 'general_wellness':
        return Icons.favorite_border;
      default:
        return Icons.flag_outlined;
    }
  }

  IconData _levelIcon(String level) {
    switch (level) {
      case 'beginner':
        return Icons.eco;
      case 'intermediate':
        return Icons.trending_up;
      case 'advanced':
        return Icons.rocket_launch;
      default:
        return Icons.star_border;
    }
  }

  String _levelDescription(String level) {
    switch (level) {
      case 'beginner':
        return 'New to wellness practices';
      case 'intermediate':
        return 'Some experience with wellness routines';
      case 'advanced':
        return 'Regular practitioner looking for challenges';
      default:
        return '';
    }
  }

  IconData _durationIcon(String duration) {
    switch (duration) {
      case '5min':
        return Icons.flash_on;
      case '10min':
        return Icons.timer;
      case '15min':
        return Icons.timer_outlined;
      case '30min':
        return Icons.hourglass_bottom;
      case '45min+':
        return Icons.hourglass_full;
      default:
        return Icons.schedule;
    }
  }

  IconData _interestIcon(String interest) {
    switch (interest) {
      case 'yoga':
        return Icons.self_improvement;
      case 'meditation':
        return Icons.spa;
      case 'hiit':
        return Icons.flash_on;
      case 'breathing':
        return Icons.air;
      case 'pilates':
        return Icons.accessibility_new;
      case 'stretching':
        return Icons.accessibility;
      case 'strength':
        return Icons.fitness_center;
      case 'cardio':
        return Icons.directions_run;
      case 'mindfulness':
        return Icons.psychology;
      case 'sleep_stories':
        return Icons.bedtime;
      case 'nutrition':
        return Icons.restaurant;
      case 'journaling':
        return Icons.edit_note;
      case 'walking':
        return Icons.directions_walk;
      case 'running':
        return Icons.directions_run;
      default:
        return Icons.explore;
    }
  }

  IconData _timeIcon(String time) {
    switch (time) {
      case 'morning':
        return Icons.wb_sunny_outlined;
      case 'afternoon':
        return Icons.wb_cloudy_outlined;
      case 'evening':
        return Icons.nightlight_outlined;
      case 'anytime':
        return Icons.schedule;
      default:
        return Icons.access_time;
    }
  }
}
