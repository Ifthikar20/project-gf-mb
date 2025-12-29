import 'package:equatable/equatable.dart';

class MeditationAudio extends Equatable {
  final String id;
  final String title;
  final String description;
  final String audioPath;
  final int durationInSeconds;
  final String category;
  final String imageUrl;

  const MeditationAudio({
    required this.id,
    required this.title,
    required this.description,
    required this.audioPath,
    required this.durationInSeconds,
    required this.category,
    required this.imageUrl,
  });

  String get formattedDuration {
    final minutes = durationInSeconds ~/ 60;
    final seconds = durationInSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        audioPath,
        durationInSeconds,
        category,
        imageUrl,
      ];
}
