import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/presentation/widgets/mood_selector_widget.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/journal_entry.dart';

/// Glassmorphism card displaying the Gemini-generated AI insight.
///
/// The card's gradient matches the mood color. A "suggested action" chip
/// deep-links to relevant content (breathing exercise, meditation, workout).
class AiInsightCard extends StatefulWidget {
  final JournalEntry entry;

  const AiInsightCard({super.key, required this.entry});

  @override
  State<AiInsightCard> createState() => _AiInsightCardState();
}

class _AiInsightCardState extends State<AiInsightCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = Moods.getById(widget.entry.mood);
    final moodColor = mood?.color ?? const Color(0xFF81C784);

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final isLight = themeState.isLight;

        return SlideTransition(
          position: _slideIn,
          child: FadeTransition(
            opacity: _fadeIn,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isLight
                            ? [
                                moodColor.withOpacity(0.12),
                                moodColor.withOpacity(0.06),
                                Colors.white.withOpacity(0.9),
                              ]
                            : [
                                moodColor.withOpacity(0.15),
                                moodColor.withOpacity(0.05),
                                Colors.white.withOpacity(0.03),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: moodColor.withOpacity(isLight ? 0.2 : 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: moodColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: moodColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI Wellness Insight',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isLight
                                          ? const Color(0xFF1A1A1A)
                                          : Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Powered by Gemini',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: isLight
                                          ? Colors.grey.shade500
                                          : Colors.white38,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Mood badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: moodColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(mood?.icon ?? Icons.mood,
                                      color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    mood?.label ?? widget.entry.mood,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Insight text
                        if (widget.entry.aiInsight.isNotEmpty)
                          Text(
                            widget.entry.aiInsight,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              height: 1.6,
                              color: isLight
                                  ? const Color(0xFF2D2D2D)
                                  : Colors.white.withOpacity(0.85),
                            ),
                          ),

                        // Suggested action chip
                        if (widget.entry.suggestedActionLabel.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () {
                              final route = widget.entry.suggestedAction;
                              if (route.isNotEmpty) {
                                context.push(route);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: moodColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: moodColor.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_forward_rounded,
                                      color: moodColor, size: 16),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      widget.entry.suggestedActionLabel,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: moodColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
