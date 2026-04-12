import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/sleep_data_service.dart';
import 'sleep_event.dart';
import 'sleep_state.dart';

class SleepBloc extends Bloc<SleepEvent, SleepState> {
  final SleepDataService _service;

  SleepBloc({SleepDataService? service})
      : _service = service ?? SleepDataService(),
        super(const SleepInitial()) {
    on<SleepLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    SleepLoadRequested event,
    Emitter<SleepState> emit,
  ) async {
    emit(const SleepLoading());
    try {
      final score = await _service.computeSleepScore();
      final insights = await _service.generateInsights(score);

      emit(SleepLoaded(
        sleepScore: score,
        insights: insights,
      ));
    } catch (e) {
      emit(SleepError('Failed to load sleep data: $e'));
    }
  }
}
