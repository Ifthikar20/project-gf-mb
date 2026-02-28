import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';

/// Body Profile setup page
/// Shows a weight slider (kg/lbs toggle) and optional height field
/// Shown before first manual workout if body profile is not set
class BodyProfilePage extends StatefulWidget {
  const BodyProfilePage({super.key});

  @override
  State<BodyProfilePage> createState() => _BodyProfilePageState();
}

class _BodyProfilePageState extends State<BodyProfilePage> {
  double _weightKg = 70.0;
  double? _heightCm;
  bool _useLbs = false;
  bool _isSaving = false;

  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _card = Color(0xFF1A1A1A);

  double get _displayWeight => _useLbs ? _weightKg * 2.205 : _weightKg;
  String get _weightUnit => _useLbs ? 'lbs' : 'kg';
  double get _minWeight => _useLbs ? 66.0 : 30.0;
  double get _maxWeight => _useLbs ? 440.0 : 200.0;

  void _onWeightChanged(double value) {
    setState(() {
      if (_useLbs) {
        _weightKg = value / 2.205;
      } else {
        _weightKg = value;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    context.read<WorkoutBloc>().add(UpdateBodyProfile(
      weightKg: _weightKg,
      heightCm: _heightCm,
    ));

    // Wait a moment for the state to update
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Icon
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _purple.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.monitor_weight_outlined, color: _purple, size: 32),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: Text(
                  'Set Your Weight',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'We need your weight to calculate\nhow many calories you burn.',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 14, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // Weight display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Weight label
                    Text(
                      'Weight',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 8),

                    // Big number
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _displayWeight.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _weightUnit,
                            style: GoogleFonts.inter(color: Colors.white54, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Slider
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: _purple,
                        inactiveTrackColor: _purple.withValues(alpha: 0.15),
                        thumbColor: _purple,
                        overlayColor: _purple.withValues(alpha: 0.15),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _displayWeight.clamp(_minWeight, _maxWeight),
                        min: _minWeight,
                        max: _maxWeight,
                        onChanged: _onWeightChanged,
                      ),
                    ),

                    // Unit toggle
                    GestureDetector(
                      onTap: () => setState(() => _useLbs = !_useLbs),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Switch to ${_useLbs ? 'kg' : 'lbs'}',
                          style: GoogleFonts.inter(color: _purple, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Height (optional)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text(
                      'Height (optional)',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          hintText: '—',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          suffixText: ' cm',
                          suffixStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                        ),
                        onChanged: (v) {
                          _heightCm = double.tryParse(v);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Privacy note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, color: Colors.white24, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Your data is private and only used for calorie calculations.',
                    style: GoogleFonts.inter(color: Colors.white24, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _purple.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Save',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
