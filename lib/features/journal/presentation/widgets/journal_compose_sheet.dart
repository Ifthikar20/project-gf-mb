import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/presentation/widgets/mood_selector_widget.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/journal_bloc.dart';
import '../bloc/journal_event.dart';
import '../bloc/journal_state.dart';

/// Bottom sheet for composing a new journal entry.
///
/// Reuses the existing [Moods.all] mood options from the core mood selector.
/// Shows mood selection grid → optional intensity slider → reflection text → submit.
class JournalComposeSheet extends StatefulWidget {
  const JournalComposeSheet({super.key});

  @override
  State<JournalComposeSheet> createState() => _JournalComposeSheetState();
}

class _JournalComposeSheetState extends State<JournalComposeSheet>
    with SingleTickerProviderStateMixin {
  String? _selectedMoodId;
  double _intensity = 3;
  final _reflectionController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedMoodId == null) return;
    context.read<JournalBloc>().add(SubmitJournalEntry(
          mood: _selectedMoodId!,
          moodIntensity: _intensity.round(),
          reflectionText: _reflectionController.text.trim(),
        ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final isLight = themeState.isLight;
        final bgColor = isLight ? Colors.white : const Color(0xFF141414);
        final surfaceColor = isLight
            ? Colors.grey.shade100
            : Colors.white.withOpacity(0.05);
        final textColor =
            isLight ? const Color(0xFF1A1A1A) : Colors.white;
        final textSecondary =
            isLight ? Colors.grey.shade600 : Colors.white60;
        final selectedMood = _selectedMoodId != null
            ? Moods.getById(_selectedMoodId!)
            : null;

        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: isLight
                    ? Colors.grey.shade200
                    : Colors.white.withOpacity(0.08),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          'How are you feeling?',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Log your mood and reflect on your day',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Mood Selection ──
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: Moods.all.map((mood) {
                            final isSelected = _selectedMoodId == mood.id;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedMoodId = mood.id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? mood.color
                                      : mood.color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: mood.color,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color:
                                                mood.color.withOpacity(0.4),
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
                                      color: isSelected
                                          ? Colors.white
                                          : mood.color,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      mood.label,
                                      style: GoogleFonts.inter(
                                        color: isSelected
                                            ? Colors.white
                                            : mood.color,
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        // ── Intensity Slider (visible after mood selection) ──
                        if (_selectedMoodId != null) ...[
                          const SizedBox(height: 28),
                          Text(
                            'Intensity',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('Mild',
                                  style: GoogleFonts.inter(
                                      fontSize: 12, color: textSecondary)),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor:
                                        selectedMood?.color ??
                                            Colors.blue,
                                    inactiveTrackColor:
                                        (selectedMood?.color ??
                                                Colors.blue)
                                            .withOpacity(0.2),
                                    thumbColor:
                                        selectedMood?.color ??
                                            Colors.blue,
                                    overlayColor:
                                        (selectedMood?.color ??
                                                Colors.blue)
                                            .withOpacity(0.15),
                                  ),
                                  child: Slider(
                                    value: _intensity,
                                    min: 1,
                                    max: 5,
                                    divisions: 4,
                                    onChanged: (v) =>
                                        setState(() => _intensity = v),
                                  ),
                                ),
                              ),
                              Text('Strong',
                                  style: GoogleFonts.inter(
                                      fontSize: 12, color: textSecondary)),
                            ],
                          ),
                        ],

                        // ── Reflection Text ──
                        if (_selectedMoodId != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isLight
                                    ? Colors.grey.shade300
                                    : Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: TextField(
                              controller: _reflectionController,
                              maxLines: 4,
                              maxLength: 500,
                              style: GoogleFonts.inter(
                                color: textColor,
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    "What's on your mind today? (optional)",
                                hintStyle: GoogleFonts.inter(
                                  color: textSecondary,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(16),
                                counterStyle: GoogleFonts.inter(
                                  color: textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],

                        // ── Submit Button ──
                        if (_selectedMoodId != null) ...[
                          const SizedBox(height: 24),
                          BlocBuilder<JournalBloc, JournalState>(
                            builder: (context, journalState) {
                              final isSubmitting = journalState
                                      is JournalLoaded &&
                                  journalState.isSubmitting;
                              return SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed:
                                      isSubmitting ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        selectedMood?.color ??
                                            Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: isSubmitting
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'Save & Get AI Insight',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
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
