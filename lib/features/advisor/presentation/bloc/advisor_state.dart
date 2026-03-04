import 'package:equatable/equatable.dart';
import '../../../../core/services/models/wellness_suggestion_model.dart';

abstract class AdvisorState extends Equatable {
  const AdvisorState();
  @override
  List<Object?> get props => [];
}

class AdvisorInitial extends AdvisorState {}

class AdvisorLoading extends AdvisorState {}

class AdvisorLoaded extends AdvisorState {
  final List<WellnessSuggestion> suggestions;
  final Set<String> dismissedIds;

  const AdvisorLoaded({
    required this.suggestions,
    this.dismissedIds = const {},
  });

  /// Visible suggestions (excluding dismissed ones)
  List<WellnessSuggestion> get visibleSuggestions =>
      suggestions.where((s) => !dismissedIds.contains(s.id)).toList();

  @override
  List<Object?> get props => [suggestions, dismissedIds];
}

class AdvisorError extends AdvisorState {
  final String message;
  const AdvisorError(this.message);
  @override
  List<Object?> get props => [message];
}
