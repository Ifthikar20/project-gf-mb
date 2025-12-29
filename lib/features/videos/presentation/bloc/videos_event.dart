import 'package:equatable/equatable.dart';
import '../../domain/entities/video_entity.dart';

abstract class VideosEvent extends Equatable {
  const VideosEvent();

  @override
  List<Object?> get props => [];
}

class LoadVideos extends VideosEvent {
  final String? category;

  const LoadVideos({this.category});

  @override
  List<Object?> get props => [category];
}

class FilterVideosByCategory extends VideosEvent {
  final String category;

  const FilterVideosByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class SearchVideos extends VideosEvent {
  final String query;

  const SearchVideos(this.query);

  @override
  List<Object?> get props => [query];
}
