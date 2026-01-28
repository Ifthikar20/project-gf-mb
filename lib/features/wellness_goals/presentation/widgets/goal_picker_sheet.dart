import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/goal_tracking_service.dart';
import '../../data/goal_templates.dart';
import '../../data/models/goal_model.dart';
import '../bloc/goals_bloc.dart';
import '../bloc/goals_event.dart';

/// Bottom sheet for picking and adding goal templates
class GoalPickerSheet extends StatefulWidget {
  const GoalPickerSheet({super.key});

  @override
  State<GoalPickerSheet> createState() => _GoalPickerSheetState();
}

class _GoalPickerSheetState extends State<GoalPickerSheet> {
  String _selectedCategory = 'All';
  
  final List<String> _categories = [
    'All',
    'Featured',
    'Streaks',
    'Videos',
    'Meditation',
    'Time',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final isVintage = themeState.isVintage;
        final bgColor = ThemeColors.background(mode);
        final surfaceColor = ThemeColors.surface(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        final primaryColor = ThemeColors.primary(mode);

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a Goal',
                      style: isVintage
                          ? GoogleFonts.playfairDisplay(
                              color: textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            )
                          : TextStyle(
                              color: textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Smart goals that track automatically',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Category filters
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = category),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isVintage ? Colors.black : primaryColor)
                              : (isVintage ? Colors.white : surfaceColor),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isVintage
                                ? (isSelected ? Colors.black : Colors.grey.shade300)
                                : (isSelected ? primaryColor : Colors.white.withOpacity(0.1)),
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected
                                ? (isVintage ? Colors.white : Colors.white)
                                : (isVintage ? Colors.black : textColor),
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Goal templates grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _filteredTemplates.length,
                  itemBuilder: (context, index) {
                    final template = _filteredTemplates[index];
                    return _buildTemplateCard(
                      template,
                      surfaceColor,
                      textColor,
                      textSecondary,
                      isVintage,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<GoalTemplate> get _filteredTemplates {
    switch (_selectedCategory) {
      case 'All':
        return GoalTemplates.all;
      case 'Featured':
        return GoalTemplates.featured;
      case 'Streaks':
        return GoalTemplates.streakGoals;
      case 'Videos':
        return GoalTemplates.contentGoals.where((t) => t.type.name.contains('video')).toList();
      case 'Meditation':
        return GoalTemplates.contentGoals.where((t) => t.type.name.contains('audio')).toList();
      case 'Time':
        return GoalTemplates.timeGoals;
      default:
        return GoalTemplates.all;
    }
  }

  Widget _buildTemplateCard(
    GoalTemplate template,
    Color surfaceColor,
    Color textColor,
    Color textSecondary,
    bool isVintage,
  ) {
    return GestureDetector(
      onTap: () => _addGoal(template),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isVintage ? Colors.grey.shade200 : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: template.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                template.icon,
                color: template.color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            
            // Title
            Text(
              template.title,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            
            // Description
            Expanded(
              child: Text(
                template.description,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Period badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: template.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getPeriodLabel(template.period),
                style: TextStyle(
                  color: template.color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPeriodLabel(dynamic period) {
    switch (period.toString()) {
      case 'GoalPeriod.daily':
        return 'Daily';
      case 'GoalPeriod.weekly':
        return 'Weekly';
      case 'GoalPeriod.monthly':
        return 'Monthly';
      case 'GoalPeriod.allTime':
        return 'Challenge';
      default:
        return 'Goal';
    }
  }

  Future<void> _addGoal(GoalTemplate template) async {
    // Check if user can add more goals
    final canAdd = await GoalTrackingService.instance.canAddMoreGoals();
    if (!canAdd) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Maximum 5 active goals allowed. Complete or delete a goal first.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    // Create goal from template
    final goal = template.toEntity();
    
    // Add to bloc
    if (mounted) {
      context.read<GoalsBloc>().add(AddGoal(goal));
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(template.icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Added: ${template.title}'),
              ),
            ],
          ),
          backgroundColor: template.color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      
      // Close sheet
      Navigator.of(context).pop();
    }
  }
}
