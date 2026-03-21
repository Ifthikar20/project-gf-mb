import 'package:equatable/equatable.dart';
import '../../data/models/scheduled_class_model.dart';

abstract class ClassScheduleState extends Equatable {
  const ClassScheduleState();
  @override
  List<Object?> get props => [];
}

class ClassScheduleInitial extends ClassScheduleState {}

class ClassScheduleLoading extends ClassScheduleState {}

class ClassScheduleLoaded extends ClassScheduleState {
  final List<ScheduledClassModel> classes;
  final DateTime selectedDate;
  final bool usingFallback; // true if API unavailable, using mock data

  const ClassScheduleLoaded({
    required this.classes,
    required this.selectedDate,
    this.usingFallback = false,
  });

  List<ScheduledClassModel> get morningClasses =>
      classes.where((c) => c.isMorning).toList();

  List<ScheduledClassModel> get afternoonClasses =>
      classes.where((c) => !c.isMorning).toList();

  @override
  List<Object?> get props => [classes, selectedDate, usingFallback];
}

class ClassScheduleError extends ClassScheduleState {
  final String message;
  const ClassScheduleError(this.message);
  @override
  List<Object?> get props => [message];
}
