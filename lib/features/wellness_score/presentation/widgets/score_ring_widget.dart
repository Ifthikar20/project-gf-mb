import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated circular score ring (0-100) with gradient color.
///
/// Color transitions:
///  0-40:  Red → Orange
///  40-70: Orange → Yellow
///  70-100: Yellow → Green
class ScoreRingWidget extends StatefulWidget {
  final int score;
  final double size;
  final double strokeWidth;
  final String? label;
  final TextStyle? labelStyle;
  final TextStyle? scoreStyle;
  final Duration animationDuration;

  const ScoreRingWidget({
    super.key,
    required this.score,
    this.size = 180,
    this.strokeWidth = 14,
    this.label,
    this.labelStyle,
    this.scoreStyle,
    this.animationDuration = const Duration(milliseconds: 1200),
  });

  @override
  State<ScoreRingWidget> createState() => _ScoreRingWidgetState();
}

class _ScoreRingWidgetState extends State<ScoreRingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = Tween<double>(begin: 0, end: widget.score / 100)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(ScoreRingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.score / 100,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getScoreColor(double progress) {
    final score = (progress * 100).round();
    if (score < 30) return Color.lerp(const Color(0xFFEF4444), const Color(0xFFF97316), score / 30)!;
    if (score < 50) return Color.lerp(const Color(0xFFF97316), const Color(0xFFEAB308), (score - 30) / 20)!;
    if (score < 70) return Color.lerp(const Color(0xFFEAB308), const Color(0xFF84CC16), (score - 50) / 20)!;
    return Color.lerp(const Color(0xFF84CC16), const Color(0xFF22C55E), (score - 70) / 30)!;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final progress = _animation.value;
        final displayScore = (progress * 100).round();
        final color = _getScoreColor(progress);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background ring
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: 1.0,
                  color: Colors.white.withOpacity(0.06),
                  strokeWidth: widget.strokeWidth,
                ),
              ),
              // Colored progress ring
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: progress,
                  color: color,
                  strokeWidth: widget.strokeWidth,
                  hasShadow: true,
                ),
              ),
              // Score text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$displayScore',
                    style: widget.scoreStyle ?? TextStyle(
                      color: Colors.white,
                      fontSize: widget.size * 0.22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  if (widget.label != null)
                    Text(
                      widget.label!,
                      style: widget.labelStyle ?? TextStyle(
                        color: color.withOpacity(0.8),
                        fontSize: widget.size * 0.07,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool hasShadow;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    this.hasShadow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (hasShadow && progress > 0) {
      final shadowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..strokeWidth = strokeWidth + 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        shadowPaint,
      );
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
