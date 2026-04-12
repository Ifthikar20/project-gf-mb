import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/healthkit_service.dart';
import 'calm_down_sheet.dart';

/// Live heart rate monitor card.
/// Uses real HealthKit data when available, falls back to simulation.
class HeartRateMonitorCard extends StatefulWidget {
  const HeartRateMonitorCard({super.key});

  @override
  State<HeartRateMonitorCard> createState() => _HeartRateMonitorCardState();
}

class _HeartRateMonitorCardState extends State<HeartRateMonitorCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _refreshTimer;
  int _currentBPM = 0;
  bool _calmDownShown = false;
  bool _isRealData = false;
  final _random = Random();

  static const _hrThreshold = 150;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _loadHeartRate();

    // Refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadHeartRate();
    });
  }

  Future<void> _loadHeartRate() async {
    final service = HealthKitService.instance;

    if (service.isEnabled && service.isAuthorized) {
      // Try real data from cache
      final bpm = await service.getLatestHeartRate();
      if (bpm > 0 && mounted) {
        setState(() {
          _currentBPM = bpm;
          _isRealData = true;
        });
        _checkThreshold();
        return;
      }
    }

    // Fallback to simulation
    if (mounted && !_isRealData) {
      setState(() {
        if (_currentBPM == 0) _currentBPM = 72;
        _currentBPM = (_currentBPM + _random.nextInt(31) - 15).clamp(55, 180);
        _isRealData = false;
      });
    }
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
    _refreshTimer?.cancel();
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
                      _currentBPM > 0 ? '$_currentBPM' : '--',
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
                Row(
                  children: [
                    Text(
                      _zone,
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    if (_isRealData) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Live',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF22C55E),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
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
