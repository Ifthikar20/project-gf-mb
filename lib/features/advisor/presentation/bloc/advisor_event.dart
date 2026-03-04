import 'package:equatable/equatable.dart';

abstract class AdvisorEvent extends Equatable {
  const AdvisorEvent();
  @override
  List<Object?> get props => [];
}

/// Load suggestions (checks cache first)
class LoadSuggestions extends AdvisorEvent {}

/// Force refresh from API / rules
class RefreshSuggestions extends AdvisorEvent {}

/// Dismiss a specific suggestion
class DismissSuggestion extends AdvisorEvent {
  final String suggestionId;
  const DismissSuggestion({required this.suggestionId});
  @override
  List<Object?> get props => [suggestionId];
}
