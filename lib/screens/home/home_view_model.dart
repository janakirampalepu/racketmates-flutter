import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/events/models/home_models.dart';
import 'package:racketmates/common/events/models/schedule_models.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/common/startup/downtime.dart';
import 'package:racketmates/screens/home/home_state.dart';

enum HomeSection { pending, upcoming, activity }

/// [_teamId] scopes every section to one team instead of the signed-in
/// user's own data — native shares this exact view-model between the Home
/// tab and Team Home (`HomeFragmentViewModel`, parameterized the same way),
/// so a `null` key here is the Home tab and an `int` key is a team's home.
class HomeViewModel extends Notifier<HomeState> {
  HomeViewModel(this._teamId);

  final int? _teamId;

  @override
  HomeState build() {
    // Switching the family selection re-fetches every section, aggregated
    // across the newly selected users (native `onUserSelectChangeClick`).
    ref.listen(selectedUserIdsProvider, (previous, next) {
      if (previous != null && previous != next) refresh();
    });
    // Start loading after the first build so `state` is initialised.
    Future.microtask(refresh);
    return const HomeState();
  }

  ScheduleRepository get _repo => ref.read(scheduleRepositoryProvider);

  List<String> get _userIds => ref.read(selectedUserIdsProvider);

  int get _hourFormat => ref.read(hourFormatProvider);

  /// Reloads every section (pull-to-refresh, family selection change, resume).
  Future<void> refresh() => Future.wait<void>([
    reload(HomeSection.pending),
    reload(HomeSection.upcoming),
    reload(HomeSection.activity),
    ref.refresh(scheduledMaintenanceProvider.future).then((_) {}),
  ]);

  Future<void> reload(HomeSection section) async {
    switch (section) {
      case HomeSection.pending:
        await _load<List<PendingAction>>(
          () => _repo.pendingActions(userIds: _userIds, teamId: _teamId),
          (v) => state = state.copyWith(pending: v),
        );
      case HomeSection.upcoming:
        await _load<List<ScheduleItem>>(
          () => _repo.homeUpcoming(
            userIds: _userIds,
            hourFormat: _hourFormat,
            teamId: _teamId,
          ),
          (v) => state = state.copyWith(upcoming: v),
        );
      case HomeSection.activity:
        await _load<List<HomePageStats>>(
          () => _repo.activitySummary(userIds: _userIds, teamId: _teamId),
          (v) => state = state.copyWith(activity: v),
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

/// `homeViewModelProvider(null)` is the Home tab; `homeViewModelProvider(id)`
/// is Team Home for that team.
final homeViewModelProvider = NotifierProvider.autoDispose
    .family<HomeViewModel, HomeState, int?>((teamId) => HomeViewModel(teamId));
