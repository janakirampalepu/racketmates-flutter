import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/events/models/home_models.dart';
import 'package:racketmates/common/events/models/schedule_models.dart';

/// Each home section loads independently so one failing request does not
/// blank the whole screen. "Latest updates" and "recent games" are left out:
/// neither native app currently fetches or shows them (see the Home rebuild
/// notes in CLAUDE.md).
class HomeState {
  const HomeState({
    this.pending = const AsyncLoading(),
    this.upcoming = const AsyncLoading(),
    this.activity = const AsyncLoading(),
  });

  final AsyncValue<List<PendingAction>> pending;
  final AsyncValue<List<ScheduleItem>> upcoming;
  final AsyncValue<List<HomePageStats>> activity;

  HomeState copyWith({
    AsyncValue<List<PendingAction>>? pending,
    AsyncValue<List<ScheduleItem>>? upcoming,
    AsyncValue<List<HomePageStats>>? activity,
  }) => HomeState(
    pending: pending ?? this.pending,
    upcoming: upcoming ?? this.upcoming,
    activity: activity ?? this.activity,
  );
}
