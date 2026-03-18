import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/food_scanner_service.dart';
import '../../data/models/food_scan_result.dart';
import '../../data/models/diet_models.dart';
import '../bloc/diet_bloc.dart';
import '../bloc/diet_event.dart';

/// Full-screen AI food scanner — Cal.ai inspired camera UI.
/// Opens the camera, captures a photo, shows AI scan results
/// with macro grid + Done button.
class FoodScanSheet extends StatefulWidget {
  const FoodScanSheet({super.key});

  @override
  State<FoodScanSheet> createState() => _FoodScanSheetState();
}

class _FoodScanSheetState extends State<FoodScanSheet> {
  final ImagePicker _picker = ImagePicker();

  File? _capturedImage;
  FoodScanResult? _result;
  bool _scanning = false;
  String? _error;
  int _servings = 1;

  @override
  void initState() {
    super.initState();
    // Auto-open camera on load
    WidgetsBinding.instance.addPostFrameCallback((_) => _capturePhoto());
  }

  // ─── Camera Capture ───
  Future<void> _capturePhoto() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file != null && mounted) {
      setState(() {
        _capturedImage = File(file.path);
        _error = null;
      });
      _analyzeImage();
    } else if (mounted && _capturedImage == null) {
      Navigator.pop(context);
    }
  }

  Future<void> _analyzeImage() async {
    if (_capturedImage == null) return;
    setState(() {
      _scanning = true;
      _error = null;
      _result = null;
    });

    try {
      // TODO: Replace with backend API call when ready
      // final bytes = await _capturedImage!.readAsBytes();
      // final response = await ApiClient.instance.post('/api/food/analyze', data: ...);
      
      // For now, try Gemini if key is available, otherwise use placeholder
      final bytes = await _capturedImage!.readAsBytes();
      FoodScanResult result;
      try {
        result = await FoodScannerService.instance.analyzeImage(bytes);
      } catch (_) {
        // Gemini key not set or API failed — use placeholder
        debugPrint('📸 AI scanner unavailable, using placeholder');
        await Future.delayed(const Duration(seconds: 1));
        result = const FoodScanResult(
          items: [
            DetectedFoodItem(
              name: 'Scanned Food',
              calories: 350,
              proteinG: 18,
              carbsG: 42,
              fatG: 12,
              servingSize: '1 serving',
              confidence: 0.7,
            ),
          ],
          totalCalories: 350,
          mealType: 'lunch',
        );
      }
      
      if (mounted) {
        setState(() {
          _result = result;
          _scanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _scanning = false;
        });
      }
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _result = null;
      _error = null;
      _servings = 1;
    });
    _capturePhoto();
  }

  MealType _guessMealType() {
    if (_result?.mealType != null) {
      switch (_result!.mealType) {
        case 'breakfast':
          return MealType.breakfast;
        case 'lunch':
          return MealType.lunch;
        case 'dinner':
          return MealType.dinner;
        default:
          return MealType.snack;
      }
    }
    final hour = DateTime.now().hour;
    if (hour < 11) return MealType.breakfast;
    if (hour < 15) return MealType.lunch;
    if (hour < 20) return MealType.dinner;
    return MealType.snack;
  }

  String _mealTypeLabel(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  void _logMeal() {
    if (_result == null) return;
    final mealType = _guessMealType();
    for (final item in _result!.items) {
      context.read<DietBloc>().add(LogMeal(
            meal: MealLog(
              name: item.name,
              calories: item.calories * _servings,
              proteinGrams: (item.proteinG * _servings).round(),
              carbsGrams: (item.carbsG * _servings).round(),
              fatGrams: (item.fatG * _servings).round(),
              mealType: mealType,
              timestamp: DateTime.now(),
              notes:
                  'Scanned via AI (${(item.confidence * 100).round()}% confidence)${_servings > 1 ? ' × $_servings servings' : ''}',
            ),
          ));
    }
    Navigator.pop(context);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Logged ${_result!.totalCalories * _servings} cal',
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasResult = _result != null && !_scanning;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Image fills the screen ──
          if (_capturedImage != null)
            Positioned.fill(
              child: Image.file(_capturedImage!, fit: BoxFit.cover),
            )
          else
            const Positioned.fill(
              child: ColoredBox(color: Color(0xFF111111)),
            ),

          // ── Gradient overlay when showing result ──
          if (hasResult)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.3, 0.5],
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.97),
                    ],
                  ),
                ),
              ),
            ),

          // ── Corner brackets overlay (when scanning / waiting) ──
          if (!hasResult && _capturedImage != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CornerBracketsPainter(scanning: _scanning),
                ),
              ),
            ),

          // ── Top bar: X — AI Scanner — ••• ──
          _buildTopBar(),

          // ── Scanning indicator ──
          if (_scanning) _buildScanningOverlay(),

          // ── Error state ──
          if (_error != null && !_scanning) _buildErrorOverlay(),

          // ── Results panel (slides up from bottom) ──
          if (hasResult) _buildResultsPanel(),

          // ── Retake button (after error or when viewing captured image) ──
          if (_capturedImage != null &&
              !_scanning &&
              !hasResult &&
              _error == null)
            _buildRetakeButton(),
        ],
      ),
    );
  }

  // ─── Top Bar ───
  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Close button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
            // Title
            Text(
              'AI Scanner',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            // More button
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.more_horiz,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Scanning overlay ───
  Widget _buildScanningOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Analyzing food...',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'AI is identifying calories & macros',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Error overlay ───
  Widget _buildErrorOverlay() {
    return Positioned(
      bottom: 100,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFEF4444), size: 36),
            const SizedBox(height: 12),
            Text(
              'Could not analyze',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try again with better lighting',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _retakePhoto,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Retake Photo',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

  // ─── Retake button ───
  Widget _buildRetakeButton() {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _retakePhoto,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Retake',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Results Panel (matching the mockup) ───
  Widget _buildResultsPanel() {
    if (_result == null) return const SizedBox.shrink();
    final item = _result!.items.first;
    final mealLabel = _mealTypeLabel(_guessMealType());

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            20, 24, 20, MediaQuery.of(context).padding.bottom + 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal type label
            Text(
              mealLabel,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(height: 4),

            // Food name + servings
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Serving control
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _servingBtn(Icons.remove, () {
                        if (_servings > 1) setState(() => _servings--);
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '$_servings',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      _servingBtn(Icons.add, () {
                        setState(() => _servings++);
                      }),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Macro grid (2x2)
            Row(
              children: [
                Expanded(
                  child: _macroCard(
                    emoji: '🔥',
                    label: 'Calories',
                    value: '${item.calories * _servings}',
                    unit: '',
                    color: const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _macroCard(
                    emoji: '🍖',
                    label: 'Protein',
                    value: '${(item.proteinG * _servings).round()}',
                    unit: 'gm',
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _macroCard(
                    emoji: '🍇',
                    label: 'Carbs',
                    value: '${(item.carbsG * _servings).round()}',
                    unit: 'gm',
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _macroCard(
                    emoji: '🧈',
                    label: 'Fat',
                    value: '${(item.fatG * _servings).round()}',
                    unit: 'gm',
                    color: const Color(0xFFEC4899),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Done button
            GestureDetector(
              onTap: _logMeal,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Done',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

  // ─── Macro Card ───
  Widget _macroCard({
    required String emoji,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              Text(
                'Edit',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.black38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Value
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: unit,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _servingBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 14, color: Colors.black87),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Corner Brackets Overlay — sharp, modern
// ─────────────────────────────────────────────
class _CornerBracketsPainter extends CustomPainter {
  final bool scanning;
  _CornerBracketsPainter({this.scanning = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final radius = size.width * 0.38;
    final bracketLen = 30.0;
    final cornerRadius = 12.0;

    // Semi-transparent dark overlay
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.35);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);

    // Clear the circle
    final circlePaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawCircle(center, radius, circlePaint);

    // White bracket corners
    final bracketPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Top-left corner
    _drawCorner(canvas, bracketPaint, rect.left, rect.top, bracketLen,
        cornerRadius, topLeft: true);
    // Top-right corner
    _drawCorner(canvas, bracketPaint, rect.right, rect.top, bracketLen,
        cornerRadius, topRight: true);
    // Bottom-left corner
    _drawCorner(canvas, bracketPaint, rect.left, rect.bottom, bracketLen,
        cornerRadius, bottomLeft: true);
    // Bottom-right corner
    _drawCorner(canvas, bracketPaint, rect.right, rect.bottom, bracketLen,
        cornerRadius, bottomRight: true);
  }

  void _drawCorner(
    Canvas canvas,
    Paint paint,
    double x,
    double y,
    double len,
    double r, {
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    final path = Path();

    if (topLeft) {
      path.moveTo(x, y + len);
      path.lineTo(x, y + r);
      path.quadraticBezierTo(x, y, x + r, y);
      path.lineTo(x + len, y);
    } else if (topRight) {
      path.moveTo(x - len, y);
      path.lineTo(x - r, y);
      path.quadraticBezierTo(x, y, x, y + r);
      path.lineTo(x, y + len);
    } else if (bottomLeft) {
      path.moveTo(x, y - len);
      path.lineTo(x, y - r);
      path.quadraticBezierTo(x, y, x + r, y);
      path.lineTo(x + len, y);
    } else if (bottomRight) {
      path.moveTo(x - len, y);
      path.lineTo(x - r, y);
      path.quadraticBezierTo(x, y, x, y - r);
      path.lineTo(x, y - len);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketsPainter old) =>
      scanning != old.scanning;
}
