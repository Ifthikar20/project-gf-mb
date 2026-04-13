import 'package:equatable/equatable.dart';

abstract class JournalEvent extends Equatable {
  const JournalEvent();
  @override
  List<Object?> get props => [];
}

/// Load journal page data (today's entry, calendar, summary)
class LoadJournal extends JournalEvent {}

/// Refresh all journal data from API
class RefreshJournal extends JournalEvent {}

/// Create or update today's journal entry
class SubmitJournalEntry extends JournalEvent {
  final String mood;
  final int moodIntensity;
  final String reflectionText;

  const SubmitJournalEntry({
    required this.mood,
    this.moodIntensity = 3,
    this.reflectionText = '',
  });

  @override
  List<Object?> get props => [mood, moodIntensity, reflectionText];
}

/// Load entries for a specific month
class LoadMonthEntries extends JournalEvent {
  final String month; // YYYY-MM format
  const LoadMonthEntries({required this.month});
  @override
  List<Object?> get props => [month];
}

/// Load calendar heatmap for a specific month
class LoadCalendarMonth extends JournalEvent {
  final String month; // YYYY-MM format
  const LoadCalendarMonth({required this.month});
  @override
  List<Object?> get props => [month];
}
