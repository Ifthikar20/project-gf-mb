import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/meditation_repository.dart';
import 'meditation_event.dart';
import 'meditation_state.dart';

class MeditationBloc extends Bloc<MeditationEvent, MeditationState> {
  final MeditationRepository repository;

  MeditationBloc({required this.repository}) : super(MeditationInitial()) {
    on<LoadMeditationAudios>(_onLoadMeditationAudios);
    on<LoadMeditationTypes>(_onLoadMeditationTypes);
    on<RefreshMeditationAudios>(_onRefreshMeditationAudios);
    on<SelectCategory>(_onSelectCategory);
    on<SelectAudio>(_onSelectAudio);
    on<PlayAudio>(_onPlayAudio);
    on<PauseAudio>(_onPauseAudio);
    on<StopAudio>(_onStopAudio);
    on<SetTimer>(_onSetTimer);
    on<ClearTimer>(_onClearTimer);
  }

  /// Load all meditation audios from API
  Future<void> _onLoadMeditationAudios(
      LoadMeditationAudios event, Emitter<MeditationState> emit) async {
    emit(MeditationLoading());
    try {
      // Fetch audio content from API
      debugPrint('🎵 MeditationBloc: Loading audio content...');
      final audios = await repository.fetchAllAudios();
      
      // Also fetch categories (or use defaults)
      await repository.fetchCategories();
      final meditationTypes = repository.getMeditationTypes();
      final moodBasedTypes = repository.getMoodBasedTypes();
      
      debugPrint('✅ MeditationBloc: Loaded ${audios.length} audios, ${meditationTypes.length} types');
      
      emit(MeditationLoaded(
        audios: audios,
        meditationTypes: meditationTypes,
        moodBasedTypes: moodBasedTypes,
      ));
    } catch (e) {
      debugPrint('❌ MeditationBloc: Error loading audios - $e');
      emit(MeditationError(e.toString()));
    }
  }

  /// Load meditation types/categories
  Future<void> _onLoadMeditationTypes(
      LoadMeditationTypes event, Emitter<MeditationState> emit) async {
    emit(MeditationLoading());
    try {
      final audios = await repository.fetchAllAudios();
      await repository.fetchCategories();
      final meditationTypes = repository.getMeditationTypes();
      final moodBasedTypes = repository.getMoodBasedTypes();
      
      emit(MeditationLoaded(
        audios: audios,
        meditationTypes: meditationTypes,
        moodBasedTypes: moodBasedTypes,
      ));
    } catch (e) {
      emit(MeditationError(e.toString()));
    }
  }

  /// Refresh audio content (force API call)
  Future<void> _onRefreshMeditationAudios(
      RefreshMeditationAudios event, Emitter<MeditationState> emit) async {
    final currentState = state;
    
    try {
      debugPrint('🔄 MeditationBloc: Refreshing audio content...');
      repository.clearCache();
      final audios = await repository.fetchAllAudios(forceRefresh: true);
      await repository.fetchCategories();
      final meditationTypes = repository.getMeditationTypes();
      final moodBasedTypes = repository.getMoodBasedTypes();
      
      if (currentState is MeditationLoaded) {
        emit(currentState.copyWith(
          audios: audios,
          meditationTypes: meditationTypes,
          moodBasedTypes: moodBasedTypes,
        ));
      } else {
        emit(MeditationLoaded(
          audios: audios,
          meditationTypes: meditationTypes,
          moodBasedTypes: moodBasedTypes,
        ));
      }
      
      debugPrint('✅ MeditationBloc: Refreshed ${audios.length} audios');
    } catch (e) {
      debugPrint('❌ MeditationBloc: Refresh failed - $e');
      // Keep current state on refresh error
      if (currentState is! MeditationLoaded) {
        emit(MeditationError('Failed to refresh: $e'));
      }
    }
  }

  /// Select a category filter
  Future<void> _onSelectCategory(
      SelectCategory event, Emitter<MeditationState> emit) async {
    final currentState = state;
    if (currentState is MeditationLoaded) {
      debugPrint('📂 MeditationBloc: Selected category: ${event.category}');
      emit(currentState.copyWith(selectedCategory: event.category));
    }
  }

  /// Select an audio for playback
  Future<void> _onSelectAudio(
      SelectAudio event, Emitter<MeditationState> emit) async {
    final currentState = state;
    if (currentState is MeditationLoaded) {
      // Try to get from cache first, then fetch from API
      var selectedAudio = repository.getAudioById(event.audioId);
      
      if (selectedAudio == null) {
        // Fetch from API
        selectedAudio = await repository.fetchAudioById(event.audioId);
      }
      
      emit(currentState.copyWith(
        selectedAudio: selectedAudio,
        isPlaying: false,
      ));
    }
  }

  Future<void> _onPlayAudio(
      PlayAudio event, Emitter<MeditationState> emit) async {
    final currentState = state;
    if (currentState is MeditationLoaded) {
      emit(currentState.copyWith(isPlaying: true));
    }
  }

  Future<void> _onPauseAudio(
      PauseAudio event, Emitter<MeditationState> emit) async {
    final currentState = state;
    if (currentState is MeditationLoaded) {
      emit(currentState.copyWith(isPlaying: false));
    }
  }

  Future<void> _onStopAudio(
      StopAudio event, Emitter<MeditationState> emit) async {
    final currentState = state;
    if (currentState is MeditationLoaded) {
      emit(currentState.copyWith(isPlaying: false));
    }
  }

  Future<void> _onSetTimer(
      SetTimer event, Emitter<MeditationState> emit) async {
    final currentState = state;
    if (currentState is MeditationLoaded) {
      emit(currentState.copyWith(timerMinutes: event.minutes));
    }
  }

  Future<void> _onClearTimer(
      ClearTimer event, Emitter<MeditationState> emit) async {
    final currentState = state;
    if (currentState is MeditationLoaded) {
      emit(currentState.copyWith(clearTimer: true));
    }
  }
}
