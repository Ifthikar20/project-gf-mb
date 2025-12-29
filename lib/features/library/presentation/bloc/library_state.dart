import 'package:equatable/equatable.dart';

class LibraryItem {
  final String id;
  final String type; // 'video' or 'audio'
  final DateTime addedAt;

  const LibraryItem({
    required this.id,
    required this.type,
    required this.addedAt,
  });
}

abstract class LibraryState extends Equatable {
  const LibraryState();

  @override
  List<Object?> get props => [];
}

class LibraryInitial extends LibraryState {}

class LibraryLoading extends LibraryState {}

class LibraryLoaded extends LibraryState {
  final Set<String> savedIds;
  final List<LibraryItem> items;

  const LibraryLoaded({
    required this.savedIds,
    required this.items,
  });

  bool isSaved(String contentId) => savedIds.contains(contentId);

  @override
  List<Object?> get props => [savedIds, items];

  LibraryLoaded copyWith({
    Set<String>? savedIds,
    List<LibraryItem>? items,
  }) {
    return LibraryLoaded(
      savedIds: savedIds ?? this.savedIds,
      items: items ?? this.items,
    );
  }
}

class LibraryError extends LibraryState {
  final String message;

  const LibraryError(this.message);

  @override
  List<Object?> get props => [message];
}
