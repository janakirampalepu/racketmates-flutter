import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/screens/schedule/schedule_state.dart';

/// Paged list for one schedule tab (`events_for` upcoming | past).
class ScheduleListViewModel extends Notifier<ScheduleListState> {
  ScheduleListViewModel(this.tab);

  final ScheduleTab tab;

  @override
  ScheduleListState build() {
    Future.microtask(_loadPage);
    return const ScheduleListState();
  }

  /// Pull-to-refresh: back to page 1.
  Future<void> refresh() async {
    state = const ScheduleListState();
    await _loadPage();
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    await _loadPage();
  }

  Future<void> retry() => refresh();

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
            tab: tab,
            page: state.nextPage,
            userIds: ref.read(selectedUserIdsProvider),
            hourFormat: ref.read(hourFormatProvider),
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

final scheduleListViewModelProvider = NotifierProvider.autoDispose
    .family<ScheduleListViewModel, ScheduleListState, ScheduleTab>(
      ScheduleListViewModel.new,
    );
