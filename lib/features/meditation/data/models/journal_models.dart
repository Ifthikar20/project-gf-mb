import 'package:hive/hive.dart';

part 'journal_models.g.dart';

/// A meditation journal entry stored locally via Hive
@HiveType(typeId: 32)
class MeditationJournalEntry extends HiveObject {
  @HiveField(0)
  final DateTime date;

  /// Mood after session: 1-5
  @HiveField(1)
  final int moodAfter;

  /// What the user is grateful for
  @HiveField(2)
  final String? gratitude;

  /// Free-form journal note
  @HiveField(3)
  final String? note;

  /// Type of session: 'breathing', 'meditation', 'mindfulness'
  @HiveField(4)
  final String sessionType;

  /// Duration of the session in seconds
  @HiveField(5)
  final int? durationSeconds;

  MeditationJournalEntry({
    required this.date,
    required this.moodAfter,
    this.gratitude,
    this.note,
    required this.sessionType,
    this.durationSeconds,
  });

  String get moodEmoji {
    switch (moodAfter) {
      case 1:
        return '😔';
      case 2:
        return '😐';
      case 3:
        return '🙂';
      case 4:
        return '😊';
      case 5:
        return '🧘';
      default:
        return '🙂';
    }
  }

  String get moodLabel {
    switch (moodAfter) {
      case 1:
        return 'Still restless';
      case 2:
        return 'Slightly calmer';
      case 3:
        return 'Calm';
      case 4:
        return 'Peaceful';
      case 5:
        return 'Deeply centered';
      default:
        return 'Calm';
    }
  }
}
