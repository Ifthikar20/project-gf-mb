import 'package:equatable/equatable.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/entities/unified_search_result.dart';

/// Base class for search states
abstract class SearchState extends Equatable {
  final String query;
  final String contentType;
  final String? category;
  final List<String> tags;
  final List<SearchSuggestion> suggestions;
  final bool isUnifiedMode;

  const SearchState({
    this.query = '',
    this.contentType = 'all',
    this.category,
    this.tags = const [],
    this.suggestions = const [],
    this.isUnifiedMode = true,
  });

  @override
  List<Object?> get props => [query, contentType, category, tags, suggestions, isUnifiedMode];
}

/// Initial state - no search performed yet
class SearchInitial extends SearchState {
  const SearchInitial({
    super.suggestions,
    super.isUnifiedMode = true,
  });
}

/// Loading state while searching
class SearchLoading extends SearchState {
  const SearchLoading({
    required String query,
    required String contentType,
    String? category,
    List<String> tags = const [],
    super.suggestions,
    super.isUnifiedMode = true,
  }) : super(
          query: query,
          contentType: contentType,
          category: category,
          tags: tags,
        );
}

/// State when legacy search results are loaded
class SearchLoaded extends SearchState {
  final List<SearchResult> results;

  const SearchLoaded({
    required this.results,
    required String query,
    required String contentType,
    String? category,
    List<String> tags = const [],
    super.suggestions,
    super.isUnifiedMode = true,
  }) : super(
          query: query,
          contentType: contentType,
          category: category,
          tags: tags,
        );

  @override
  List<Object?> get props => [...super.props, results];
}

/// State when unified search results are loaded (grouped by type)
class SearchUnifiedLoaded extends SearchState {
  final UnifiedSearchResult unifiedResult;

  const SearchUnifiedLoaded({
    required this.unifiedResult,
    required String query,
    required String contentType,
    String? category,
    List<String> tags = const [],
    super.suggestions,
    super.isUnifiedMode = true,
  }) : super(
          query: query,
          contentType: contentType,
          category: category,
          tags: tags,
        );

  @override
  List<Object?> get props => [...super.props, unifiedResult];
}

/// Error state
class SearchError extends SearchState {
  final String message;

  const SearchError({
    required this.message,
    required String query,
    required String contentType,
    String? category,
    List<String> tags = const [],
    super.suggestions,
    super.isUnifiedMode = true,
  }) : super(
          query: query,
          contentType: contentType,
          category: category,
          tags: tags,
        );

  @override
  List<Object?> get props => [...super.props, message];
}

