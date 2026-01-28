import 'package:hive/hive.dart';
import '../../domain/entities/goal_entity.dart';

part 'goal_model.g.dart';

@HiveType(typeId: 0)
class GoalModel extends GoalEntity {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String title;

  @HiveField(2)
  @override
  final String description;

  @HiveField(3)
  @override
  final String category;

  @HiveField(4)
  @override
  final int targetValue;

  @HiveField(5)
  @override
  final int currentValue;

  @HiveField(6)
  @override
  final DateTime createdAt;

  @HiveField(7)
  @override
  final DateTime? targetDate;

  @HiveField(8)
  @override
  final bool isCompleted;

  // New fields for smart tracking
  @HiveField(9)
  final int typeIndex; // Store GoalType as int

  @HiveField(10)
  final int periodIndex; // Store GoalPeriod as int

  @HiveField(11)
  @override
  final DateTime periodStart;

  @HiveField(12)
  final List<String> trackedIdsList; // Store Set as List

  @HiveField(13)
  @override
  final int streakDays;

  @HiveField(14)
  @override
  final DateTime? lastActivityDate;

  @HiveField(15)
  @override
  final String? iconName;

  GoalModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.targetValue,
    this.currentValue = 0,
    required this.createdAt,
    this.targetDate,
    this.isCompleted = false,
    this.typeIndex = 0,
    this.periodIndex = 3, // allTime
    DateTime? periodStart,
    this.trackedIdsList = const [],
    this.streakDays = 0,
    this.lastActivityDate,
    this.iconName,
  })  : periodStart = periodStart ?? createdAt,
        super(
          id: id,
          title: title,
          description: description,
          category: category,
          targetValue: targetValue,
          currentValue: currentValue,
          createdAt: createdAt,
          targetDate: targetDate,
          isCompleted: isCompleted,
          type: GoalType.values[typeIndex],
          period: GoalPeriod.values[periodIndex],
          periodStart: periodStart ?? createdAt,
          trackedIds: Set.from(trackedIdsList),
          streakDays: streakDays,
          lastActivityDate: lastActivityDate,
          iconName: iconName,
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
      typeIndex: entity.type.index,
      periodIndex: entity.period.index,
      periodStart: entity.periodStart,
      trackedIdsList: entity.trackedIds.toList(),
      streakDays: entity.streakDays,
      lastActivityDate: entity.lastActivityDate,
      iconName: entity.iconName,
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
      type: GoalType.values[typeIndex],
      period: GoalPeriod.values[periodIndex],
      periodStart: periodStart,
      trackedIds: Set.from(trackedIdsList),
      streakDays: streakDays,
      lastActivityDate: lastActivityDate,
      iconName: iconName,
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
      'type': typeIndex,
      'period': periodIndex,
      'periodStart': periodStart.toIso8601String(),
      'trackedIds': trackedIdsList,
      'streakDays': streakDays,
      'lastActivityDate': lastActivityDate?.toIso8601String(),
      'iconName': iconName,
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
      typeIndex: json['type'] as int? ?? 0,
      periodIndex: json['period'] as int? ?? 3,
      periodStart: json['periodStart'] != null
          ? DateTime.parse(json['periodStart'] as String)
          : null,
      trackedIdsList: (json['trackedIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      streakDays: json['streakDays'] as int? ?? 0,
      lastActivityDate: json['lastActivityDate'] != null
          ? DateTime.parse(json['lastActivityDate'] as String)
          : null,
      iconName: json['iconName'] as String?,
    );
  }
}
