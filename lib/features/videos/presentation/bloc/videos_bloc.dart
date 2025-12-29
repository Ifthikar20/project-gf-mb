import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/videos_repository.dart';
import 'videos_event.dart';
import 'videos_state.dart';

class VideosBloc extends Bloc<VideosEvent, VideosState> {
  final VideosRepository repository;

  VideosBloc({required this.repository}) : super(VideosInitial()) {
    on<LoadVideos>(_onLoadVideos);
    on<FilterVideosByCategory>(_onFilterVideosByCategory);
    on<SearchVideos>(_onSearchVideos);
  }

  Future<void> _onLoadVideos(LoadVideos event, Emitter<VideosState> emit) async {
    emit(VideosLoading());
    try {
      final videos = await repository.getVideos(category: event.category);
      emit(VideosLoaded(videos, currentCategory: event.category));
    } catch (e) {
      emit(VideosError(e.toString()));
    }
  }

  Future<void> _onFilterVideosByCategory(
      FilterVideosByCategory event, Emitter<VideosState> emit) async {
    emit(VideosLoading());
    try {
      final videos = await repository.getVideos(
        category: event.category == 'All' ? null : event.category,
      );
      emit(VideosLoaded(videos, currentCategory: event.category));
    } catch (e) {
      emit(VideosError(e.toString()));
    }
  }

  Future<void> _onSearchVideos(
      SearchVideos event, Emitter<VideosState> emit) async {
    try {
      final currentState = state;
      if (currentState is VideosLoaded) {
        final allVideos = await repository.getVideos();
        final filteredVideos = allVideos.where((video) {
          return video.title.toLowerCase().contains(event.query.toLowerCase()) ||
              video.description.toLowerCase().contains(event.query.toLowerCase());
        }).toList();
        emit(VideosLoaded(filteredVideos, currentCategory: currentState.currentCategory));
      }
    } catch (e) {
      emit(VideosError(e.toString()));
    }
  }
}
