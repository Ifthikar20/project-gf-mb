import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom sheet with breathing animation and nature sound selector.
/// Triggered when heart rate exceeds threshold.
class CalmDownSheet extends StatefulWidget {
  const CalmDownSheet({super.key});

  @override
  State<CalmDownSheet> createState() => _CalmDownSheetState();
}

class _CalmDownSheetState extends State<CalmDownSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  String _selectedSound = 'Ocean Waves';

  static const _sounds = [
    _NatureSound(Icons.waves_rounded, 'Ocean Waves'),
    _NatureSound(Icons.water_drop_outlined, 'Rain'),
    _NatureSound(Icons.forest_rounded, 'Forest'),
    _NatureSound(Icons.flutter_dash_rounded, 'Birds'),
  ];

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0D1B2A),
            Color(0xFF0A2A3C),
            Color(0xFF0E3D4A),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            // Message
            Text(
              'Take a moment',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your heart rate is elevated.\nLet\'s breathe and reset.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white60,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 36),
            // Breathing circle
            AnimatedBuilder(
              animation: _breathController,
              builder: (context, child) {
                final scale = 0.6 + 0.4 * _breathController.value;
                final opacity = 0.3 + 0.5 * _breathController.value;
                final isInhale = _breathController.status == AnimationStatus.forward;
                return Column(
                  children: [
                    Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF38BDF8).withOpacity(opacity),
                              const Color(0xFF0EA5E9).withOpacity(opacity * 0.3),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withOpacity(0.2),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isInhale ? 'Breathe in...' : 'Breathe out...',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            // Nature sound selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SOOTHING SOUNDS',
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: _sounds.map((s) {
                      final selected = _selectedSound == s.name;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedSound = s.name),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white.withOpacity(0.12)
                                  : Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF38BDF8).withOpacity(0.5)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(s.icon,
                                    color: selected
                                        ? const Color(0xFF38BDF8)
                                        : Colors.white54,
                                    size: 24),
                                const SizedBox(height: 6),
                                Text(
                                  s.name.split(' ').first,
                                  style: GoogleFonts.inter(
                                    color: selected
                                        ? Colors.white
                                        : Colors.white54,
                                    fontSize: 11,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // I'm Good button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                  ),
                  child: Text(
                    'I\'m Good',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NatureSound {
  final IconData icon;
  final String name;
  const _NatureSound(this.icon, this.name);
}
