import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/class_schedule_service.dart';
import '../../../videos/presentation/bloc/videos_bloc.dart';
import '../../../videos/presentation/bloc/videos_state.dart';
import '../../data/models/scheduled_class_model.dart';
import 'class_schedule_event.dart';
import 'class_schedule_state.dart';

class ClassScheduleBloc
    extends Bloc<ClassScheduleEvent, ClassScheduleState> {
  final ClassScheduleService _service;
  final VideosBloc _videosBloc;

  ClassScheduleBloc({
    ClassScheduleService? service,
    required VideosBloc videosBloc,
  })  : _service = service ?? ClassScheduleService(),
        _videosBloc = videosBloc,
        super(ClassScheduleInitial()) {
    on<LoadClasses>(_onLoadClasses);
    on<SetClassReminder>(_onSetReminder);
    on<CancelClassReminder>(_onCancelReminder);
  }

  Future<void> _onLoadClasses(
      LoadClasses event, Emitter<ClassScheduleState> emit) async {
    emit(ClassScheduleLoading());
    try {
      // Try backend first
      final classes = await _service.getClassesForDate(event.date);
      if (classes.isNotEmpty) {
        emit(ClassScheduleLoaded(
          classes: classes,
          selectedDate: event.date,
        ));
        return;
      }

      // Fallback: generate mock schedule from videos
      final mockClasses = _generateMockSchedule(event.date);
      emit(ClassScheduleLoaded(
        classes: mockClasses,
        selectedDate: event.date,
        usingFallback: true,
      ));
    } catch (e) {
      final mockClasses = _generateMockSchedule(event.date);
      emit(ClassScheduleLoaded(
        classes: mockClasses,
        selectedDate: event.date,
        usingFallback: true,
      ));
    }
  }

  Future<void> _onSetReminder(
      SetClassReminder event, Emitter<ClassScheduleState> emit) async {
    if (state is! ClassScheduleLoaded) return;
    final current = state as ClassScheduleLoaded;

    // Optimistic update
    final updated = current.classes.map((c) {
      if (c.id == event.classId) {
        return c.copyWithReminder(hasReminder: true, reminderId: 'pending');
      }
      return c;
    }).toList();
    emit(ClassScheduleLoaded(
      classes: updated,
      selectedDate: current.selectedDate,
      usingFallback: current.usingFallback,
    ));

    // Call API (only if not using fallback)
    if (!current.usingFallback) {
      final reminderId = await _service.setReminder(
        classId: event.classId,
        remindMinutesBefore: event.remindMinutesBefore,
      );
      if (reminderId != null) {
        final confirmed = updated.map((c) {
          if (c.id == event.classId) {
            return c.copyWithReminder(
                hasReminder: true, reminderId: reminderId);
          }
          return c;
        }).toList();
        emit(ClassScheduleLoaded(
          classes: confirmed,
          selectedDate: current.selectedDate,
          usingFallback: current.usingFallback,
        ));
      }
    }
  }

  Future<void> _onCancelReminder(
      CancelClassReminder event, Emitter<ClassScheduleState> emit) async {
    if (state is! ClassScheduleLoaded) return;
    final current = state as ClassScheduleLoaded;

    // Optimistic update
    final updated = current.classes.map((c) {
      if (c.id == event.classId) {
        return c.copyWithReminder(hasReminder: false, reminderId: null);
      }
      return c;
    }).toList();
    emit(ClassScheduleLoaded(
      classes: updated,
      selectedDate: current.selectedDate,
      usingFallback: current.usingFallback,
    ));

    // Call API
    if (!current.usingFallback) {
      await _service.cancelReminder(event.reminderId);
    }
  }

  /// Generate mock classes from video content (fallback when API unavailable)
  List<ScheduledClassModel> _generateMockSchedule(DateTime date) {
    final videosState = _videosBloc.state;
    if (videosState is! VideosLoaded) return [];

    final videos = videosState.videos;
    final rng = Random(date.day * 100 + date.month);
    final List<ScheduledClassModel> classes = [];

    final morningTimes = [6, 7, 9, 10];
    final afternoonTimes = [12, 13, 14, 15, 16];

    for (int i = 0; i < videos.length && i < 6; i++) {
      final video = videos[i];
      final isMorning = i < 3;
      final hours = isMorning ? morningTimes : afternoonTimes;
      final hour = hours[rng.nextInt(hours.length)];
      final minute = rng.nextBool() ? 0 : 30;
      final durationMin =
          video.durationInSeconds > 0 ? video.durationInSeconds ~/ 60 : 30;

      classes.add(ScheduledClassModel(
        id: '${video.id}_${date.day}',
        title: video.title,
        instructor:
            video.instructor.isNotEmpty ? video.instructor : 'Guest Teacher',
        category: video.category.isNotEmpty ? video.category : 'Wellness',
        level: 'Level ${rng.nextInt(2) + 1}',
        scheduledAt: DateTime(date.year, date.month, date.day, hour, minute),
        durationMinutes: durationMin,
        thumbnailUrl: video.thumbnailUrl,
        videoId: video.id,
        signedUpCount: rng.nextInt(25) + 3,
      ));
    }

    classes.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return classes;
  }
}
