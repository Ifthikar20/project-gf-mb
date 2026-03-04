import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/knowledge_repository.dart';
import 'knowledge_event.dart';
import 'knowledge_state.dart';

class KnowledgeBloc extends Bloc<KnowledgeEvent, KnowledgeState> {
  final KnowledgeRepository _repository;

  KnowledgeBloc({KnowledgeRepository? repository})
      : _repository = repository ?? KnowledgeRepository(),
        super(KnowledgeInitial()) {
    on<LoadKnowledge>(_onLoad);
    on<FilterByCategory>(_onFilter);
  }

  Future<void> _onLoad(
      LoadKnowledge event, Emitter<KnowledgeState> emit) async {
    emit(KnowledgeLoading());
    try {
      final articles = await _repository.getArticles();
      final tips = _repository.getTips();
      final tipOfTheDay = _repository.getTipOfTheDay();

      emit(KnowledgeLoaded(
        articles: articles,
        tips: tips,
        tipOfTheDay: tipOfTheDay,
      ));
    } catch (e) {
      emit(KnowledgeError('Failed to load content: $e'));
    }
  }

  void _onFilter(FilterByCategory event, Emitter<KnowledgeState> emit) {
    if (state is KnowledgeLoaded) {
      final current = state as KnowledgeLoaded;
      emit(KnowledgeLoaded(
        articles: current.articles,
        tips: current.tips,
        tipOfTheDay: current.tipOfTheDay,
        activeFilter: event.category,
      ));
    }
  }
}
