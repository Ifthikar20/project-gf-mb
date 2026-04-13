import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';

/// AI-generated gratitude prompt card.
///
/// Displayed below the insight card to encourage reflective gratitude practice.
class GratitudePromptCard extends StatefulWidget {
  final String prompt;

  const GratitudePromptCard({super.key, required this.prompt});

  @override
  State<GratitudePromptCard> createState() => _GratitudePromptCardState();
}

class _GratitudePromptCardState extends State<GratitudePromptCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    // Delay slightly so it appears after the insight card
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.prompt.isEmpty) return const SizedBox.shrink();

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final isLight = themeState.isLight;

        return FadeTransition(
          opacity: _fadeIn,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isLight
                    ? [
                        const Color(0xFFFFF8E1),
                        const Color(0xFFFFF3E0),
                      ]
                    : [
                        const Color(0xFFFFD54F).withOpacity(0.08),
                        const Color(0xFFFFB74D).withOpacity(0.04),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isLight
                    ? const Color(0xFFFFE082)
                    : const Color(0xFFFFD54F).withOpacity(0.12),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFFF8A65),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gratitude Moment',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isLight
                              ? const Color(0xFF5D4037)
                              : const Color(0xFFFFD54F),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.prompt,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.5,
                          color: isLight
                              ? const Color(0xFF4E342E)
                              : Colors.white.withOpacity(0.75),
                        ),
                      ),
                    ],
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
