import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "Are you working out today?" — Yes / No prompt screen.
class WorkoutCheckPage extends StatelessWidget {
  const WorkoutCheckPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final bgColor = ThemeColors.background(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        final isDark = mode == AppThemeMode.dark;

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Illustration
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6366F1).withOpacity(0.15),
                          const Color(0xFF8B5CF6).withOpacity(0.08),
                        ],
                      ),
                    ),
                    child: const Center(
                    child: Icon(Icons.fitness_center_rounded, color: const Color(0xFF6366F1), size: 56),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Are you working\nout today?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Let\'s make it count!',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: textSecondary,
                    ),
                  ),
                  const Spacer(flex: 2),
                  // YES button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const _WorkoutTypePage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Yes, let\'s go!',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // NO button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textSecondary,
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.12)
                              : Colors.black.withOpacity(0.1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Not today',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Workout Type Selection (inline)
// ─────────────────────────────────────────────

class _WorkoutTypePage extends StatelessWidget {
  const _WorkoutTypePage();

  static const _types = [
    _WorkoutType(Icons.fitness_center_rounded, 'Gym', 'Weight Training'),
    _WorkoutType(Icons.directions_run_rounded, 'Running', 'Cardio'),
    _WorkoutType(Icons.self_improvement_rounded, 'Yoga', 'Stretching'),
    _WorkoutType(Icons.pedal_bike_rounded, 'Cycling', 'Endurance'),
    _WorkoutType(Icons.pool_rounded, 'Swimming', 'Full Body'),
    _WorkoutType(Icons.local_fire_department_rounded, 'HIIT', 'High Intensity'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final bgColor = ThemeColors.background(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final surfaceColor = ThemeColors.surface(mode);
        final isDark = mode == AppThemeMode.dark;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, color: textColor, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Choose Workout',
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.1,
              ),
              itemCount: _types.length,
              itemBuilder: (context, index) {
                final t = _types[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _WorkoutQuestionsPage(workoutType: t.name),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(t.icon, size: 40, color: ThemeColors.textPrimary(mode)),
                        const SizedBox(height: 12),
                        Text(
                          t.name,
                          style: GoogleFonts.inter(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.subtitle,
                          style: GoogleFonts.inter(
                            color: ThemeColors.textSecondary(mode),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _WorkoutType {
  final IconData icon;
  final String name;
  final String subtitle;
  const _WorkoutType(this.icon, this.name, this.subtitle);
}

// ─────────────────────────────────────────────
// Workout Questions
// ─────────────────────────────────────────────

class _WorkoutQuestionsPage extends StatefulWidget {
  final String workoutType;
  const _WorkoutQuestionsPage({required this.workoutType});

  @override
  State<_WorkoutQuestionsPage> createState() => _WorkoutQuestionsPageState();
}

class _WorkoutQuestionsPageState extends State<_WorkoutQuestionsPage> {
  int _selectedDuration = 30;
  String _selectedIntensity = 'Medium';
  String _selectedFocus = 'Full Body';

  static const _durations = [15, 30, 45, 60, 90];
  static const _intensities = ['Low', 'Medium', 'High'];

  List<String> get _focusAreas {
    switch (widget.workoutType) {
      case 'Gym':
        return ['Upper Body', 'Lower Body', 'Full Body', 'Core'];
      case 'Running':
        return ['Endurance', 'Sprints', 'Intervals', 'Recovery'];
      case 'Yoga':
        return ['Flexibility', 'Strength', 'Balance', 'Relaxation'];
      default:
        return ['Full Body', 'Upper Body', 'Lower Body', 'Core'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final bgColor = ThemeColors.background(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        final surfaceColor = ThemeColors.surface(mode);
        final isDark = mode == AppThemeMode.dark;
        final accent = const Color(0xFF6366F1);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, color: textColor, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              widget.workoutType,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Duration
                _sectionTitle('How long?', textColor),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _durations.map((d) {
                    final selected = _selectedDuration == d;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDuration = d),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? accent : surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? accent
                                : isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.black.withOpacity(0.06),
                          ),
                        ),
                        child: Text(
                          '$d min',
                          style: GoogleFonts.inter(
                            color: selected ? Colors.white : textColor,
                            fontSize: 15,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // Intensity
                _sectionTitle('Intensity', textColor),
                const SizedBox(height: 12),
                Row(
                  children: _intensities.map((i) {
                    final selected = _selectedIntensity == i;
                    final colors = {
                      'Low': const Color(0xFF22C55E),
                      'Medium': const Color(0xFFF59E0B),
                      'High': const Color(0xFFEF4444),
                    };
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedIntensity = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(
                              right: i != 'High' ? 10 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: selected
                                ? colors[i]!.withOpacity(0.15)
                                : surfaceColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? colors[i]!
                                  : isDark
                                      ? Colors.white.withOpacity(0.08)
                                      : Colors.black.withOpacity(0.06),
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                i == 'Low'
                                    ? Icons.trending_flat_rounded
                                    : i == 'Medium'
                                        ? Icons.trending_up_rounded
                                        : Icons.local_fire_department_rounded,
                                color: selected ? colors[i] : textSecondary,
                                size: 24,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                i,
                                style: GoogleFonts.inter(
                                  color: selected ? colors[i] : textColor,
                                  fontSize: 14,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // Focus area
                _sectionTitle('Focus Area', textColor),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _focusAreas.map((f) {
                    final selected = _selectedFocus == f;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFocus = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? accent : surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? accent
                                : isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.black.withOpacity(0.06),
                          ),
                        ),
                        child: Text(
                          f,
                          style: GoogleFonts.inter(
                            color: selected ? Colors.white : textColor,
                            fontSize: 15,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 48),

                // Start button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to connect device page
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const _ConnectDevicePage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Start Workout',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: color,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Connect Device (inline, last step)
// ─────────────────────────────────────────────

class _ConnectDevicePage extends StatefulWidget {
  const _ConnectDevicePage();

  @override
  State<_ConnectDevicePage> createState() => _ConnectDevicePageState();
}

class _ConnectDevicePageState extends State<_ConnectDevicePage> {
  String? _selectedDevice;

  static const _devices = [
    _DeviceOption(Icons.watch_rounded, 'Apple Watch', 'Seamless iOS integration', Color(0xFF1D1D1F)),
    _DeviceOption(Icons.watch_later_rounded, 'Fitbit', 'Steps, HR & sleep', Color(0xFF00B0B9)),
    _DeviceOption(Icons.terrain_rounded, 'Garmin', 'Advanced fitness metrics', Color(0xFF007CC3)),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final bgColor = ThemeColors.background(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        final surfaceColor = ThemeColors.surface(mode);
        final isDark = mode == AppThemeMode.dark;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, color: textColor, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connect a\nDevice',
                  style: GoogleFonts.inter(
                    color: textColor,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track your heart rate & performance in real time',
                  style: GoogleFonts.inter(
                    color: textSecondary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 32),
                // Device cards
                ...List.generate(_devices.length, (i) {
                  final d = _devices[i];
                  final selected = _selectedDevice == d.name;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDevice = d.name),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF6366F1)
                                : isDark
                                    ? Colors.white.withOpacity(0.06)
                                    : Colors.black.withOpacity(0.05),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: d.brandColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                              child: Icon(d.icon,
                                  color: d.brandColor, size: 24),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.name,
                                    style: GoogleFonts.inter(
                                      color: textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    d.subtitle,
                                    style: GoogleFonts.inter(
                                      color: textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF6366F1),
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                // Continue
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // Pop all the way back to home
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _selectedDevice != null ? 'Continue' : 'Skip for now',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DeviceOption {
  final IconData icon;
  final String name;
  final String subtitle;
  final Color brandColor;
  const _DeviceOption(this.icon, this.name, this.subtitle, this.brandColor);
}
