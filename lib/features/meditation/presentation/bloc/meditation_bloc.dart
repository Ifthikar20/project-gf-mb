import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/meditation_repository.dart';
import 'meditation_event.dart';
import 'meditation_state.dart';

class MeditationBloc extends Bloc<MeditationEvent, MeditationState> {
  final MeditationRepository repository;

  MeditationBloc({required this.repository}) : super(MeditationInitial()) {
    on<LoadMeditationAudios>(_onLoadMeditationAudios);
    on<LoadMeditationTypes>(_onLoadMeditationTypes);
    on<SelectCategory>(_onSelectCategory);
    on<SelectAudio>(_onSelectAudio);
    on<PlayAudio>(_onPlayAudio);
    on<PauseAudio>(_onPauseAudio);
    on<StopAudio>(_onStopAudio);
    on<SetTimer>(_onSetTimer);
    on<ClearTimer>(_onClearTimer);
  }

  Future<void> _onLoadMeditationAudios(
      LoadMeditationAudios event, Emitter<MeditationState> emit) async {
    emit(MeditationLoading());
    try {
      final audios = repository.getAllAudios();
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

  Future<void> _onLoadMeditationTypes(
      LoadMeditationTypes event, Emitter<MeditationState> emit) async {
    emit(MeditationLoading());
    try {
      final audios = repository.getAllAudios();
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

  Future<void> _onSelectCategory(
      SelectCategory event, Emitter<MeditationState> emit) async {
    final currentState = state;
    if (currentState is MeditationLoaded) {
      emit(currentState.copyWith(selectedCategory: event.category));
    }
  }

  Future<void> _onSelectAudio(
      SelectAudio event, Emitter<MeditationState> emit) async {
    final currentState = state;
    if (currentState is MeditationLoaded) {
      final selectedAudio = repository.getAudioById(event.audioId);
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
