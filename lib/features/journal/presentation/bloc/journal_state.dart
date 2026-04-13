import 'package:equatable/equatable.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/entities/mood_summary.dart';

abstract class JournalState extends Equatable {
  const JournalState();
  @override
  List<Object?> get props => [];
}

class JournalInitial extends JournalState {}

class JournalLoading extends JournalState {}

/// Main loaded state — holds all journal data.
class JournalLoaded extends JournalState {
  final JournalEntry? todayEntry;
  final MoodSummary summary;
  final CalendarData calendar;
  final List<JournalEntry> entries;
  final bool isSubmitting;

  const JournalLoaded({
    this.todayEntry,
    this.summary = const MoodSummary(),
    this.calendar = const CalendarData(month: ''),
    this.entries = const [],
    this.isSubmitting = false,
  });

  JournalLoaded copyWith({
    JournalEntry? todayEntry,
    MoodSummary? summary,
    CalendarData? calendar,
    List<JournalEntry>? entries,
    bool? isSubmitting,
  }) {
    return JournalLoaded(
      todayEntry: todayEntry ?? this.todayEntry,
      summary: summary ?? this.summary,
      calendar: calendar ?? this.calendar,
      entries: entries ?? this.entries,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props =>
      [todayEntry?.id, summary, calendar, entries, isSubmitting];
}

/// Entry was just submitted successfully — triggers UI animation.
class JournalEntrySubmitted extends JournalState {
  final JournalEntry entry;
  const JournalEntrySubmitted({required this.entry});
  @override
  List<Object?> get props => [entry.id];
}

class JournalError extends JournalState {
  final String message;
  const JournalError(this.message);
  @override
  List<Object?> get props => [message];
}
