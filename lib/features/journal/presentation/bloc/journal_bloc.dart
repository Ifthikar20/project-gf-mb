import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/journal_service.dart';
import 'journal_event.dart';
import 'journal_state.dart';

/// Manages journal state: loading entries, creating/updating, and calendar navigation.
///
/// Uses the same 5-second timeout pattern as other BLoCs in the app
/// to prevent UI hangs if the backend is slow.
class JournalBloc extends Bloc<JournalEvent, JournalState> {
  final JournalService _journalService;

  JournalBloc({JournalService? journalService})
      : _journalService = journalService ?? JournalService(),
        super(const JournalInitial()) {
    on<JournalLoadRequested>(_onLoadRequested);
    on<JournalEntrySubmitted>(_onEntrySubmitted);
    on<JournalEntryUpdated>(_onEntryUpdated);
    on<JournalPastEntriesRequested>(_onPastEntriesRequested);
    on<JournalCalendarMonthChanged>(_onCalendarMonthChanged);
  }

  Future<void> _onLoadRequested(
    JournalLoadRequested event,
    Emitter<JournalState> emit,
  ) async {
    emit(const JournalLoading());

    try {
      // Fetch all data in parallel with timeout
      final results = await Future.wait([
        _journalService.getTodayEntry().timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        ),
        _journalService.getMoodSummary().timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        ),
        _journalService.getCalendarData().timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        ),
        _journalService.getEntries(limit: 10).timeout(
          const Duration(seconds: 5),
          onTimeout: () => [],
        ),
      ]);

      emit(JournalLoaded(
        todayEntry: results[0] as dynamic,
        moodSummary: results[1] as dynamic,
        calendarMonth: results[2] as dynamic,
        pastEntries: (results[3] as List).cast(),
      ));
    } catch (e) {
      emit(JournalError('Failed to load journal: $e'));
    }
  }

  Future<void> _onEntrySubmitted(
    JournalEntrySubmitted event,
    Emitter<JournalState> emit,
  ) async {
    final currentState = state;
    if (currentState is JournalLoaded) {
      emit(currentState.copyWith(isSubmitting: true, clearError: true));
    } else {
      emit(const JournalLoaded(isSubmitting: true));
    }

    try {
      final entry = await _journalService.createEntry(
        mood: event.mood,
        moodIntensity: event.moodIntensity,
        reflectionText: event.reflectionText,
      );

      if (entry != null) {
        // Refresh summary and calendar after creation
        final summary = await _journalService.getMoodSummary();
        final calendar = await _journalService.getCalendarData();
        final pastEntries = await _journalService.getEntries(limit: 10);

        emit(JournalLoaded(
          todayEntry: entry,
          moodSummary: summary,
          calendarMonth: calendar,
          pastEntries: pastEntries,
          isSubmitting: false,
        ));
      } else {
        final loaded = state is JournalLoaded ? state as JournalLoaded : const JournalLoaded();
        emit(loaded.copyWith(
          isSubmitting: false,
          submitError: 'Failed to save journal entry. Please try again.',
        ));
      }
    } catch (e) {
      final loaded = state is JournalLoaded ? state as JournalLoaded : const JournalLoaded();
      emit(loaded.copyWith(
        isSubmitting: false,
        submitError: 'Something went wrong. Please try again.',
      ));
    }
  }

  Future<void> _onEntryUpdated(
    JournalEntryUpdated event,
    Emitter<JournalState> emit,
  ) async {
    final currentState = state;
    if (currentState is! JournalLoaded) return;

    emit(currentState.copyWith(isSubmitting: true, clearError: true));

    try {
      final entry = await _journalService.updateEntry(
        entryId: event.entryId,
        mood: event.mood,
        moodIntensity: event.moodIntensity,
        reflectionText: event.reflectionText,
      );

      if (entry != null) {
        emit(currentState.copyWith(
          todayEntry: entry,
          isSubmitting: false,
        ));
      } else {
        emit(currentState.copyWith(
          isSubmitting: false,
          submitError: 'Failed to update entry.',
        ));
      }
    } catch (e) {
      emit(currentState.copyWith(
        isSubmitting: false,
        submitError: 'Something went wrong.',
      ));
    }
  }

  Future<void> _onPastEntriesRequested(
    JournalPastEntriesRequested event,
    Emitter<JournalState> emit,
  ) async {
    final currentState = state;
    if (currentState is! JournalLoaded) return;

    try {
      final entries = await _journalService.getEntries(
        month: event.month,
        limit: 20,
      );
      emit(currentState.copyWith(pastEntries: entries));
    } catch (_) {}
  }

  Future<void> _onCalendarMonthChanged(
    JournalCalendarMonthChanged event,
    Emitter<JournalState> emit,
  ) async {
    final currentState = state;
    if (currentState is! JournalLoaded) return;

    try {
      final calendar = await _journalService.getCalendarData(month: event.month);
      if (calendar != null) {
        emit(currentState.copyWith(calendarMonth: calendar));
      }
    } catch (_) {}
  }
}
