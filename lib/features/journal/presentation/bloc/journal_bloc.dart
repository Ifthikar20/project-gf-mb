import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/journal_service.dart';
import '../../domain/entities/mood_summary.dart';
import 'journal_event.dart';
import 'journal_state.dart';

class JournalBloc extends Bloc<JournalEvent, JournalState> {
  final JournalService _service;

  JournalBloc({JournalService? service})
      : _service = service ?? JournalService.instance,
        super(JournalInitial()) {
    on<LoadJournal>(_onLoad);
    on<RefreshJournal>(_onRefresh);
    on<SubmitJournalEntry>(_onSubmit);
    on<LoadMonthEntries>(_onLoadMonth);
    on<LoadCalendarMonth>(_onLoadCalendar);
  }

  Future<void> _onLoad(LoadJournal event, Emitter<JournalState> emit) async {
    if (state is JournalLoaded) return; // already loaded
    emit(JournalLoading());
    await _fetchAll(emit);
  }

  Future<void> _onRefresh(
      RefreshJournal event, Emitter<JournalState> emit) async {
    await _fetchAll(emit);
  }

  Future<void> _fetchAll(Emitter<JournalState> emit) async {
    try {
      // Fire all requests concurrently
      final results = await Future.wait([
        _service.getTodayEntry().catchError((_) => null),
        _service.getMoodSummary(),
        _service.getCalendar(),
        _service.getEntries(),
      ]).timeout(const Duration(seconds: 8), onTimeout: () {
        throw Exception('Journal data took too long to load');
      });

      emit(JournalLoaded(
        todayEntry: results[0] as dynamic,
        summary: results[1] as MoodSummary,
        calendar: results[2] as CalendarData,
        entries: results[3] as List<dynamic>,
      ));
    } catch (e) {
      debugPrint('📓 JournalBloc._fetchAll error: $e');
      emit(JournalError('Could not load journal: $e'));
    }
  }

  Future<void> _onSubmit(
      SubmitJournalEntry event, Emitter<JournalState> emit) async {
    // Show loading spinner on the compose sheet
    final prev = state;
    if (prev is JournalLoaded) {
      emit(prev.copyWith(isSubmitting: true));
    }

    try {
      final entry = await _service.createEntry(
        mood: event.mood,
        moodIntensity: event.moodIntensity,
        reflectionText: event.reflectionText,
      );

      // Emit transient "submitted" state (triggers animation)
      emit(JournalEntrySubmitted(entry: entry));

      // Then refresh everything to update calendar/summary
      await _fetchAll(emit);
    } catch (e) {
      debugPrint('📓 JournalBloc._onSubmit error: $e');
      // Restore previous state with submitting=false
      if (prev is JournalLoaded) {
        emit(prev.copyWith(isSubmitting: false));
      }
      emit(JournalError('Could not save entry: $e'));
    }
  }

  Future<void> _onLoadMonth(
      LoadMonthEntries event, Emitter<JournalState> emit) async {
    try {
      final entries = await _service.getEntries(month: event.month);
      if (state is JournalLoaded) {
        emit((state as JournalLoaded).copyWith(entries: entries));
      }
    } catch (e) {
      debugPrint('📓 JournalBloc._onLoadMonth error: $e');
    }
  }

  Future<void> _onLoadCalendar(
      LoadCalendarMonth event, Emitter<JournalState> emit) async {
    try {
      final calendar = await _service.getCalendar(month: event.month);
      if (state is JournalLoaded) {
        emit((state as JournalLoaded).copyWith(calendar: calendar));
      }
    } catch (e) {
      debugPrint('📓 JournalBloc._onLoadCalendar error: $e');
    }
  }
}
