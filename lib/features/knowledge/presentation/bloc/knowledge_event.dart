import 'package:equatable/equatable.dart';

abstract class KnowledgeEvent extends Equatable {
  const KnowledgeEvent();
  @override
  List<Object?> get props => [];
}

class LoadKnowledge extends KnowledgeEvent {}

class FilterByCategory extends KnowledgeEvent {
  final String? category; // null = show all
  const FilterByCategory({this.category});
  @override
  List<Object?> get props => [category];
}
