import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/wellness_checkin_model.dart';
import '../../../../core/config/secure_config.dart';

/// Full-screen daily wellness check-in page.
/// Asks: mood, energy level, optional notes.
/// Triggered by FAB tap and on app launch if not done today.
class WellnessCheckInPage extends StatefulWidget {
  const WellnessCheckInPage({super.key});

  @override
  State<WellnessCheckInPage> createState() => _WellnessCheckInPageState();
}

class _WellnessCheckInPageState extends State<WellnessCheckInPage> {
  int _currentStep = 0;
  int _selectedMood = 0;
  int _selectedEnergy = 0;
  final _notesController = TextEditingController();

  static const _moodOptions = [
    _MoodOption(value: 1, label: 'Awful', icon: Icons.sentiment_very_dissatisfied_rounded),
    _MoodOption(value: 2, label: 'Low', icon: Icons.sentiment_dissatisfied_rounded),
    _MoodOption(value: 3, label: 'Okay', icon: Icons.sentiment_neutral_rounded),
    _MoodOption(value: 4, label: 'Good', icon: Icons.sentiment_satisfied_rounded),
    _MoodOption(value: 5, label: 'Great', icon: Icons.sentiment_very_satisfied_rounded),
  ];

  static const _energyOptions = [
    _MoodOption(value: 1, label: 'Exhausted', icon: Icons.battery_alert_rounded),
    _MoodOption(value: 2, label: 'Tired', icon: Icons.battery_2_bar_rounded),
    _MoodOption(value: 3, label: 'Normal', icon: Icons.battery_4_bar_rounded),
    _MoodOption(value: 4, label: 'Energized', icon: Icons.battery_full_rounded),
    _MoodOption(value: 5, label: 'Supercharged', icon: Icons.bolt_rounded),
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCheckIn() async {
    final keyList = await SecureConfig.instance.getEncryptionKey();
    final cipher = HiveAesCipher(Uint8List.fromList(keyList));
    final box = await Hive.openBox<WellnessCheckInModel>('wellness_checkins',
        encryptionCipher: cipher);
    final today = DateTime.now();
    final key = '${today.year}-${today.month}-${today.day}';

    final checkIn = WellnessCheckInModel(
      mood: _selectedMood,
      energyLevel: _selectedEnergy,
      date: DateTime(today.year, today.month, today.day),
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    await box.put(key, checkIn);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _nextStep() {
    if (_currentStep == 0 && _selectedMood == 0) return;
    if (_currentStep == 1 && _selectedEnergy == 0) return;

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _saveCheckIn();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFBFBFB);
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleColor = isDark ? Colors.white38 : Colors.black38;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _prevStep,
                    child: Icon(
                      _currentStep > 0
                          ? Icons.arrow_back_rounded
                          : Icons.close_rounded,
                      color: textColor,
                      size: 24,
                    ),
                  ),
                  // Progress dots
                  Row(
                    children: List.generate(3, (i) {
                      return Container(
                        width: i == _currentStep ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: i == _currentStep
                              ? textColor
                              : (isDark
                                  ? Colors.white.withOpacity(0.15)
                                  : Colors.black.withOpacity(0.08)),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 24),
                ],
              ),

              const Spacer(flex: 1),

              // Step content
              if (_currentStep == 0) ...[
                Text(
                  'How are you\nfeeling today?',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This helps us personalize your wellness journey',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: subtleColor,
                  ),
                ),
                const SizedBox(height: 36),
                ..._moodOptions.map((option) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildOptionCard(
                        option: option,
                        isSelected: _selectedMood == option.value,
                        onTap: () =>
                            setState(() => _selectedMood = option.value),
                        isDark: isDark,
                      ),
                    )),
              ],

              if (_currentStep == 1) ...[
                Text(
                  'What\'s your\nenergy level?',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We\'ll adjust suggestions based on your energy',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: subtleColor,
                  ),
                ),
                const SizedBox(height: 36),
                ..._energyOptions.map((option) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildOptionCard(
                        option: option,
                        isSelected: _selectedEnergy == option.value,
                        onTap: () =>
                            setState(() => _selectedEnergy = option.value),
                        isDark: isDark,
                      ),
                    )),
              ],

              if (_currentStep == 2) ...[
                Text(
                  'Anything on\nyour mind?',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Optional -- jot down anything you\'d like to note',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: subtleColor,
                  ),
                ),
                const SizedBox(height: 36),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.06),
                    ),
                  ),
                  child: TextField(
                    controller: _notesController,
                    maxLines: 4,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'How was your sleep? Any goals for today?',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 15,
                        color: subtleColor,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],

              const Spacer(flex: 2),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_currentStep == 0 && _selectedMood == 0) ||
                          (_currentStep == 1 && _selectedEnergy == 0)
                      ? null
                      : _nextStep,
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
                    _currentStep < 2 ? 'Continue' : 'Done',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (_currentStep == 2)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                    child: GestureDetector(
                      onTap: _saveCheckIn,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: subtleColor,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required _MoodOption option,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            Text(
              option.label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark ? Colors.white : Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodOption {
  final int value;
  final String label;
  final IconData icon;

  const _MoodOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}
