import 'package:equatable/equatable.dart';

class GoalEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final int targetValue;
  final int currentValue;
  final DateTime createdAt;
  final DateTime? targetDate;
  final bool isCompleted;

  const GoalEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.targetValue,
    this.currentValue = 0,
    required this.createdAt,
    this.targetDate,
    this.isCompleted = false,
  });

  double get progress {
    if (targetValue == 0) return 0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  GoalEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? targetValue,
    int? currentValue,
    DateTime? createdAt,
    DateTime? targetDate,
    bool? isCompleted,
  }) {
    return GoalEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      createdAt: createdAt ?? this.createdAt,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        targetValue,
        currentValue,
        createdAt,
        targetDate,
        isCompleted,
      ];
}
