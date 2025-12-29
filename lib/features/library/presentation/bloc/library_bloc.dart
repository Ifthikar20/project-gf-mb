import 'package:flutter_bloc/flutter_bloc.dart';
import 'library_event.dart';
import 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  LibraryBloc() : super(const LibraryLoaded(savedIds: {}, items: [])) {
    on<LoadLibrary>(_onLoadLibrary);
    on<AddToLibrary>(_onAddToLibrary);
    on<RemoveFromLibrary>(_onRemoveFromLibrary);
    on<ToggleLibraryItem>(_onToggleLibraryItem);
  }

  void _onLoadLibrary(LoadLibrary event, Emitter<LibraryState> emit) {
    // Library is already loaded in memory, this is for future persistence
    final currentState = state;
    if (currentState is LibraryLoaded) {
      emit(currentState);
    } else {
      emit(const LibraryLoaded(savedIds: {}, items: []));
    }
  }

  void _onAddToLibrary(AddToLibrary event, Emitter<LibraryState> emit) {
    final currentState = state;
    if (currentState is LibraryLoaded) {
      final newSavedIds = Set<String>.from(currentState.savedIds)
        ..add(event.contentId);
      final newItems = List<LibraryItem>.from(currentState.items)
        ..add(LibraryItem(
          id: event.contentId,
          type: event.contentType,
          addedAt: DateTime.now(),
        ));
      emit(currentState.copyWith(savedIds: newSavedIds, items: newItems));
    }
  }

  void _onRemoveFromLibrary(RemoveFromLibrary event, Emitter<LibraryState> emit) {
    final currentState = state;
    if (currentState is LibraryLoaded) {
      final newSavedIds = Set<String>.from(currentState.savedIds)
        ..remove(event.contentId);
      final newItems = currentState.items
          .where((item) => item.id != event.contentId)
          .toList();
      emit(currentState.copyWith(savedIds: newSavedIds, items: newItems));
    }
  }

  void _onToggleLibraryItem(ToggleLibraryItem event, Emitter<LibraryState> emit) {
    final currentState = state;
    if (currentState is LibraryLoaded) {
      if (currentState.savedIds.contains(event.contentId)) {
        add(RemoveFromLibrary(contentId: event.contentId));
      } else {
        add(AddToLibrary(contentId: event.contentId, contentType: event.contentType));
      }
    }
  }

  // Helper method to check if item is saved
  bool isSaved(String contentId) {
    final currentState = state;
    if (currentState is LibraryLoaded) {
      return currentState.savedIds.contains(contentId);
    }
    return false;
  }
}
