import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/wellness_score_service.dart';
import 'wellness_score_event.dart';
import 'wellness_score_state.dart';

class WellnessScoreBloc extends Bloc<WellnessScoreEvent, WellnessScoreState> {
  final WellnessScoreService _service;

  WellnessScoreBloc({WellnessScoreService? service})
      : _service = service ?? WellnessScoreService(),
        super(const WellnessScoreInitial()) {
    on<WellnessScoreLoadRequested>(_onLoadRequested);
    on<WellnessScoreHistoryRequested>(_onHistoryRequested);
  }

  Future<void> _onLoadRequested(
    WellnessScoreLoadRequested event,
    Emitter<WellnessScoreState> emit,
  ) async {
    emit(const WellnessScoreLoading());
    try {
      final results = await Future.wait([
        _service.computeTodayScore(),
        _service.getScoreHistory(days: 30),
      ]);

      emit(WellnessScoreLoaded(
        score: results[0] as dynamic,
        history: (results[1] as List).cast(),
      ));
    } catch (e) {
      emit(WellnessScoreError('Failed to compute score: $e'));
    }
  }

  Future<void> _onHistoryRequested(
    WellnessScoreHistoryRequested event,
    Emitter<WellnessScoreState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WellnessScoreLoaded) return;

    try {
      final history = await _service.getScoreHistory(days: event.days);
      emit(currentState.copyWith(history: history));
    } catch (_) {}
  }
}
