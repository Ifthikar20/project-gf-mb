import 'package:equatable/equatable.dart';

abstract class MeditationEvent extends Equatable {
  const MeditationEvent();

  @override
  List<Object?> get props => [];
}

class LoadMeditationAudios extends MeditationEvent {}

class LoadMeditationTypes extends MeditationEvent {}

/// Force refresh from API (for pull-to-refresh)
class RefreshMeditationAudios extends MeditationEvent {}

class SelectCategory extends MeditationEvent {
  final String category;

  const SelectCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class SelectAudio extends MeditationEvent {
  final String audioId;

  const SelectAudio(this.audioId);

  @override
  List<Object?> get props => [audioId];
}

class PlayAudio extends MeditationEvent {}

class PauseAudio extends MeditationEvent {}

class StopAudio extends MeditationEvent {}

class SetTimer extends MeditationEvent {
  final int minutes;

  const SetTimer(this.minutes);

  @override
  List<Object?> get props => [minutes];
}

class ClearTimer extends MeditationEvent {}
