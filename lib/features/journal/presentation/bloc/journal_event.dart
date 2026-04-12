import 'package:equatable/equatable.dart';

/// Journal BLoC events
abstract class JournalEvent extends Equatable {
  const JournalEvent();

  @override
  List<Object?> get props => [];
}

/// Load the journal page data (today's entry + summary + calendar).
class JournalLoadRequested extends JournalEvent {
  const JournalLoadRequested();
}

/// Create a new journal entry for today.
class JournalEntrySubmitted extends JournalEvent {
  final String mood;
  final int moodIntensity;
  final String reflectionText;

  const JournalEntrySubmitted({
    required this.mood,
    this.moodIntensity = 3,
    this.reflectionText = '',
  });

  @override
  List<Object?> get props => [mood, moodIntensity, reflectionText];
}

/// Update an existing journal entry.
class JournalEntryUpdated extends JournalEvent {
  final String entryId;
  final String mood;
  final int moodIntensity;
  final String reflectionText;

  const JournalEntryUpdated({
    required this.entryId,
    required this.mood,
    this.moodIntensity = 3,
    this.reflectionText = '',
  });

  @override
  List<Object?> get props => [entryId, mood, moodIntensity, reflectionText];
}

/// Load past journal entries (pagination).
class JournalPastEntriesRequested extends JournalEvent {
  final String? month;

  const JournalPastEntriesRequested({this.month});

  @override
  List<Object?> get props => [month];
}

/// Change the calendar month being viewed.
class JournalCalendarMonthChanged extends JournalEvent {
  final String month; // YYYY-MM

  const JournalCalendarMonthChanged(this.month);

  @override
  List<Object?> get props => [month];
}
