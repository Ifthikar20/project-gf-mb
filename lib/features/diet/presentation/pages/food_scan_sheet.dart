import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/food_scanner_service.dart';
import '../../data/models/food_scan_result.dart';
import '../bloc/diet_bloc.dart';
import '../bloc/diet_event.dart';

import '../../data/models/diet_models.dart';

/// Bottom sheet for Cal AI food scanning.
/// Captures photo → sends to Gemini Vision → shows detected items + calories.
class FoodScanSheet extends StatefulWidget {
  const FoodScanSheet({super.key});

  @override
  State<FoodScanSheet> createState() => _FoodScanSheetState();
}

class _FoodScanSheetState extends State<FoodScanSheet>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  FoodScanResult? _result;
  bool _scanning = false;
  String? _error;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file != null) {
      setState(() {
        _imageFile = File(file.path);
        _error = null;
      });
      _analyzeImage();
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file != null) {
      setState(() {
        _imageFile = File(file.path);
        _error = null;
      });
      _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageFile == null) return;
    setState(() {
      _scanning = true;
      _error = null;
      _result = null;
    });

    try {
      final bytes = await _imageFile!.readAsBytes();
      final result = await FoodScannerService.instance.analyzeImage(bytes);
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

  MealType _parseMealType(String? type) {
    switch (type) {
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

  void _logMeal() {
    if (_result == null) return;
    final mealType = _parseMealType(_result!.mealType);
    for (final item in _result!.items) {
      context.read<DietBloc>().add(LogMeal(
            meal: MealLog(
              name: item.name,
              calories: item.calories,
              proteinGrams: item.proteinG.round(),
              carbsGrams: item.carbsG.round(),
              fatGrams: item.fatG.round(),
              mealType: mealType,
              timestamp: DateTime.now(),
              notes: 'Scanned via Cal AI (${(item.confidence * 100).round()}% confidence)',
            ),
          ));
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Logged ${_result!.totalCalories} cal from ${_result!.items.length} item(s)',
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
        final mode = themeState.mode;
        final isLight = themeState.isLight;
        final bgColor = ThemeColors.background(mode);
        final surfaceColor = ThemeColors.surface(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        final borderColor = ThemeColors.border(mode);
        final primaryColor = const Color(0xFF3B82F6);

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cal AI Scanner',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Snap a photo of your food',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Image / Scanner area
              if (_imageFile == null && !_scanning && _result == null)
                _buildCaptureButtons(
                  surfaceColor: surfaceColor,
                  textColor: textColor,
                  textSecondary: textSecondary,
                  borderColor: borderColor,
                  primaryColor: primaryColor,
                ),

              if (_imageFile != null)
                _buildImagePreview(borderColor),

              if (_scanning)
                _buildScanningAnimation(
                  textColor: textColor,
                  textSecondary: textSecondary,
                  primaryColor: primaryColor,
                ),

              if (_error != null)
                _buildErrorState(textColor, textSecondary, primaryColor),

              if (_result != null && !_scanning)
                _buildResults(
                  surfaceColor: surfaceColor,
                  textColor: textColor,
                  textSecondary: textSecondary,
                  borderColor: borderColor,
                  primaryColor: primaryColor,
                ),

              // Log button
              if (_result != null && !_scanning) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: GestureDetector(
                    onTap: _logMeal,
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
                ),
              ],

              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCaptureButtons({
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Camera button (big)
          GestureDetector(
            onTap: _takePhoto,
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.08),
                    const Color(0xFF8B5CF6).withOpacity(0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primaryColor.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Take a Photo',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Point at your food and snap',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Gallery button (compact)
          GestureDetector(
            onTap: _pickFromGallery,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_rounded, size: 18, color: textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Choose from Gallery',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(Color borderColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        image: DecorationImage(
          image: FileImage(_imageFile!),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildScanningAnimation({
    required Color textColor,
    required Color textSecondary,
    required Color primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 0.8 + (_pulseController.value * 0.4);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.6 + _pulseController.value * 0.4),
                        const Color(0xFF8B5CF6).withOpacity(0.4 + _pulseController.value * 0.4),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing your food...',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'AI is detecting calories & macros',
            style: GoogleFonts.inter(fontSize: 12, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Color textColor, Color textSecondary, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 40, color: textSecondary),
          const SizedBox(height: 8),
          Text(
            'Analysis failed',
            style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Make sure your .env has GEMINI_API_KEY',
            style: GoogleFonts.inter(fontSize: 12, color: textSecondary),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _analyzeImage,
            child: Text(
              'Retry',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults({
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    final result = _result!;
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Total calories hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    '${result.totalCalories}',
                    style: GoogleFonts.inter(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'Calories',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Macro row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _macroChip('Protein', '${result.totalProtein.toStringAsFixed(1)}g',
                          const Color(0xFFEF4444)),
                      _macroChip('Carbs', '${result.totalCarbs.toStringAsFixed(1)}g',
                          const Color(0xFFF59E0B)),
                      _macroChip('Fat', '${result.totalFat.toStringAsFixed(1)}g',
                          const Color(0xFF22C55E)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detected items
            Text(
              'Detected Items',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            ...result.items.map((item) => _buildFoodItemRow(
                  item,
                  surfaceColor: surfaceColor,
                  textColor: textColor,
                  textSecondary: textSecondary,
                  borderColor: borderColor,
                )),
          ],
        ),
      ),
    );
  }

  Widget _macroChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFoodItemRow(
    DetectedFoodItem item, {
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.servingSize,
                  style: GoogleFonts.inter(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.calories} cal',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              Text(
                'P${item.proteinG.toStringAsFixed(0)} C${item.carbsG.toStringAsFixed(0)} F${item.fatG.toStringAsFixed(0)}',
                style: GoogleFonts.inter(fontSize: 10, color: textSecondary),
              ),
            ],
          ),
          if (item.confidence > 0 && item.confidence < 0.7) ...[
            const SizedBox(width: 8),
            Icon(Icons.help_outline, size: 14, color: textSecondary),
          ],
        ],
      ),
    );
  }
}
