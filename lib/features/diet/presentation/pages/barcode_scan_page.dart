import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/barcode_lookup_service.dart';
import '../../data/models/food_scan_result.dart';
import '../../data/models/diet_models.dart';
import '../bloc/diet_bloc.dart';
import '../bloc/diet_event.dart';

/// Full-screen barcode scanner page.
/// Shows live camera with barcode scan overlay box,
/// then looks up product nutrition via OpenFoodFacts.
class BarcodeScanPage extends StatefulWidget {
  const BarcodeScanPage({super.key});

  @override
  State<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _scanned = false;
  bool _loading = false;
  FoodScanResult? _result;
  String? _scannedBarcode;
  String? _error;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_scanned || _loading) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final barcode = barcodes.first.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    setState(() {
      _scanned = true;
      _loading = true;
      _scannedBarcode = barcode;
      _error = null;
    });

    // Pause scanning
    _scannerController.stop();

    // Look up product
    final result = await BarcodeLookupService.instance.lookupBarcode(barcode);

    if (mounted) {
      setState(() {
        _loading = false;
        if (result != null && result.totalCalories > 0) {
          _result = result;
        } else {
          _error = 'Product not found. Try scanning again.';
        }
      });
    }
  }

  void _resetScan() {
    setState(() {
      _scanned = false;
      _loading = false;
      _result = null;
      _error = null;
      _scannedBarcode = null;
    });
    _scannerController.start();
  }

  void _logProduct() {
    if (_result == null) return;
    final item = _result!.items.first;
    final hour = DateTime.now().hour;
    MealType mealType;
    if (hour < 11) {
      mealType = MealType.breakfast;
    } else if (hour < 15) {
      mealType = MealType.lunch;
    } else if (hour < 20) {
      mealType = MealType.dinner;
    } else {
      mealType = MealType.snack;
    }

    context.read<DietBloc>().add(LogMeal(
          meal: MealLog(
            name: item.name,
            calories: item.calories,
            proteinGrams: item.proteinG.round(),
            carbsGrams: item.carbsG.round(),
            fatGrams: item.fatG.round(),
            mealType: mealType,
            timestamp: DateTime.now(),
            notes: 'Scanned barcode: $_scannedBarcode',
          ),
        ));

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Logged ${item.name} — ${item.calories} cal',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final isLight = themeState.isLight;
        final bgColor = isLight ? Colors.white : const Color(0xFF111111);
        final surfaceColor =
            isLight ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A1A);
        final textColor =
            isLight ? ThemeColors.lightTextPrimary : ThemeColors.darkTextPrimary;
        final textSecondary = isLight
            ? ThemeColors.lightTextSecondary
            : ThemeColors.darkTextSecondary;
        final borderColor =
            isLight ? ThemeColors.lightBorder : ThemeColors.darkBorder;

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              // Camera view
              if (!_scanned)
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onBarcodeDetected,
                ),

              // Dark overlay with cutout
              if (!_scanned)
                _buildScanOverlay(),

              // Top bar
              _buildTopBar(bgColor, textColor),

              // Results panel at bottom
              if (_loading || _result != null || _error != null)
                _buildResultsPanel(
                  bgColor: bgColor,
                  surfaceColor: surfaceColor,
                  textColor: textColor,
                  textSecondary: textSecondary,
                  borderColor: borderColor,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScanOverlay() {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ScanOverlayPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildTopBar(Color bgColor, Color textColor) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            16, MediaQuery.of(context).padding.top + 8, 16, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Barcode Scan',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            if (_scanned && _result == null && _error != null)
              GestureDetector(
                onTap: _resetScan,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Scan Again',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsPanel({
    required Color bgColor,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).padding.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            if (_loading)
              _buildLoadingState(textColor, textSecondary),

            if (_error != null && !_loading)
              _buildErrorState(textColor, textSecondary),

            if (_result != null && !_loading) ...[
              _buildProductResult(
                surfaceColor: surfaceColor,
                textColor: textColor,
                textSecondary: textSecondary,
                borderColor: borderColor,
              ),
              const SizedBox(height: 16),
              // Log button
              GestureDetector(
                onTap: _logProduct,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF22C55E), Color(0xFF10B981)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Log ${_result!.totalCalories} Calories',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _resetScan,
                child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: Text(
                      'Scan Another',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(Color textColor, Color textSecondary) {
    return Column(
      children: [
        const SizedBox(height: 8),
        const CircularProgressIndicator(
          color: Color(0xFF3B82F6),
          strokeWidth: 3,
        ),
        const SizedBox(height: 16),
        Text(
          'Looking up product...',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Barcode: $_scannedBarcode',
          style: GoogleFonts.inter(fontSize: 12, color: textSecondary),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildErrorState(Color textColor, Color textSecondary) {
    return Column(
      children: [
        Icon(Icons.search_off_rounded, size: 40, color: textSecondary),
        const SizedBox(height: 8),
        Text(
          _error ?? 'Product not found',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Barcode: $_scannedBarcode',
          style: GoogleFonts.inter(fontSize: 12, color: textSecondary),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _resetScan,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Try Again',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductResult({
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
  }) {
    final item = _result!.items.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product name
        Text(
          item.name,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.servingSize,
          style: GoogleFonts.inter(fontSize: 12, color: textSecondary),
        ),
        const SizedBox(height: 16),

        // Calorie ring + macros row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              // Calorie ring
              SizedBox(
                width: 72,
                height: 72,
                child: CustomPaint(
                  painter: _CalorieRingPainter(
                    calories: item.calories,
                    maxCalories: 500, // Reference scale
                    ringColor: const Color(0xFF8B5CF6),
                    bgRingColor: borderColor,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${item.calories}',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'cal',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Macros
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _macroColumn(
                      '${item.carbsG.round()}g',
                      'Carbs',
                      const Color(0xFFF59E0B),
                      textColor,
                    ),
                    _macroColumn(
                      '${item.fatG.round()}g',
                      'Fat',
                      const Color(0xFFEF4444),
                      textColor,
                    ),
                    _macroColumn(
                      '${item.proteinG.round()}g',
                      'Protein',
                      const Color(0xFF22C55E),
                      textColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _macroColumn(
      String value, String label, Color color, Color textColor) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────
// Scan Overlay Painter — dark overlay with a clear cutout box
// ─────────────────────────────────
class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.5);

    // Draw full overlay
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);

    // Cut out the scan area
    final scanSize = size.width * 0.65;
    final left = (size.width - scanSize) / 2;
    final top = (size.height - scanSize) / 2 - 40;
    final scanRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, scanSize, scanSize),
      const Radius.circular(16),
    );

    // Clear the cutout
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);
    canvas.drawRRect(scanRect, clearPaint);
    canvas.restore();

    // Draw corner brackets
    final bracketPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const bracketLen = 24.0;
    final rect = scanRect.outerRect;

    // Top-left
    canvas.drawLine(Offset(rect.left, rect.top + bracketLen),
        Offset(rect.left, rect.top), bracketPaint);
    canvas.drawLine(Offset(rect.left, rect.top),
        Offset(rect.left + bracketLen, rect.top), bracketPaint);

    // Top-right
    canvas.drawLine(Offset(rect.right - bracketLen, rect.top),
        Offset(rect.right, rect.top), bracketPaint);
    canvas.drawLine(Offset(rect.right, rect.top),
        Offset(rect.right, rect.top + bracketLen), bracketPaint);

    // Bottom-left
    canvas.drawLine(Offset(rect.left, rect.bottom - bracketLen),
        Offset(rect.left, rect.bottom), bracketPaint);
    canvas.drawLine(Offset(rect.left, rect.bottom),
        Offset(rect.left + bracketLen, rect.bottom), bracketPaint);

    // Bottom-right
    canvas.drawLine(Offset(rect.right - bracketLen, rect.bottom),
        Offset(rect.right, rect.bottom), bracketPaint);
    canvas.drawLine(Offset(rect.right, rect.bottom),
        Offset(rect.right, rect.bottom - bracketLen), bracketPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────
// Calorie Ring Painter (like the screenshot)
// ─────────────────────────────────
class _CalorieRingPainter extends CustomPainter {
  final int calories;
  final int maxCalories;
  final Color ringColor;
  final Color bgRingColor;

  _CalorieRingPainter({
    required this.calories,
    required this.maxCalories,
    required this.ringColor,
    required this.bgRingColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 8.0;

    // Background ring
    final bgPaint = Paint()
      ..color = bgRingColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    final progress = (calories / maxCalories).clamp(0.0, 1.0);
    final sweepAngle = 2 * 3.14159 * progress;

    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // Start from top
      sweepAngle,
      false,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CalorieRingPainter old) =>
      old.calories != calories;
}
