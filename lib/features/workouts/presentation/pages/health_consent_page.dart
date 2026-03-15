import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/healthkit_service.dart';

/// Pre-permission consent screen shown before the native HealthKit dialog.
/// Explains what data we read and why, with a "Connect" button.
class HealthConsentPage extends StatefulWidget {
  const HealthConsentPage({super.key});

  @override
  State<HealthConsentPage> createState() => _HealthConsentPageState();
}

class _HealthConsentPageState extends State<HealthConsentPage> {
  bool _isConnecting = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.white54 : Colors.black54;
    final bgColor = isDark ? const Color(0xFF0A0A0A) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 1),
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF06B6D4)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 28),
              // Title
              Text(
                'Connect Apple Health',
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'See your real fitness data in the app — heart rate, workouts, steps, and calories from your Apple Watch.',
                style: GoogleFonts.inter(
                  color: textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              // Data points we read
              _buildDataRow(
                icon: Icons.monitor_heart_rounded,
                title: 'Heart Rate',
                subtitle: 'See your BPM trends over time',
                color: const Color(0xFFEF4444),
                isDark: isDark,
              ),
              _buildDataRow(
                icon: Icons.fitness_center_rounded,
                title: 'Workouts',
                subtitle: 'Track duration and calories burned',
                color: const Color(0xFF22C55E),
                isDark: isDark,
              ),
              _buildDataRow(
                icon: Icons.directions_walk_rounded,
                title: 'Steps & Activity',
                subtitle: 'Daily movement and energy',
                color: const Color(0xFF3B82F6),
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              // Privacy note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_rounded,
                        color: const Color(0xFF22C55E), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your health data stays on your device. We never upload or share it.',
                        style: GoogleFonts.inter(
                          color: textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              // Connect button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isConnecting ? null : _onConnect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isConnecting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Connect Apple Health',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              // Skip button
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Skip for now',
                  style: GoogleFonts.inter(
                    color: textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded,
              color: const Color(0xFF22C55E), size: 20),
        ],
      ),
    );
  }

  Future<void> _onConnect() async {
    setState(() => _isConnecting = true);

    final granted = await HealthKitService.instance.requestPermissions();

    if (mounted) {
      setState(() => _isConnecting = false);
      Navigator.of(context).pop(granted);
    }
  }
}
