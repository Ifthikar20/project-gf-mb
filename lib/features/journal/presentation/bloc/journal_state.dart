import 'package:equatable/equatable.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/entities/mood_summary.dart';

/// Journal BLoC states
abstract class JournalState extends Equatable {
  const JournalState();

  @override
  List<Object?> get props => [];
}

/// Initial state — nothing loaded yet.
class JournalInitial extends JournalState {
  const JournalInitial();
}

/// Loading the journal page data.
class JournalLoading extends JournalState {
  const JournalLoading();
}

/// Journal data loaded successfully.
class JournalLoaded extends JournalState {
  final JournalEntry? todayEntry;
  final MoodSummary? moodSummary;
  final CalendarMonth? calendarMonth;
  final List<JournalEntry> pastEntries;
  final bool isSubmitting;
  final String? submitError;

  const JournalLoaded({
    this.todayEntry,
    this.moodSummary,
    this.calendarMonth,
    this.pastEntries = const [],
    this.isSubmitting = false,
    this.submitError,
  });

  @override
  List<Object?> get props => [
    todayEntry?.id,
    todayEntry?.mood,
    todayEntry?.aiInsight,
    moodSummary?.streak.currentStreak,
    calendarMonth?.month,
    pastEntries.length,
    isSubmitting,
    submitError,
  ];

  JournalLoaded copyWith({
    JournalEntry? todayEntry,
    MoodSummary? moodSummary,
    CalendarMonth? calendarMonth,
    List<JournalEntry>? pastEntries,
    bool? isSubmitting,
    String? submitError,
    bool clearTodayEntry = false,
    bool clearError = false,
  }) {
    return JournalLoaded(
      todayEntry: clearTodayEntry ? null : (todayEntry ?? this.todayEntry),
      moodSummary: moodSummary ?? this.moodSummary,
      calendarMonth: calendarMonth ?? this.calendarMonth,
      pastEntries: pastEntries ?? this.pastEntries,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearError ? null : (submitError ?? this.submitError),
    );
  }
}

/// Error loading journal data.
class JournalError extends JournalState {
  final String message;

  const JournalError(this.message);

  @override
  List<Object?> get props => [message];
}
