import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/events/models/home_models.dart';
import 'package:racketmates/common/events/models/schedule_models.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/screens/home/home_state.dart';

enum HomeSection { pending, upcoming, updates, activity, past }

class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() {
    // Start loading after the first build so `state` is initialised.
    Future.microtask(refresh);
    return const HomeState();
  }

  ScheduleRepository get _repo => ref.read(scheduleRepositoryProvider);

  List<String> get _userIds => ref.read(selectedUserIdsProvider);

  int get _hourFormat => ref.read(hourFormatProvider);

  /// Reloads every section (pull-to-refresh).
  Future<void> refresh() => Future.wait([
    reload(HomeSection.pending),
    reload(HomeSection.upcoming),
    reload(HomeSection.updates),
    reload(HomeSection.activity),
    reload(HomeSection.past),
  ]);

  Future<void> reload(HomeSection section) async {
    switch (section) {
      case HomeSection.pending:
        await _load<List<PendingAction>>(
          () => _repo.pendingActions(userIds: _userIds),
          (v) => state = state.copyWith(pending: v),
        );
      case HomeSection.upcoming:
        await _load<List<ScheduleItem>>(
          () => _repo.homeUpcoming(userIds: _userIds, hourFormat: _hourFormat),
          (v) => state = state.copyWith(upcoming: v),
        );
      case HomeSection.updates:
        await _load<List<PlayerCard>>(
          () => _repo.latestUpdates(userIds: _userIds),
          (v) => state = state.copyWith(updates: v),
        );
      case HomeSection.activity:
        await _load<List<HomePageStats>>(
          () => _repo.activitySummary(userIds: _userIds),
          (v) => state = state.copyWith(activity: v),
        );
      case HomeSection.past:
        await _load<List<ScheduleItem>>(
          () => _repo.homePast(userIds: _userIds, hourFormat: _hourFormat),
          (v) => state = state.copyWith(past: v),
        );
    }
  }

  /// Keeps stale data visible while refreshing; errors replace it.
  Future<void> _load<T>(
    Future<T> Function() fetch,
    void Function(AsyncValue<T>) set,
  ) async {
    try {
      final value = await fetch();
      if (ref.mounted) set(AsyncData(value));
    } on Object catch (error, stack) {
      if (ref.mounted) set(AsyncError(error, stack));
    }
  }
}

final homeViewModelProvider =
    NotifierProvider.autoDispose<HomeViewModel, HomeState>(HomeViewModel.new);
