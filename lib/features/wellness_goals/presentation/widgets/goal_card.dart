import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/goal_entity.dart';

class GoalCard extends StatelessWidget {
  final GoalEntity goal;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(int) onProgressUpdate;

  const GoalCard({
    super.key,
    required this.goal,
    required this.onTap,
    required this.onDelete,
    required this.onProgressUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(goal.category).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusS,
                      ),
                    ),
                    child: Text(
                      goal.category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getCategoryColor(goal.category),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const Spacer(),
                  if (goal.isCompleted)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                      iconSize: 20,
                    ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingS),
              Text(
                goal.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppConstants.spacingXS),
              Text(
                goal.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppConstants.spacingM),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${goal.currentValue}/${goal.targetValue}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingXS),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusS,
                    ),
                    child: LinearProgressIndicator(
                      value: goal.progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getCategoryColor(goal.category),
                      ),
                    ),
                  ),
                ],
              ),
              if (!goal.isCompleted) ...[
                const SizedBox(height: AppConstants.spacingM),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (goal.currentValue > 0) {
                            onProgressUpdate(goal.currentValue - 1);
                          }
                        },
                        icon: const Icon(Icons.remove, size: 16),
                        label: const Text('Decrease'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (goal.currentValue < goal.targetValue) {
                            onProgressUpdate(goal.currentValue + 1);
                          }
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Increase'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (goal.targetDate != null) ...[
                const SizedBox(height: AppConstants.spacingS),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Target: ${goal.targetDate!.day}/${goal.targetDate!.month}/${goal.targetDate!.year}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Mindfulness':
        return AppTheme.primaryColor;
      case 'Exercise':
        return AppTheme.accentColor;
      case 'Nutrition':
        return Colors.green;
      case 'Sleep':
        return AppTheme.secondaryColor;
      case 'Meditation':
        return const Color(0xFF8B7BA8);
      case 'Reading':
        return Colors.blue;
      case 'Hydration':
        return Colors.lightBlue;
      case 'Social':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}
