import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/events/models/home_models.dart';
import 'package:racketmates/common/events/models/schedule_models.dart';

/// Each home section loads independently so one failing request does not blank
/// the whole screen.
class HomeState {
  const HomeState({
    this.pending = const AsyncLoading(),
    this.upcoming = const AsyncLoading(),
    this.updates = const AsyncLoading(),
    this.activity = const AsyncLoading(),
    this.past = const AsyncLoading(),
  });

  final AsyncValue<List<PendingAction>> pending;
  final AsyncValue<List<ScheduleItem>> upcoming;
  final AsyncValue<List<PlayerCard>> updates;
  final AsyncValue<List<HomePageStats>> activity;
  final AsyncValue<List<ScheduleItem>> past;

  HomeState copyWith({
    AsyncValue<List<PendingAction>>? pending,
    AsyncValue<List<ScheduleItem>>? upcoming,
    AsyncValue<List<PlayerCard>>? updates,
    AsyncValue<List<HomePageStats>>? activity,
    AsyncValue<List<ScheduleItem>>? past,
  }) => HomeState(
    pending: pending ?? this.pending,
    upcoming: upcoming ?? this.upcoming,
    updates: updates ?? this.updates,
    activity: activity ?? this.activity,
    past: past ?? this.past,
  );
}
