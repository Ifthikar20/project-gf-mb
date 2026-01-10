import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/search_service.dart';
import 'search_event.dart';
import 'search_state.dart';

/// BLoC for handling search functionality with secure input handling
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchService _searchService;
  Timer? _debounceTimer;
  
  // Current filter values
  String _currentQuery = '';
  String _currentContentType = 'all';
  String? _currentCategory;
  List<String> _currentTags = [];

  SearchBloc({SearchService? searchService})
      : _searchService = searchService ?? SearchService(),
        super(const SearchInitial()) {
    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchContentTypeChanged>(_onContentTypeChanged);
    on<SearchCategoryChanged>(_onCategoryChanged);
    on<SearchTagsChanged>(_onTagsChanged);
    on<SearchCleared>(_onCleared);
    on<SearchSubmitted>(_onSubmitted);
  }

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    _currentQuery = event.query;
    
    // Cancel previous debounce timer
    _debounceTimer?.cancel();
    
    if (event.query.isEmpty) {
      emit(const SearchInitial());
      return;
    }

    // Debounce search by 300ms
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
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
    _currentQuery = '';
    _currentTags = [];
    emit(const SearchInitial());
  }

  Future<void> _onSubmitted(
    SearchSubmitted event,
    Emitter<SearchState> emit,
  ) async {
    if (_currentQuery.isEmpty) {
      emit(const SearchInitial());
      return;
    }

    emit(SearchLoading(
      query: _currentQuery,
      contentType: _currentContentType,
      category: _currentCategory,
      tags: _currentTags,
    ));

    try {
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
      ));
    } catch (e) {
      emit(SearchError(
        message: 'Failed to search: ${e.toString()}',
        query: _currentQuery,
        contentType: _currentContentType,
        category: _currentCategory,
        tags: _currentTags,
      ));
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}

