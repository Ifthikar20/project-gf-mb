import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Dismissible water reminder card for the home screen.
/// Persists "done" state in Hive so it resets daily.
class WaterReminderCard extends StatefulWidget {
  const WaterReminderCard({super.key});

  @override
  State<WaterReminderCard> createState() => _WaterReminderCardState();
}

class _WaterReminderCardState extends State<WaterReminderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;
  Box? _box;
  bool _dismissed = false;
  bool _loading = true;

  static const _boxName = 'water_reminder';

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _openBox();
  }

  Future<void> _openBox() async {
    _box = await Hive.openBox(_boxName);
    if (mounted) {
      setState(() {
        _dismissed = _box?.get(_todayKey, defaultValue: false) == true;
        _loading = false;
      });
    }
  }

  Future<void> _markDone() async {
    await _box?.put(_todayKey, true);
    if (mounted) setState(() => _dismissed = true);
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _dismissed) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF0D47A1),
                        const Color(0xFF1565C0),
                        const Color(0xFF0097A7),
                      ]
                    : [
                        const Color(0xFF42A5F5),
                        const Color(0xFF1E88E5),
                        const Color(0xFF0097A7),
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Water icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(Icons.water_drop_rounded, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stay Hydrated!',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Time to drink a glass of water',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Done button
              GestureDetector(
                onTap: _markDone,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1565C0),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

