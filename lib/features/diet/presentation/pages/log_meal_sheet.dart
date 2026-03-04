import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/diet_models.dart';
import '../bloc/diet_bloc.dart';
import '../bloc/diet_event.dart';

/// Bottom sheet for quick meal entry
class LogMealSheet extends StatefulWidget {
  const LogMealSheet({super.key});

  @override
  State<LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends State<LogMealSheet> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  MealType _selectedType = MealType.lunch;

  static const Color _green = Color(0xFF10B981);
  static const Color _sheetBg = Color(0xFF1A1A1A);
  static const Color _chipBg = Color(0xFF2A2A2A);

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _logMeal() {
    final name = _nameController.text.trim();
    final calories = int.tryParse(_caloriesController.text) ?? 0;
    if (name.isEmpty || calories <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a meal name and calories'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final meal = MealLog(
      name: name,
      calories: calories,
      proteinGrams: int.tryParse(_proteinController.text) ?? 0,
      carbsGrams: int.tryParse(_carbsController.text) ?? 0,
      fatGrams: int.tryParse(_fatController.text) ?? 0,
      mealType: _selectedType,
      timestamp: DateTime.now(),
    );

    context.read<DietBloc>().add(LogMeal(meal: meal));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _sheetBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Log a Meal',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Meal type selector
                _buildLabel('Meal Type'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: MealType.values.map((type) {
                    final isSelected = type == _selectedType;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _green.withOpacity(0.2)
                              : _chipBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isSelected ? _green : Colors.white10,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(type.emoji,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              type.label,
                              style: GoogleFonts.inter(
                                color: isSelected
                                    ? _green
                                    : Colors.white70,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Meal name
                _buildLabel('What did you eat?'),
                const SizedBox(height: 8),
                _buildTextField(_nameController, 'e.g. Grilled chicken salad',
                    TextInputType.text),
                const SizedBox(height: 20),

                // Calories
                _buildLabel('Calories'),
                const SizedBox(height: 8),
                _buildTextField(
                    _caloriesController, 'e.g. 450', TextInputType.number),
                const SizedBox(height: 16),

                // Macros row
                _buildLabel('Macros (optional)'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: _buildTextField(
                            _proteinController, 'Protein (g)',
                            TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _buildTextField(_carbsController, 'Carbs (g)',
                            TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _buildTextField(
                            _fatController, 'Fat (g)', TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 32),

                // CTA
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _logMeal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Log Meal',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
          color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, TextInputType type) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 14),
        filled: true,
        fillColor: _chipBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _green, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
