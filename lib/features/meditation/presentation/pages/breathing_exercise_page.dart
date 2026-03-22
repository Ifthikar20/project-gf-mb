import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/breathing_patterns.dart';
import 'meditation_journal_page.dart';

/// Guided breathing exercise page with animated expand/contract circle
class BreathingExercisePage extends StatefulWidget {
  final BreathingPattern? initialPattern;

  const BreathingExercisePage({super.key, this.initialPattern});

  @override
  State<BreathingExercisePage> createState() => _BreathingExercisePageState();
}

class _BreathingExercisePageState extends State<BreathingExercisePage>
    with TickerProviderStateMixin {
  late BreathingPattern _pattern;
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  bool _isActive = false;
  int _cyclesCompleted = 0;
  String _phaseLabel = 'Tap to begin';
  Timer? _phaseTimer;
  int _totalSeconds = 0;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _pattern = widget.initialPattern ?? BreathingPatternsData.patterns.first;
    _breathController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _pattern.totalCycleSeconds),
    );
    _buildAnimation();
  }

  void _buildAnimation() {
    final total = _pattern.totalCycleSeconds.toDouble();
    final inhaleEnd = _pattern.inhaleSeconds / total;
    final holdEnd = inhaleEnd + _pattern.holdSeconds / total;
    final exhaleEnd = holdEnd + _pattern.exhaleSeconds / total;

    _breathAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.4, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: inhaleEnd * 100,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: (holdEnd - inhaleEnd) * 100,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.4)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: (exhaleEnd - holdEnd) * 100,
      ),
      if (_pattern.holdAfterExhaleSeconds > 0)
        TweenSequenceItem(
          tween: ConstantTween(0.4),
          weight: (1.0 - exhaleEnd) * 100,
        ),
    ]).animate(_breathController);
  }

  void _startBreathing() {
    setState(() {
      _isActive = true;
      _cyclesCompleted = 0;
      _totalSeconds = 0;
    });

    _breathController.repeat();
    _startPhaseLabeling();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _totalSeconds++);
    });
  }

  void _stopBreathing() {
    _breathController.stop();
    _phaseTimer?.cancel();
    _clockTimer?.cancel();
    setState(() {
      _isActive = false;
      _phaseLabel = 'Session complete';
    });

    // Navigate to journal page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MeditationJournalPage(
          sessionType: 'breathing',
          durationSeconds: _totalSeconds,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _startPhaseLabeling() {
    _runPhase(0);
  }

  void _runPhase(int cyclePhase) {
    if (!_isActive) return;

    String label;
    int seconds;

    switch (cyclePhase) {
      case 0:
        label = 'Breathe in';
        seconds = _pattern.inhaleSeconds;
        break;
      case 1:
        label = 'Hold';
        seconds = _pattern.holdSeconds;
        break;
      case 2:
        label = 'Breathe out';
        seconds = _pattern.exhaleSeconds;
        break;
      case 3:
        label = 'Hold';
        seconds = _pattern.holdAfterExhaleSeconds;
        break;
      default:
        label = '';
        seconds = 0;
    }

    if (seconds == 0) {
      // Skip zero-duration phases
      final nextPhase = (cyclePhase + 1) % 4;
      if (nextPhase == 0) _cyclesCompleted++;
      _runPhase(nextPhase);
      return;
    }

    setState(() => _phaseLabel = label);
    HapticFeedback.lightImpact();

    _phaseTimer = Timer(Duration(seconds: seconds), () {
      final nextPhase = (cyclePhase + 1) % 4;
      if (nextPhase == 0) {
        setState(() => _cyclesCompleted++);
      }
      _runPhase(nextPhase);
    });
  }

  @override
  void dispose() {
    _breathController.dispose();
    _phaseTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: () {
            if (_isActive) _stopBreathing();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          _pattern.name,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Pattern selector (only before starting)
          if (!_isActive) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: BreathingPatternsData.patterns.length,
                itemBuilder: (context, index) {
                  final p = BreathingPatternsData.patterns[index];
                  final isSelected = p.name == _pattern.name;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _pattern = p;
                          _breathController.duration =
                              Duration(seconds: p.totalCycleSeconds);
                          _buildAnimation();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? p.color.withOpacity(0.2)
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isSelected
                                ? p.color
                                : Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          p.name,
                          style: GoogleFonts.inter(
                            color: isSelected ? p.color : Colors.white54,
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _pattern.description,
                style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const Spacer(),

          // Animated breathing circle
          AnimatedBuilder(
            animation: _breathAnimation,
            builder: (context, child) {
              final scale = _isActive ? _breathAnimation.value : 0.4;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _pattern.color.withOpacity(0.6),
                        _pattern.color.withOpacity(0.1),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _pattern.color.withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Phase label
          Text(
            _phaseLabel,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),

          if (_isActive) ...[
            const SizedBox(height: 8),
            Text(
              '${_totalSeconds ~/ 60}:${(_totalSeconds % 60).toString().padLeft(2, '0')} · $_cyclesCompleted cycles',
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 14,
              ),
            ),
          ],

          const Spacer(),

          // Start / Stop button
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isActive ? _stopBreathing : _startBreathing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isActive
                      ? Colors.white.withOpacity(0.1)
                      : _pattern.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                  elevation: 0,
                ),
                child: Text(
                  _isActive ? 'End Session' : 'Begin',
                  style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
