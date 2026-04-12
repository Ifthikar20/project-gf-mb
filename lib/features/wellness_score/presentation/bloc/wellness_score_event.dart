import 'package:equatable/equatable.dart';

abstract class WellnessScoreEvent extends Equatable {
  const WellnessScoreEvent();
  @override
  List<Object?> get props => [];
}

/// Load/refresh today's wellness score.
class WellnessScoreLoadRequested extends WellnessScoreEvent {
  const WellnessScoreLoadRequested();
}

/// Load score history for trend chart.
class WellnessScoreHistoryRequested extends WellnessScoreEvent {
  final int days;
  const WellnessScoreHistoryRequested({this.days = 30});
  @override
  List<Object?> get props => [days];
}
