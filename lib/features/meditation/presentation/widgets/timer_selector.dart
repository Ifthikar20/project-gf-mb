import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class TimerSelector extends StatelessWidget {
  final int? selectedTimer;
  final Function(int?) onTimerSelected;

  const TimerSelector({
    super.key,
    this.selectedTimer,
    required this.onTimerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meditation Timer',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...AppConstants.meditationTimers.map((minutes) {
              final isSelected = selectedTimer == minutes;
              return ChoiceChip(
                label: Text('$minutes min'),
                selected: isSelected,
                onSelected: (selected) {
                  onTimerSelected(selected ? minutes : null);
                },
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }),
            if (selectedTimer != null)
              ActionChip(
                label: const Text('Clear'),
                avatar: const Icon(Icons.close, size: 16),
                onPressed: () => onTimerSelected(null),
              ),
          ],
        ),
      ],
    );
  }
}
