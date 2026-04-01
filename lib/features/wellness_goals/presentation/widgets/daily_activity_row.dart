import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/healthkit_service.dart';
import '../../../diet/presentation/bloc/diet_bloc.dart';
import '../../../diet/presentation/bloc/diet_state.dart';

/// Compact row showing today's steps + calories consumed on the Home page.
class DailyActivityRow extends StatefulWidget {
  const DailyActivityRow({super.key});

  @override
  State<DailyActivityRow> createState() => _DailyActivityRowState();
}

class _DailyActivityRowState extends State<DailyActivityRow> {
  int _steps = 0;
  bool _hasHealthData = false;

  @override
  void initState() {
    super.initState();
    _loadSteps();
  }

  Future<void> _loadSteps() async {
    final hk = HealthKitService.instance;
    if (!hk.isEnabled) return;

    // Try cached first
    var steps = await hk.getCachedSteps();

    // Try live if cached is 0
    if (steps == 0 && hk.isAuthorized) {
      try {
        steps = await hk.getStepCount(days: 1);
      } catch (_) {}
    }

    if (mounted && steps > 0) {
      setState(() {
        _steps = steps;
        _hasHealthData = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final text = isDark ? Colors.white : Colors.black;
    final subtle = isDark ? Colors.white38 : Colors.black38;
    final border = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8EC);

    return Row(
      children: [
        // Steps card
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.directions_walk, color: Color(0xFF3B82F6), size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hasHealthData ? _formatSteps(_steps) : '--',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: text),
                    ),
                    Text('Steps', style: GoogleFonts.inter(fontSize: 11, color: subtle)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Calories consumed card
        Expanded(
          child: BlocBuilder<DietBloc, DietState>(
            builder: (context, state) {
              final cal = state is DietLoaded ? state.summary.totalCalories : 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_fire_department, color: Color(0xFF22C55E), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$cal',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: text),
                        ),
                        Text('Cal eaten', style: GoogleFonts.inter(fontSize: 11, color: subtle)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatSteps(int n) {
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}k';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}
