import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/presentation/widgets/mood_selector_widget.dart';

/// Bottom sheet for creating/editing a journal entry.
///
/// Reuses the existing Moods data from mood_selector_widget.dart for
/// consistent mood options and colors across the app.
class JournalComposeSheet extends StatefulWidget {
  final String? existingMood;
  final int existingIntensity;
  final String existingReflection;
  final bool isEditing;
  final ValueChanged<Map<String, dynamic>> onSubmit;

  const JournalComposeSheet({
    super.key,
    this.existingMood,
    this.existingIntensity = 3,
    this.existingReflection = '',
    this.isEditing = false,
    required this.onSubmit,
  });

  @override
  State<JournalComposeSheet> createState() => _JournalComposeSheetState();
}

class _JournalComposeSheetState extends State<JournalComposeSheet>
    with SingleTickerProviderStateMixin {
  late String? _selectedMood;
  late int _intensity;
  late TextEditingController _reflectionController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.existingMood;
    _intensity = widget.existingIntensity;
    _reflectionController = TextEditingController(text: widget.existingReflection);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedMood == null) return;
    widget.onSubmit({
      'mood': _selectedMood!,
      'mood_intensity': _intensity,
      'reflection_text': _reflectionController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final bgColor = ThemeColors.surface(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        final selectedMoodData = _selectedMood != null ? Moods.getById(_selectedMood!) : null;
        final accentColor = selectedMoodData?.color ?? ThemeColors.primary(mode);

        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      widget.isEditing ? 'Edit Your Journal' : 'Daily Check-In',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'How are you feeling right now?',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Mood selector
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: Moods.all.map((mood) {
                        final isSelected = _selectedMood == mood.id;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedMood = mood.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? mood.color : mood.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isSelected ? mood.color : mood.color.withOpacity(0.3),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: mood.color.withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  mood.icon,
                                  color: isSelected ? Colors.white : mood.color,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  mood.label,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : mood.color,
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Intensity slider
                    if (_selectedMood != null) ...[
                      Text(
                        'Intensity',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Mild', style: TextStyle(color: textSecondary, fontSize: 11)),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: accentColor,
                                inactiveTrackColor: accentColor.withOpacity(0.2),
                                thumbColor: accentColor,
                                overlayColor: accentColor.withOpacity(0.1),
                                trackHeight: 4,
                              ),
                              child: Slider(
                                value: _intensity.toDouble(),
                                min: 1,
                                max: 5,
                                divisions: 4,
                                onChanged: (v) => setState(() => _intensity = v.round()),
                              ),
                            ),
                          ),
                          Text('Strong', style: TextStyle(color: textSecondary, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Reflection text field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: TextField(
                        controller: _reflectionController,
                        maxLines: 4,
                        style: TextStyle(color: textColor, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: "What's on your mind today? (optional)",
                          hintStyle: TextStyle(
                            color: textSecondary.withOpacity(0.6),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: ElevatedButton(
                          onPressed: _selectedMood != null ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: _selectedMood != null ? 4 : 0,
                            shadowColor: accentColor.withOpacity(0.4),
                          ),
                          child: Text(
                            widget.isEditing ? 'Update Journal' : 'Save & Get AI Insight ✨',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
