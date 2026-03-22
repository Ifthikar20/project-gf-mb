import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'calm_down_sheet.dart';

/// Live heart rate monitor card.
/// Uses simulated data — replace with real wearable data later.
class HeartRateMonitorCard extends StatefulWidget {
  const HeartRateMonitorCard({super.key});

  @override
  State<HeartRateMonitorCard> createState() => _HeartRateMonitorCardState();
}

class _HeartRateMonitorCardState extends State<HeartRateMonitorCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Timer _hrTimer;
  int _currentBPM = 72;
  bool _calmDownShown = false;
  final _random = Random();

  // Simulates heart rate changes
  static const _hrThreshold = 150;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // Simulate HR changes every 3 seconds
    _hrTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        // Random walk: ±15 BPM, clamped to 55-180
        _currentBPM = (_currentBPM + _random.nextInt(31) - 15).clamp(55, 180);
      });
      _checkThreshold();
    });
  }

  void _checkThreshold() {
    if (_currentBPM >= _hrThreshold && !_calmDownShown) {
      _calmDownShown = true;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const CalmDownSheet(),
      ).then((_) => _calmDownShown = false);
    }
  }

  Color get _bpmColor {
    if (_currentBPM < 100) return const Color(0xFF22C55E);
    if (_currentBPM < 140) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String get _zone {
    if (_currentBPM < 100) return 'Resting';
    if (_currentBPM < 120) return 'Fat Burn';
    if (_currentBPM < 150) return 'Cardio';
    return 'Peak';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _hrTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F5F5);


    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          // Pulse icon
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + 0.15 * _pulseController.value;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _bpmColor.withOpacity(0.15),
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: _bpmColor,
                    size: 28,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          // BPM info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$_currentBPM',
                      style: GoogleFonts.inter(
                        color: _bpmColor,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'bpm',
                      style: GoogleFonts.inter(
                        color: _bpmColor.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _zone,
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Zone indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _bpmColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _zone,
              style: GoogleFonts.inter(
                color: _bpmColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
