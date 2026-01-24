import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/search_service.dart';
import '../../domain/entities/unified_search_result.dart';
import 'search_event.dart';
import 'search_state.dart';

/// BLoC for handling search functionality with secure input handling
/// 
/// Supports both legacy flat results and unified grouped results (Spotify/YouTube style)
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchService _searchService;
  Timer? _debounceTimer;
  Timer? _suggestionTimer;
  
  // Current filter values
  String _currentQuery = '';
  String _currentContentType = 'all';
  String? _currentCategory;
  List<String> _currentTags = [];
  List<SearchSuggestion> _currentSuggestions = [];
  bool _isUnifiedMode = true; // Default to unified search

  SearchBloc({SearchService? searchService})
      : _searchService = searchService ?? SearchService(),
        super(const SearchInitial()) {
    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchContentTypeChanged>(_onContentTypeChanged);
    on<SearchCategoryChanged>(_onCategoryChanged);
    on<SearchTagsChanged>(_onTagsChanged);
    on<SearchCleared>(_onCleared);
    on<SearchSubmitted>(_onSubmitted);
    on<SearchUnifiedModeToggled>(_onUnifiedModeToggled);
    on<SearchSuggestionsRequested>(_onSuggestionsRequested);
    on<SearchSuggestionsCleared>(_onSuggestionsCleared);
  }

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    _currentQuery = event.query;
    
    // Cancel previous timers
    _debounceTimer?.cancel();
    _suggestionTimer?.cancel();
    
    if (event.query.isEmpty) {
      _currentSuggestions = [];
      emit(const SearchInitial());
      return;
    }

    // Fetch suggestions quickly (150ms debounce)
    _suggestionTimer = Timer(const Duration(milliseconds: 150), () {
      add(SearchSuggestionsRequested(event.query));
    });

    // Debounce search by 400ms
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      add(const SearchSubmitted());
    });
  }

  Future<void> _onContentTypeChanged(
    SearchContentTypeChanged event,
    Emitter<SearchState> emit,
  ) async {
    _currentContentType = event.contentType;
    
    // Re-search if there's a query
    if (_currentQuery.isNotEmpty) {
      add(const SearchSubmitted());
    }
  }

  Future<void> _onCategoryChanged(
    SearchCategoryChanged event,
    Emitter<SearchState> emit,
  ) async {
    _currentCategory = event.category;
    
    // Re-search if there's a query
    if (_currentQuery.isNotEmpty) {
      add(const SearchSubmitted());
    }
  }

  Future<void> _onTagsChanged(
    SearchTagsChanged event,
    Emitter<SearchState> emit,
  ) async {
    _currentTags = event.tags;
    
    // Re-search if there's a query
    if (_currentQuery.isNotEmpty) {
      add(const SearchSubmitted());
    }
  }

  Future<void> _onCleared(
    SearchCleared event,
    Emitter<SearchState> emit,
  ) async {
    _debounceTimer?.cancel();
    _suggestionTimer?.cancel();
    _currentQuery = '';
    _currentTags = [];
    _currentSuggestions = [];
    emit(SearchInitial(isUnifiedMode: _isUnifiedMode));
  }

  Future<void> _onUnifiedModeToggled(
    SearchUnifiedModeToggled event,
    Emitter<SearchState> emit,
  ) async {
    _isUnifiedMode = event.enabled;
    
    // Re-search if there's a query
    if (_currentQuery.isNotEmpty) {
      add(const SearchSubmitted());
    }
  }

  Future<void> _onSuggestionsRequested(
    SearchSuggestionsRequested event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.length < 2) {
      return;
    }

    try {
      final suggestions = await _searchService.getSuggestions(query: event.query);
      _currentSuggestions = suggestions;
      
      // If we're still in an initial/loading state, emit with updated suggestions
      if (state is SearchInitial || state is SearchLoading) {
        // Don't change state type, just update suggestions in next state
      }
    } catch (_) {
      // Silently ignore suggestion errors
    }
  }

  Future<void> _onSuggestionsCleared(
    SearchSuggestionsCleared event,
    Emitter<SearchState> emit,
  ) async {
    _currentSuggestions = [];
  }

  Future<void> _onSubmitted(
    SearchSubmitted event,
    Emitter<SearchState> emit,
  ) async {
    if (_currentQuery.isEmpty) {
      emit(SearchInitial(isUnifiedMode: _isUnifiedMode));
      return;
    }

    emit(SearchLoading(
      query: _currentQuery,
      contentType: _currentContentType,
      category: _currentCategory,
      tags: _currentTags,
      suggestions: _currentSuggestions,
      isUnifiedMode: _isUnifiedMode,
    ));

    try {
      if (_isUnifiedMode) {
        // Use unified search (Spotify/YouTube style)
        final unifiedResult = await _searchService.unifiedSearch(
          query: _currentQuery,
        );

        emit(SearchUnifiedLoaded(
          unifiedResult: unifiedResult,
          query: _currentQuery,
          contentType: _currentContentType,
          category: _currentCategory,
          tags: _currentTags,
          suggestions: _currentSuggestions,
          isUnifiedMode: _isUnifiedMode,
        ));
      } else {
        // Use legacy flat search
        final results = await _searchService.search(
          query: _currentQuery,
          contentType: _currentContentType,
          category: _currentCategory,
          tags: _currentTags.isEmpty ? null : _currentTags,
        );

        emit(SearchLoaded(
          results: results,
          query: _currentQuery,
          contentType: _currentContentType,
          category: _currentCategory,
          tags: _currentTags,
          suggestions: _currentSuggestions,
          isUnifiedMode: _isUnifiedMode,
        ));
      }
    } catch (e) {
      emit(SearchError(
        message: 'Failed to search: ${e.toString()}',
        query: _currentQuery,
        contentType: _currentContentType,
        category: _currentCategory,
        tags: _currentTags,
        suggestions: _currentSuggestions,
        isUnifiedMode: _isUnifiedMode,
      ));
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _suggestionTimer?.cancel();
    return super.close();
  }
}

