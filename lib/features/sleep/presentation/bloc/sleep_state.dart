import 'package:equatable/equatable.dart';
import '../../domain/entities/sleep_data.dart';

abstract class SleepState extends Equatable {
  const SleepState();
  @override
  List<Object?> get props => [];
}

class SleepInitial extends SleepState {
  const SleepInitial();
}

class SleepLoading extends SleepState {
  const SleepLoading();
}

class SleepLoaded extends SleepState {
  final SleepScore sleepScore;
  final List<SleepInsight> insights;

  const SleepLoaded({
    required this.sleepScore,
    this.insights = const [],
  });

  @override
  List<Object?> get props => [sleepScore.score, insights.length];
}

class SleepError extends SleepState {
  final String message;
  const SleepError(this.message);
  @override
  List<Object?> get props => [message];
}
