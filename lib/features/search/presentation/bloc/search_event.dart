import 'package:equatable/equatable.dart';

/// Base class for search events
abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

/// Event when search query changes
class SearchQueryChanged extends SearchEvent {
  final String query;

  const SearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Event when content type filter changes
class SearchContentTypeChanged extends SearchEvent {
  final String contentType;

  const SearchContentTypeChanged(this.contentType);

  @override
  List<Object?> get props => [contentType];
}

/// Event when category filter changes
class SearchCategoryChanged extends SearchEvent {
  final String? category;

  const SearchCategoryChanged(this.category);

  @override
  List<Object?> get props => [category];
}

/// Event when tags filter changes
class SearchTagsChanged extends SearchEvent {
  final List<String> tags;

  const SearchTagsChanged(this.tags);

  @override
  List<Object?> get props => [tags];
}

/// Event to clear search
class SearchCleared extends SearchEvent {
  const SearchCleared();
}

/// Event to perform search with current filters
class SearchSubmitted extends SearchEvent {
  const SearchSubmitted();
}

/// Event to toggle unified search mode
class SearchUnifiedModeToggled extends SearchEvent {
  final bool enabled;
  
  const SearchUnifiedModeToggled(this.enabled);
  
  @override
  List<Object?> get props => [enabled];
}

/// Event to request autocomplete suggestions
class SearchSuggestionsRequested extends SearchEvent {
  final String query;
  
  const SearchSuggestionsRequested(this.query);
  
  @override
  List<Object?> get props => [query];
}

/// Event to clear suggestions
class SearchSuggestionsCleared extends SearchEvent {
  const SearchSuggestionsCleared();
}

