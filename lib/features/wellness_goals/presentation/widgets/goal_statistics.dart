import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/goal_entity.dart';

class GoalStatistics extends StatelessWidget {
  final List<GoalEntity> goals;

  const GoalStatistics({super.key, required this.goals});

  @override
  Widget build(BuildContext context) {
    final totalGoals = goals.length;
    final completedGoals = goals.where((g) => g.isCompleted).length;
    final inProgressGoals = totalGoals - completedGoals;
    final averageProgress = totalGoals > 0
        ? goals.map((g) => g.progress).reduce((a, b) => a + b) / totalGoals
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.track_changes,
                    label: 'Total Goals',
                    value: totalGoals.toString(),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingS),
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle,
                    label: 'Completed',
                    value: completedGoals.toString(),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingS),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.pending_actions,
                    label: 'In Progress',
                    value: inProgressGoals.toString(),
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingS),
                Expanded(
                  child: _StatCard(
                    icon: Icons.trending_up,
                    label: 'Avg. Progress',
                    value: '${(averageProgress * 100).toInt()}%',
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
