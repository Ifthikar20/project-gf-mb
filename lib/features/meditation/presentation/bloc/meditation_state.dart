import 'package:equatable/equatable.dart';
import '../../domain/entities/meditation_audio.dart';
import '../../domain/entities/meditation_type.dart';

abstract class MeditationState extends Equatable {
  const MeditationState();

  @override
  List<Object?> get props => [];
}

class MeditationInitial extends MeditationState {}

class MeditationLoading extends MeditationState {}

class MeditationLoaded extends MeditationState {
  final List<MeditationAudio> audios;
  final List<MeditationType> meditationTypes;
  final List<MeditationType> moodBasedTypes;
  final MeditationAudio? selectedAudio;
  final String selectedCategory;
  final bool isPlaying;
  final int? timerMinutes;

  const MeditationLoaded({
    required this.audios,
    required this.meditationTypes,
    required this.moodBasedTypes,
    this.selectedAudio,
    this.selectedCategory = 'All',
    this.isPlaying = false,
    this.timerMinutes,
  });

  MeditationLoaded copyWith({
    List<MeditationAudio>? audios,
    List<MeditationType>? meditationTypes,
    List<MeditationType>? moodBasedTypes,
    MeditationAudio? selectedAudio,
    String? selectedCategory,
    bool? isPlaying,
    int? timerMinutes,
    bool clearTimer = false,
  }) {
    return MeditationLoaded(
      audios: audios ?? this.audios,
      meditationTypes: meditationTypes ?? this.meditationTypes,
      moodBasedTypes: moodBasedTypes ?? this.moodBasedTypes,
      selectedAudio: selectedAudio ?? this.selectedAudio,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isPlaying: isPlaying ?? this.isPlaying,
      timerMinutes: clearTimer ? null : (timerMinutes ?? this.timerMinutes),
    );
  }

  /// Returns audios filtered by the selected category
  List<MeditationAudio> get filteredAudios {
    if (selectedCategory == 'All') {
      return audios;
    }
    return audios.where((audio) => 
      audio.category.toLowerCase() == selectedCategory.toLowerCase()
    ).toList();
  }

  @override
  List<Object?> get props => [
        audios,
        meditationTypes,
        moodBasedTypes,
        selectedAudio,
        selectedCategory,
        isPlaying,
        timerMinutes,
      ];
}

class MeditationError extends MeditationState {
  final String message;

  const MeditationError(this.message);

  @override
  List<Object?> get props => [message];
}
