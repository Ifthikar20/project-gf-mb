import 'package:hive/hive.dart';

part 'wellness_checkin_model.g.dart';

/// Daily wellness check-in stored locally via Hive
@HiveType(typeId: 20)
class WellnessCheckInModel extends HiveObject {
  /// Mood: 1=Awful, 2=Low, 3=Okay, 4=Good, 5=Great
  @HiveField(0)
  final int mood;

  /// Energy level: 1-5
  @HiveField(1)
  final int energyLevel;

  /// Sleep quality: 1-5 (optional)
  @HiveField(2)
  final int? sleepQuality;

  /// Check-in date (just date, no time)
  @HiveField(3)
  final DateTime date;

  /// Optional notes
  @HiveField(4)
  final String? notes;

  WellnessCheckInModel({
    required this.mood,
    required this.energyLevel,
    this.sleepQuality,
    required this.date,
    this.notes,
  });

  /// Check if this check-in is for today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Mood label
  String get moodLabel {
    switch (mood) {
      case 1:
        return 'Awful';
      case 2:
        return 'Low';
      case 3:
        return 'Okay';
      case 4:
        return 'Good';
      case 5:
        return 'Great';
      default:
        return 'Unknown';
    }
  }

  /// Energy label
  String get energyLabel {
    switch (energyLevel) {
      case 1:
        return 'Exhausted';
      case 2:
        return 'Tired';
      case 3:
        return 'Normal';
      case 4:
        return 'Energized';
      case 5:
        return 'Supercharged';
      default:
        return 'Unknown';
    }
  }
}
