import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/common/widgets/event_tile.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/event_drafts/event_drafts_test_ids.dart';
import 'package:racketmates/screens/schedule/schedule_test_ids.dart';
import 'package:racketmates/screens/schedule/schedule_view_model.dart';

/// Schedule tab: upcoming and past events (native `ScheduleFragment`).
/// Drafts, to-be-rescheduled, filters, calendar view and swipe actions are
/// later work.
class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(ref.msg(MessageKeys.scheduleTitle, l10n.scheduleTitle)),
          actions: [
            TestId(
              EventDraftActionIds.scheduleButton,
              child: IconButton(
                tooltip: l10n.draftsAction,
                icon: const Icon(Icons.drafts_outlined),
                onPressed: () => context.push(AppRoutes.drafts),
              ),
            ),
          ],
          bottom: TabBar(
            tabs: [
              TestId(
                ScheduleTestIds.tab('upcoming'),
                child: Tab(
                  text: ref.msg(
                    MessageKeys.scheduleUpcomingTab,
                    l10n.tabUpcoming,
                  ),
                ),
              ),
              TestId(
                ScheduleTestIds.tab('past'),
                child: Tab(
                  text: ref.msg(MessageKeys.schedulePastTab, l10n.tabPast),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: TestId(
          ScheduleTestIds.createEvent,
          child: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: Text(l10n.addEventAction),
            onPressed: () {
              ref.read(createEventFlowProvider.notifier).start();
              context.push(AppRoutes.createEvent);
            },
          ),
        ),
        body: TestId(
          ScheduleTestIds.root,
          child: const TabBarView(
            children: [
              _ScheduleList(tab: ScheduleTab.upcoming),
              _ScheduleList(tab: ScheduleTab.past),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleList extends ConsumerStatefulWidget {
  const _ScheduleList({required this.tab});

  final ScheduleTab tab;

  @override
  ConsumerState<_ScheduleList> createState() => _ScheduleListState();
}

class _ScheduleListState extends ConsumerState<_ScheduleList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final provider = scheduleListViewModelProvider(widget.tab);
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    final name = widget.tab.name;

    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.failure != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.scheduleLoadError),
            TestId(
              ScheduleTestIds.retry(name),
              child: TextButton(
                onPressed: vm.retry,
                child: Text(l10n.retryAction),
              ),
            ),
          ],
        ),
      );
    }
    if (state.isEmpty) {
      return RefreshIndicator(
        onRefresh: vm.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            TestId(
              ScheduleTestIds.empty(name),
              child: Center(
                child: Text(
                  widget.tab == ScheduleTab.upcoming
                      ? ref.msg(
                          MessageKeys.scheduleNoUpcoming,
                          l10n.scheduleEmptyUpcoming,
                        )
                      : ref.msg(
                          MessageKeys.scheduleNoPast,
                          l10n.scheduleEmptyPast,
                        ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < 300) vm.loadMore();
          return false;
        },
        child: ListView.builder(
          key: Key(ScheduleTestIds.list(name)),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: state.items.length + (state.loadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= state.items.length) {
              return TestId(
                ScheduleTestIds.loadingMore(name),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            final item = state.items[index];
            final id = item.eventId;
            return EventTile(
              item: item,
              testId: ScheduleTestIds.event(name, id ?? index),
              onTap: id == null
                  ? null
                  : () => context.push(AppRoutes.eventFor(id)),
            );
          },
        ),
      ),
    );
  }
}
