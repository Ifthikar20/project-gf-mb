import 'package:equatable/equatable.dart';

abstract class SleepEvent extends Equatable {
  const SleepEvent();
  @override
  List<Object?> get props => [];
}

class SleepLoadRequested extends SleepEvent {
  const SleepLoadRequested();
}
