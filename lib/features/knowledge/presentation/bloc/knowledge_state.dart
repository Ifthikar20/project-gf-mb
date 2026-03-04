import 'package:equatable/equatable.dart';
import '../../data/models/knowledge_models.dart';

abstract class KnowledgeState extends Equatable {
  const KnowledgeState();
  @override
  List<Object?> get props => [];
}

class KnowledgeInitial extends KnowledgeState {}

class KnowledgeLoading extends KnowledgeState {}

class KnowledgeLoaded extends KnowledgeState {
  final List<Article> articles;
  final List<WellnessTip> tips;
  final WellnessTip tipOfTheDay;
  final String? activeFilter; // null = all

  const KnowledgeLoaded({
    required this.articles,
    required this.tips,
    required this.tipOfTheDay,
    this.activeFilter,
  });

  /// Filtered articles based on active category
  List<Article> get filteredArticles {
    if (activeFilter == null) return articles;
    return articles.where((a) => a.category == activeFilter).toList();
  }

  @override
  List<Object?> get props => [articles, tips, tipOfTheDay, activeFilter];
}

class KnowledgeError extends KnowledgeState {
  final String message;
  const KnowledgeError(this.message);
  @override
  List<Object?> get props => [message];
}
