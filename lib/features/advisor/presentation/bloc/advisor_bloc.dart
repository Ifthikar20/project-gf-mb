import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/wellness_advisor_service.dart';
import 'advisor_event.dart';
import 'advisor_state.dart';

class AdvisorBloc extends Bloc<AdvisorEvent, AdvisorState> {
  final WellnessAdvisorService _service;

  AdvisorBloc({WellnessAdvisorService? service})
      : _service = service ?? WellnessAdvisorService.instance,
        super(AdvisorInitial()) {
    on<LoadSuggestions>(_onLoad);
    on<RefreshSuggestions>(_onRefresh);
    on<DismissSuggestion>(_onDismiss);
  }

  Future<void> _onLoad(
      LoadSuggestions event, Emitter<AdvisorState> emit) async {
    if (state is AdvisorLoaded) return; // already loaded, use cache
    emit(AdvisorLoading());
    try {
      final suggestions = await _service.getSuggestions();
      emit(AdvisorLoaded(suggestions: suggestions));
    } catch (e) {
      emit(AdvisorError('Failed to load suggestions: $e'));
    }
  }

  Future<void> _onRefresh(
      RefreshSuggestions event, Emitter<AdvisorState> emit) async {
    try {
      _service.invalidateCache();
      final suggestions = await _service.getSuggestions(forceRefresh: true);
      final dismissed =
          state is AdvisorLoaded ? (state as AdvisorLoaded).dismissedIds : <String>{};
      emit(AdvisorLoaded(suggestions: suggestions, dismissedIds: dismissed));
    } catch (e) {
      emit(AdvisorError('Failed to refresh suggestions: $e'));
    }
  }

  void _onDismiss(DismissSuggestion event, Emitter<AdvisorState> emit) {
    if (state is AdvisorLoaded) {
      final current = state as AdvisorLoaded;
      emit(AdvisorLoaded(
        suggestions: current.suggestions,
        dismissedIds: {...current.dismissedIds, event.suggestionId},
      ));
    }
  }
}
