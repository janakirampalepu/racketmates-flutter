import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/screens/schedule/schedule_state.dart';

/// Paged events of one team (the schedule screen's paging with `team_id`).
class TeamScheduleViewModel extends Notifier<ScheduleListState> {
  TeamScheduleViewModel(this.args);

  final ({int teamId, ScheduleTab tab}) args;

  @override
  ScheduleListState build() {
    Future.microtask(_loadPage);
    return const ScheduleListState();
  }

  Future<void> refresh() async {
    state = const ScheduleListState();
    await _loadPage();
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    await _loadPage();
  }

  Future<void> _loadPage() async {
    final first = state.items.isEmpty;
    state = state.copyWith(
      loading: first,
      loadingMore: !first,
      failure: () => null,
    );
    try {
      final response = await ref
          .read(scheduleRepositoryProvider)
          .schedulePage(
            tab: args.tab,
            page: state.nextPage,
            userIds: ref.read(selectedUserIdsProvider),
            hourFormat: ref.read(hourFormatProvider),
            teamId: args.teamId,
          );
      if (!ref.mounted) return;
      final fetched = response.scheduleItems ?? const [];
      state = state.copyWith(
        items: [...state.items, ...fetched],
        nextPage: state.nextPage + 1,
        loading: false,
        loadingMore: false,
        hasMore: fetched.isNotEmpty,
      );
    } on AppFailure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        loading: false,
        loadingMore: false,
        failure: () => failure,
      );
    }
  }
}

final teamScheduleViewModelProvider = NotifierProvider.autoDispose
    .family<
      TeamScheduleViewModel,
      ScheduleListState,
      ({int teamId, ScheduleTab tab})
    >(TeamScheduleViewModel.new);
