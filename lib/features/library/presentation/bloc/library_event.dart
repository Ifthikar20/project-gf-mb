import 'package:equatable/equatable.dart';

abstract class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => [];
}

class LoadLibrary extends LibraryEvent {}

class AddToLibrary extends LibraryEvent {
  final String contentId;
  final String contentType; // 'video' or 'audio'

  const AddToLibrary({required this.contentId, required this.contentType});

  @override
  List<Object?> get props => [contentId, contentType];
}

class RemoveFromLibrary extends LibraryEvent {
  final String contentId;

  const RemoveFromLibrary({required this.contentId});

  @override
  List<Object?> get props => [contentId];
}

class ToggleLibraryItem extends LibraryEvent {
  final String contentId;
  final String contentType;

  const ToggleLibraryItem({required this.contentId, required this.contentType});

  @override
  List<Object?> get props => [contentId, contentType];
}
