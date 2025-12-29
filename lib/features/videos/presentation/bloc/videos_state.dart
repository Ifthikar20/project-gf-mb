import 'package:equatable/equatable.dart';
import '../../domain/entities/video_entity.dart';

abstract class VideosState extends Equatable {
  const VideosState();

  @override
  List<Object?> get props => [];
}

class VideosInitial extends VideosState {}

class VideosLoading extends VideosState {}

class VideosLoaded extends VideosState {
  final List<VideoEntity> videos;
  final String? currentCategory;

  const VideosLoaded(this.videos, {this.currentCategory});

  @override
  List<Object?> get props => [videos, currentCategory];
}

class VideosError extends VideosState {
  final String message;

  const VideosError(this.message);

  @override
  List<Object?> get props => [message];
}
