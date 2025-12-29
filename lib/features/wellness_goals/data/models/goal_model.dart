import 'package:hive/hive.dart';
import '../../domain/entities/goal_entity.dart';

part 'goal_model.g.dart';

@HiveType(typeId: 0)
class GoalModel extends GoalEntity {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final int targetValue;

  @HiveField(5)
  final int currentValue;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime? targetDate;

  @HiveField(8)
  final bool isCompleted;

  const GoalModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.targetValue,
    this.currentValue = 0,
    required this.createdAt,
    this.targetDate,
    this.isCompleted = false,
  }) : super(
          id: id,
          title: title,
          description: description,
          category: category,
          targetValue: targetValue,
          currentValue: currentValue,
          createdAt: createdAt,
          targetDate: targetDate,
          isCompleted: isCompleted,
        );

  factory GoalModel.fromEntity(GoalEntity entity) {
    return GoalModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      category: entity.category,
      targetValue: entity.targetValue,
      currentValue: entity.currentValue,
      createdAt: entity.createdAt,
      targetDate: entity.targetDate,
      isCompleted: entity.isCompleted,
    );
  }

  GoalEntity toEntity() {
    return GoalEntity(
      id: id,
      title: title,
      description: description,
      category: category,
      targetValue: targetValue,
      currentValue: currentValue,
      createdAt: createdAt,
      targetDate: targetDate,
      isCompleted: isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'createdAt': createdAt.toIso8601String(),
      'targetDate': targetDate?.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      targetValue: json['targetValue'] as int,
      currentValue: json['currentValue'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
