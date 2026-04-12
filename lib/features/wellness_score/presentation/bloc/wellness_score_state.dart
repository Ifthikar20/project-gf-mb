import 'package:equatable/equatable.dart';
import '../../domain/entities/wellness_score.dart';

abstract class WellnessScoreState extends Equatable {
  const WellnessScoreState();
  @override
  List<Object?> get props => [];
}

class WellnessScoreInitial extends WellnessScoreState {
  const WellnessScoreInitial();
}

class WellnessScoreLoading extends WellnessScoreState {
  const WellnessScoreLoading();
}

class WellnessScoreLoaded extends WellnessScoreState {
  final WellnessScore score;
  final List<DailyScoreSnapshot> history;

  const WellnessScoreLoaded({
    required this.score,
    this.history = const [],
  });

  @override
  List<Object?> get props => [score.totalScore, score.date, history.length];

  WellnessScoreLoaded copyWith({
    WellnessScore? score,
    List<DailyScoreSnapshot>? history,
  }) {
    return WellnessScoreLoaded(
      score: score ?? this.score,
      history: history ?? this.history,
    );
  }
}

class WellnessScoreError extends WellnessScoreState {
  final String message;
  const WellnessScoreError(this.message);
  @override
  List<Object?> get props => [message];
}
