import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import '../../../../core/services/food_scanner_service.dart';
import '../../../workouts/data/services/workout_service.dart';
import '../../../workouts/presentation/bloc/workout_bloc.dart';
import '../../../workouts/presentation/bloc/workout_event.dart';
import '../../../wellness_goals/data/models/burn_goal_model.dart';
import '../../data/models/food_scan_result.dart';
import '../../data/models/diet_models.dart';
import '../bloc/diet_bloc.dart';
import '../bloc/diet_event.dart';
import 'barcode_scan_page.dart';

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
  bool _showDetail = false;

  @override
  void initState() {
    super.initState();
    // Auto-open camera when scanner loads
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
      // User cancelled camera — stay on scanner screen (don't pop)
    }
  }

  Future<File> _stripExifMetadata(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return imageFile;
    final stripped = img.encodeJpg(decoded, quality: 90);
    await imageFile.writeAsBytes(stripped);
    return imageFile;
  }

  Future<void> _analyzeImage() async {
    if (_capturedImage == null) return;
    setState(() {
      _scanning = true;
      _error = null;
      _result = null;
    });

    try {
      final strippedFile = await _stripExifMetadata(_capturedImage!);
      final bytes = await strippedFile.readAsBytes();
      final result = await FoodScannerService.instance.analyzeImage(bytes);
      
      if (mounted) {
        setState(() => _scanning = false);
        // Navigate to summary page
        final logged = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<DietBloc>(),
              child: _FoodSummaryPage(
                result: result,
                imageFile: _capturedImage!,
                guessMealType: _guessMealType,
                saveImage: _saveImageToDocuments,
              ),
            ),
          ),
        );
        // Whether logged or cancelled, close the scanner and go back to Calories
        if (mounted) Navigator.pop(context);
      }
    } on FoodScanException catch (e) {
      if (!mounted) return;

      if (e.code == 'RATE_LIMITED') {
        setState(() { _scanning = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Too many scans. Please wait a moment.')),
        );
      } else if (e.code == 'INVALID_IMAGE') {
        setState(() { _scanning = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read the image. Try a clearer photo.')),
        );
      } else if (e.code == 'AUTHENTICATION_REQUIRED') {
        setState(() { _scanning = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to use the food scanner.')),
        );
        Navigator.pop(context);
      } else {
        // Show real error — no fake placeholder data
        debugPrint('📸 Food scanner error (${e.code}): ${e.message}');
        setState(() {
          _error = 'Scan unavailable — ${e.message}';
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

  /// Pick an image from the photo gallery for scanning
  Future<void> _pickFromGallery() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
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
    }
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

  /// Save the captured food photo to app documents dir.
  Future<String?> _saveImageToDocuments() async {
    if (_capturedImage == null) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'food_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await _capturedImage!.copy(p.join(dir.path, fileName));
      return savedFile.path;
    } catch (e) {
      debugPrint('📸 Failed to save food image: $e');
      return null;
    }
  }

  void _logMeal() async {
    if (_result == null) return;
    final mealType = _guessMealType();
    final imagePath = await _saveImageToDocuments();
    final scanId = const Uuid().v4();
    final now = DateTime.now();
    final mealName = _result!.mealName; // e.g. "Burger", "Chicken Salad"

    // Build all meals first, then log as single batch (1 reload instead of N)
    final imageUrlFromApi = _result!.imageUrl;
    final wellness = _result!.mealWellness;
    final wellnessBreakdown = wellness != null
        ? jsonEncode({
            'label': wellness.label,
            'per_item': wellness.perItem.map((i) => {'name': i.name, 'score': i.score}).toList(),
            'positive': wellness.positiveFactors.map((f) => {'label': f.label, 'points': f.points, 'reason': f.reason}).toList(),
            'negative': wellness.negativeFactors.map((f) => {'label': f.label, 'points': f.points, 'reason': f.reason}).toList(),
          })
        : null;
    final meals = _result!.items.map((item) => MealLog(
          name: item.name,
          calories: item.calories * _servings,
          proteinGrams: (item.proteinG * _servings).round(),
          carbsGrams: (item.carbsG * _servings).round(),
          fatGrams: (item.fatG * _servings).round(),
          sugarGrams: (item.sugarG * _servings).round(),
          fiberGrams: (item.fiberG * _servings).round(),
          sodiumMg: (item.sodiumMg * _servings),
          caffeineMg: (item.caffeineMg * _servings),
          itemType: item.type,
          warningsJson: item.warnings.isNotEmpty
              ? jsonEncode(item.warnings.map((w) => {
                    'type': w.type,
                    'severity': w.severity,
                    'label': w.label,
                    'detail': w.detail,
                  }).toList())
              : null,
          benefitsJson: item.benefits.isNotEmpty
              ? jsonEncode(item.benefits.map((b) => {
                    'icon': b.icon,
                    'title': b.title,
                    'detail': b.detail,
                  }).toList())
              : null,
          calorieBurnJson: item.calorieBurn.isNotEmpty
              ? jsonEncode(item.calorieBurn.map((c) => {
                    'activity': c.activity,
                    'duration': c.duration,
                    'icon': c.icon,
                    'steps': c.steps,
                    'detail': c.detail,
                  }).toList())
              : null,
          wellnessScore: wellness?.overallScore ?? 0,
          wellnessBreakdownJson: wellnessBreakdown,
          mealType: mealType,
          timestamp: now,
          imagePath: imagePath,
          imageUrl: imageUrlFromApi,
          scanId: scanId,
          mealName: mealName,
          notes:
              'Scanned via AI (${(item.confidence * 100).round()}% confidence)${_servings > 1 ? ' × $_servings servings' : ''}',
        )).toList();

    if (!mounted) return;
    context.read<DietBloc>().add(LogMealBatch(meals: meals));
    if (!mounted) return;
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

  void _switchToBarcode() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<DietBloc>(),
          child: const BarcodeScanPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

          // ── Corner brackets overlay ──
          if (_capturedImage != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CornerBracketsPainter(scanning: _scanning),
                ),
              ),
            ),

          // ── Top bar ──
          _buildTopBar(),

          // ── Scanning indicator ──
          if (_scanning) _buildScanningOverlay(),

          // ── Error state ──
          if (_error != null && !_scanning) _buildErrorOverlay(),

          // ── Retake / Gallery buttons ──
          if (_capturedImage != null && !_scanning && _error == null)
            _buildRetakeBar(),
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
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
            Text(
              'Scan Food',
              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            // Barcode button
            GestureDetector(
              onTap: _switchToBarcode,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Retake / Gallery bar (after capture, before results) ───
  Widget _buildRetakeBar() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 24,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _retakePhoto,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text('Retake', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _pickFromGallery,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_library_outlined, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text('Gallery', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Scanning overlay — food image visible behind with animated scan line ───
  Widget _buildScanningOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: const Stack(
          children: [
            // Animated scan line
            _ScanLineAnimation(),
            // Corner brackets during scan
            Positioned.fill(
              child: IgnorePointer(
                child: _AnimatedCornerBrackets(),
              ),
            ),
            // Text at bottom center
            Positioned(
              bottom: 140,
              left: 0,
              right: 0,
              child: Center(child: _ScanningTextAnimation()),
            ),
          ],
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

  // (Retake is now handled by the bottom toolbar scan button)

  // ─── Results Panel — draggable sheet so image stays visible ───
  Widget _buildResultsPanel() {
    if (_result == null) return const SizedBox.shrink();
    final item = _result!.items.first;
    final mealLabel = _mealTypeLabel(_guessMealType());

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4))],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 36, height: 4,
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
                ),
              ),
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

            // ── Liquid/Beverage badge ──
            if (item.isLiquidOrBeverage)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: item.isBeverage
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: item.isBeverage
                          ? const Color(0xFFBFDBFE)
                          : const Color(0xFFBBF7D0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.isBeverage
                            ? Icons.local_cafe_rounded
                            : Icons.water_drop_rounded,
                        size: 15,
                        color: item.isBeverage
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF22C55E),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        item.isBeverage ? 'Beverage' : 'Liquid',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: item.isBeverage
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFF22C55E),
                        ),
                      ),
                      if (item.volumeDisplay != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          item.volumeDisplay!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

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

            // ── Warning badges ──
            if (item.hasWarnings) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: item.warnings.map((w) => _warningChip(w)).toList(),
              ),
            ],

            // ── Detail toggle ──
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => setState(() => _showDetail = !_showDetail),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _showDetail ? Icons.expand_less : Icons.expand_more,
                      color: Colors.black54,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showDetail ? 'Hide Details' : 'See Details',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expanded detail view ──
            if (_showDetail) ...[
              const SizedBox(height: 14),
              _buildDetailBreakdown(item),
            ],

            // ── Burn It Off (workout suggestions) ──
            if (item.hasCalorieBurn) ...[
              const SizedBox(height: 16),
              Text('Burn It Off', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black)),
              const SizedBox(height: 8),
              ...item.calorieBurn.map((burn) => _burnCard(burn)),
            ],

            const SizedBox(height: 16),

            // Done button
            GestureDetector(
              onTap: _logMeal,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Log Meal',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ),
            ],
          ),
        );
      },
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

  // ─── Warning Chip ───
  Widget _warningChip(FoodWarning w) {
    Color bg, fg;
    if (w.isHigh) {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
    } else if (w.isMedium) {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
    } else {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF64748B);
    }

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(w.detail, style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: fg,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_warningIcon(w.type), size: 12, color: fg),
            const SizedBox(width: 4),
            Text(
              w.label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _warningIcon(String type) {
    switch (type) {
      case 'allergen':
        return Icons.warning_amber_rounded;
      case 'high_caffeine':
        return Icons.bolt_rounded;
      case 'high_sugar':
        return Icons.cake_rounded;
      case 'high_sodium':
        return Icons.water_drop_outlined;
      case 'high_sat_fat':
        return Icons.opacity_rounded;
      case 'high_calorie':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  // ─── Detail Breakdown Card ───
  Widget _buildDetailBreakdown(DetectedFoodItem item) {
    final multiplier = _servings;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutrition Breakdown',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _progressRow('Protein', '${(item.proteinG * multiplier).round()}g',
              item.proteinG / 50, const Color(0xFF3B82F6)),
          _progressRow('Carbs', '${(item.carbsG * multiplier).round()}g',
              item.carbsG / 100, const Color(0xFFF59E0B)),
          _progressRow('Fat', '${(item.fatG * multiplier).round()}g',
              item.fatG / 65, const Color(0xFFEC4899)),
          _progressRow('Sugar', '${(item.sugarG * multiplier).round()}g',
              item.sugarG / 50, const Color(0xFFF97316)),
          _progressRow('Fiber', '${(item.fiberG * multiplier).round()}g',
              item.fiberG / 30, const Color(0xFF22C55E)),
          const SizedBox(height: 4),
          // Sodium
          _infoRow('Sodium', '${(item.sodiumMg * multiplier)}mg'),
          // Caffeine (only if > 0)
          if (item.hasCaffeine)
            _infoRow('Caffeine', '${(item.caffeineMg * multiplier)}mg'),
          // Warning details
          if (item.hasWarnings) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 10),
            ...item.warnings.map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_warningIcon(w.type),
                          size: 14,
                          color: w.isHigh
                              ? const Color(0xFFDC2626)
                              : w.isMedium
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          w.detail,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.black54,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _progressRow(String label, String value, double ratio, Color color) {
    final clampedRatio = ratio.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                )),
          ),
          SizedBox(
            width: 44,
            child: Text(value,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                )),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: clampedRatio,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _burnCard(CalorieBurn burn) {
    IconData icon;
    switch (burn.icon) {
      case 'walking': icon = Icons.directions_walk; break;
      case 'running': icon = Icons.directions_run; break;
      case 'cycling': icon = Icons.directions_bike; break;
      case 'swimming': icon = Icons.pool; break;
      default: icon = Icons.fitness_center;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(burn.activity, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                Text(burn.duration, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              // Add to workout goals
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${burn.activity} (${burn.duration}) added to your goals'),
                  backgroundColor: const Color(0xFF22C55E),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Add', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                )),
          ),
          Text(value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Food Summary Page — clean full-page result
// ─────────────────────────────────────────────
class _FoodSummaryPage extends StatefulWidget {
  final FoodScanResult result;
  final File imageFile;
  final MealType Function() guessMealType;
  final Future<String?> Function() saveImage;

  const _FoodSummaryPage({
    required this.result,
    required this.imageFile,
    required this.guessMealType,
    required this.saveImage,
  });

  @override
  State<_FoodSummaryPage> createState() => _FoodSummaryPageState();
}

class _FoodSummaryPageState extends State<_FoodSummaryPage> {
  int _servings = 1;

  void _logMeal() async {
    final mealType = widget.guessMealType();
    final imagePath = await widget.saveImage();
    final scanId = const Uuid().v4();
    final now = DateTime.now();
    final r = widget.result;
    final wellness = r.mealWellness;
    final wellnessBreakdown = wellness != null
        ? jsonEncode({
            'label': wellness.label,
            'per_item': wellness.perItem.map((i) => {'name': i.name, 'score': i.score}).toList(),
            'positive': wellness.positiveFactors.map((f) => {'label': f.label, 'points': f.points, 'reason': f.reason}).toList(),
            'negative': wellness.negativeFactors.map((f) => {'label': f.label, 'points': f.points, 'reason': f.reason}).toList(),
          })
        : null;

    final meals = r.items.map((item) => MealLog(
          name: item.name,
          calories: item.calories * _servings,
          proteinGrams: (item.proteinG * _servings).round(),
          carbsGrams: (item.carbsG * _servings).round(),
          fatGrams: (item.fatG * _servings).round(),
          sugarGrams: (item.sugarG * _servings).round(),
          fiberGrams: (item.fiberG * _servings).round(),
          sodiumMg: (item.sodiumMg * _servings),
          caffeineMg: (item.caffeineMg * _servings),
          itemType: item.type,
          warningsJson: item.warnings.isNotEmpty ? jsonEncode(item.warnings.map((w) => {'type': w.type, 'severity': w.severity, 'label': w.label, 'detail': w.detail}).toList()) : null,
          benefitsJson: item.benefits.isNotEmpty ? jsonEncode(item.benefits.map((b) => {'icon': b.icon, 'title': b.title, 'detail': b.detail}).toList()) : null,
          calorieBurnJson: item.calorieBurn.isNotEmpty ? jsonEncode(item.calorieBurn.map((c) => {'activity': c.activity, 'duration': c.duration, 'icon': c.icon, 'steps': c.steps, 'detail': c.detail}).toList()) : null,
          wellnessScore: wellness?.overallScore ?? 0,
          wellnessBreakdownJson: wellnessBreakdown,
          mealType: mealType,
          timestamp: now,
          imagePath: imagePath,
          imageUrl: r.imageUrl,
          scanId: scanId,
          mealName: r.mealName,
          notes: 'Scanned via AI (${(item.confidence * 100).round()}% confidence)${_servings > 1 ? ' × $_servings servings' : ''}',
        )).toList();

    if (!mounted) return;
    context.read<DietBloc>().add(LogMealBatch(meals: meals));
    HapticFeedback.mediumImpact();
    Navigator.pop(context, true); // Return true = logged
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.result.items.first;
    final totalCal = widget.result.totalCalories * _servings;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Food image (top 40%) ──
          SliverToBoxAdapter(
            child: Stack(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.38,
                  width: double.infinity,
                  child: Image.file(widget.imageFile, fit: BoxFit.cover),
                ),
                // Gradient fade to white
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  height: 80,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.white],
                      ),
                    ),
                  ),
                ),
                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food name + servings
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.result.mealName ?? item.name,
                              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.result.items.length} item${widget.result.items.length > 1 ? 's' : ''} detected',
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.black45),
                            ),
                          ],
                        ),
                      ),
                      // Serving control
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            _sBtn(Icons.remove, () { if (_servings > 1) setState(() => _servings--); }),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text('$_servings', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                            ),
                            _sBtn(Icons.add, () => setState(() => _servings++)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Big calorie number ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text('$totalCal', style: GoogleFonts.inter(fontSize: 44, fontWeight: FontWeight.w800, color: const Color(0xFFEF4444))),
                        Text('calories', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFEF4444).withValues(alpha: 0.7))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Macros row ──
                  Row(
                    children: [
                      _macro('Protein', '${(item.proteinG * _servings).round()}g', const Color(0xFF3B82F6)),
                      const SizedBox(width: 8),
                      _macro('Carbs', '${(item.carbsG * _servings).round()}g', const Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      _macro('Fat', '${(item.fatG * _servings).round()}g', const Color(0xFFEC4899)),
                    ],
                  ),

                  // ── Burn It Off ──
                  if (item.hasCalorieBurn) ...[
                    const SizedBox(height: 24),
                    Text('Burn It Off', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
                    const SizedBox(height: 4),
                    Text('Add a workout to your goals', style: GoogleFonts.inter(fontSize: 12, color: Colors.black45)),
                    const SizedBox(height: 10),
                    ...item.calorieBurn.map((burn) {
                      IconData icon;
                      switch (burn.icon) {
                        case 'walking': icon = Icons.directions_walk; break;
                        case 'running': icon = Icons.directions_run; break;
                        case 'cycling': icon = Icons.directions_bike; break;
                        case 'swimming': icon = Icons.pool; break;
                        default: icon = Icons.fitness_center;
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: const Color(0xFF8B5CF6), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(burn.activity, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
                                  Text(burn.duration, style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
                                  if (burn.steps != null)
                                    Text('~${burn.steps} steps', style: GoogleFonts.inter(fontSize: 11, color: Colors.black38)),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                try {
                                  final minMatch = RegExp(r'(\d+)').firstMatch(burn.duration);
                                  final minutes = minMatch != null ? int.parse(minMatch.group(1)!) : 30;
                                  final totalCal = widget.result.totalCalories * _servings;
                                  final mealName = widget.result.mealName ?? widget.result.items.first.name;

                                  // Create local burn goal (stacks, doesn't replace)
                                  final burnGoal = BurnGoal(
                                    id: 'burn_${DateTime.now().millisecondsSinceEpoch}',
                                    activity: burn.activity,
                                    icon: burn.icon,
                                    targetCalories: totalCal,
                                    targetMinutes: minutes,
                                    targetSteps: burn.steps,
                                    mealName: mealName,
                                    mealCalories: totalCal,
                                    createdAt: DateTime.now(),
                                  );
                                  await BurnGoalStorage.instance.addGoal(burnGoal);

                                  // Also save to backend weekly goal (best effort)
                                  try {
                                    await WorkoutService.instance.setGoal(goalType: 'active_minutes', targetValue: minutes);
                                    if (context.mounted) context.read<WorkoutBloc>().add(const RefreshWorkoutData());
                                  } catch (_) {}

                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('${burn.activity} (${burn.duration}) to burn off $mealName — added to goals'),
                                    backgroundColor: const Color(0xFF22C55E),
                                    duration: const Duration(seconds: 3),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ));
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Could not add goal: $e'),
                                    backgroundColor: const Color(0xFFEF4444),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ));
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(10)),
                                child: Text('Add', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  // ── Warnings ──
                  if (item.hasWarnings) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: item.warnings.map((w) {
                        final isHigh = w.severity == 'high';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isHigh ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(w.label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isHigh ? const Color(0xFFDC2626) : const Color(0xFFD97706))),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Log Meal button ──
                  GestureDetector(
                    onTap: _logMeal,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text('Log $totalCal cal', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(7), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Icon(icon, size: 14, color: Colors.black87),
      ),
    );
  }

  Widget _macro(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: color.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Corner Brackets Overlay — sharp, modern
// ─────────────────────────────────────────────
class _CornerBracketsPainter extends CustomPainter {
  final bool scanning;
  final double glowOpacity;
  _CornerBracketsPainter({this.scanning = false, this.glowOpacity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final rectSize = size.width * 0.72;
    final bracketLen = 35.0;
    final cornerRadius = 14.0;

    // Bracket rectangle (not circle — matches reference UI)
    final rect = Rect.fromCenter(center: center, width: rectSize, height: rectSize);

    // White bracket corners (with glow when scanning)
    final bracketColor = scanning
        ? Color.fromRGBO(139, 92, 246, glowOpacity) // Purple glow
        : Colors.white.withOpacity(0.8);

    final bracketPaint = Paint()
      ..color = bracketColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

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
      scanning != old.scanning || glowOpacity != old.glowOpacity;
}

// ─────────────────────────────────────────────
// Animated scanning text ─ cycles through messages
// ─────────────────────────────────────────────
/// Animated scanning line that sweeps vertically over the food image
class _ScanLineAnimation extends StatefulWidget {
  const _ScanLineAnimation();

  @override
  State<_ScanLineAnimation> createState() => _ScanLineAnimationState();
}

class _ScanLineAnimationState extends State<_ScanLineAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final screenH = MediaQuery.of(context).size.height;
        final top = _controller.value * screenH * 0.6 + screenH * 0.15;
        return Positioned(
          top: top,
          left: 40,
          right: 40,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF8B5CF6).withOpacity(0.8),
                  const Color(0xFF6366F1),
                  const Color(0xFF8B5CF6).withOpacity(0.8),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Animated corner brackets that pulse during scanning
class _AnimatedCornerBrackets extends StatefulWidget {
  const _AnimatedCornerBrackets();

  @override
  State<_AnimatedCornerBrackets> createState() => _AnimatedCornerBracketsState();
}

class _AnimatedCornerBracketsState extends State<_AnimatedCornerBrackets>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.4 + _controller.value * 0.6;
        return CustomPaint(
          painter: _CornerBracketsPainter(
            scanning: true,
            glowOpacity: opacity,
          ),
        );
      },
    );
  }
}

/// Scanning text with cycling messages
class _ScanningTextAnimation extends StatefulWidget {
  const _ScanningTextAnimation();

  @override
  State<_ScanningTextAnimation> createState() => _ScanningTextAnimationState();
}

class _ScanningTextAnimationState extends State<_ScanningTextAnimation> {
  static const _messages = [
    'Breaking down the image...',
    'Finding calories & macros...',
    'Identifying ingredients...',
    'Analyzing portion size...',
    'Almost there...',
  ];

  int _index = 0;
  int _dotCount = 0;
  late final _messageTimer = Stream.periodic(
    const Duration(seconds: 3),
    (i) => i,
  ).listen((_) {
    if (mounted) setState(() => _index = (_index + 1) % _messages.length);
  });
  late final _dotTimer = Stream.periodic(
    const Duration(milliseconds: 500),
    (i) => i,
  ).listen((_) {
    if (mounted) setState(() => _dotCount = (_dotCount + 1) % 4);
  });

  @override
  void dispose() {
    _messageTimer.cancel();
    _dotTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            onEnd: () {
              if (mounted) setState(() {});
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withOpacity(0.2),
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                color: Color(0xFF8B5CF6),
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Main message
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              _messages[_index],
              key: ValueKey(_index),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Subtitle with dots
          Text(
            'Scanning${'.' * _dotCount}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
