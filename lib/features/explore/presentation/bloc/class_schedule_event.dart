import 'package:equatable/equatable.dart';

abstract class ClassScheduleEvent extends Equatable {
  const ClassScheduleEvent();
  @override
  List<Object?> get props => [];
}

/// Load classes for a specific date
class LoadClasses extends ClassScheduleEvent {
  final DateTime date;
  const LoadClasses({required this.date});
  @override
  List<Object?> get props => [date];
}

/// Set a reminder for a class
class SetClassReminder extends ClassScheduleEvent {
  final String classId;
  final int remindMinutesBefore;
  const SetClassReminder({
    required this.classId,
    this.remindMinutesBefore = 15,
  });
  @override
  List<Object?> get props => [classId, remindMinutesBefore];
}

/// Cancel a reminder
class CancelClassReminder extends ClassScheduleEvent {
  final String classId;
  final String reminderId;
  const CancelClassReminder({
    required this.classId,
    required this.reminderId,
  });
  @override
  List<Object?> get props => [classId, reminderId];
}
