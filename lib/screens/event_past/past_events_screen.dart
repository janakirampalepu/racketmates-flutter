import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/common/widgets/paged_schedule_list.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/schedule/schedule_state.dart';
import 'package:racketmates/screens/schedule/schedule_test_ids.dart';
import 'package:racketmates/screens/schedule/schedule_view_model.dart';
import 'package:racketmates/screens/team_details/team_schedule_view_model.dart';

/// Past events — its own screen on both native apps (Android
/// `btnPastEvents`/`PastEventsFragment`, iOS's `EventListTopRowView`
/// "Past events" row/`.pastEventsScreen`), not a Schedule tab.
/// [teamId] scopes it the same way Team Schedule scopes the upcoming list.
class PastEventsScreen extends ConsumerWidget {
  const PastEventsScreen({this.teamId, super.key});

  final int? teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final testName = teamId == null ? 'past' : 'team_past';
    final ScheduleListState state;
    final Future<void> Function() onRefresh;
    final VoidCallback onLoadMore;
    final VoidCallback onRetry;
    if (teamId == null) {
      final provider = scheduleListViewModelProvider(ScheduleTab.past);
      state = ref.watch(provider);
      final vm = ref.read(provider.notifier);
      onRefresh = vm.refresh;
      onLoadMore = vm.loadMore;
      onRetry = vm.retry;
    } else {
      final provider = teamScheduleViewModelProvider((
        teamId: teamId!,
        tab: ScheduleTab.past,
      ));
      state = ref.watch(provider);
      final vm = ref.read(provider.notifier);
      onRefresh = vm.refresh;
      onLoadMore = vm.loadMore;
      onRetry = vm.refresh;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(ref.msg(MessageKeys.schedulePastTab, l10n.pastEventsTitle)),
      ),
      body: TestId(
        PastEventsTestIds.root,
        child: PagedScheduleList(
          state: state,
          testName: testName,
          emptyText: l10n.pastEventsEmpty,
          loadErrorText: l10n.pastEventsLoadError,
          onRefresh: onRefresh,
          onLoadMore: onLoadMore,
          onRetry: onRetry,
        ),
      ),
    );
  }
}
