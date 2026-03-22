import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_theme.dart';

/// An animated breathing exercise card for the Explore page.
/// Features a pulsing circle animation that mimics the breathing rhythm.
class BreathingExerciseCard extends StatefulWidget {
  final bool isLight;

  const BreathingExerciseCard({super.key, required this.isLight});

  @override
  State<BreathingExerciseCard> createState() => _BreathingExerciseCardState();
}

class _BreathingExerciseCardState extends State<BreathingExerciseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = widget.isLight;

    final textColor = isLight ? ThemeColors.lightTextPrimary : ThemeColors.darkTextPrimary;
    final textSecondary = isLight ? ThemeColors.lightTextSecondary : ThemeColors.darkTextSecondary;

    const accentColor = Color(0xFF06B6D4); // Cyan
    const accentGradient = [Color(0xFF06B6D4), Color(0xFF8B5CF6)]; // Cyan → Purple

    return GestureDetector(
      onTap: () => context.push(AppRouter.breathingExercise),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLight
                ? [const Color(0xFFF0FDFA), const Color(0xFFF5F3FF)]
                : [const Color(0xFF0A2A2A), const Color(0xFF1A1030)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLight
                ? accentColor.withOpacity(0.2)
                : accentColor.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            // Animated breathing circle
            SizedBox(
              width: 80,
              height: 80,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ring 1 (rotating)
                      Transform.rotate(
                        angle: _rotationAnimation.value,
                        child: Container(
                          width: 80 * _scaleAnimation.value,
                          height: 80 * _scaleAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accentColor.withOpacity(
                                  _opacityAnimation.value * 0.4),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      // Outer ring 2 (counter-rotating)
                      Transform.rotate(
                        angle: -_rotationAnimation.value * 0.7,
                        child: Container(
                          width: 64 * _scaleAnimation.value,
                          height: 64 * _scaleAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF8B5CF6).withOpacity(
                                  _opacityAnimation.value * 0.3),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      // Pulsing core
                      Container(
                        width: 48 * _scaleAnimation.value,
                        height: 48 * _scaleAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              accentColor.withOpacity(
                                  _opacityAnimation.value),
                              const Color(0xFF8B5CF6).withOpacity(
                                  _opacityAnimation.value * 0.5),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                      // Center dot
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.9),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      // Orbiting dots
                      ...List.generate(3, (i) {
                        final angle = _rotationAnimation.value +
                            (i * 2 * math.pi / 3);
                        final radius = 30.0 * _scaleAnimation.value;
                        return Positioned(
                          left: 40 + radius * math.cos(angle) - 3,
                          top: 40 + radius * math.sin(angle) - 3,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentGradient[i % 2].withOpacity(
                                  _opacityAnimation.value),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'BREATHE',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Box Breathing',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Calm your mind with guided breathing exercises',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 13, color: textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '4 min',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: textSecondary),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Try Now →',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
