import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/common/widgets/event_tile.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/team_details/team_details_test_ids.dart';
import 'package:racketmates/screens/team_details/team_schedule_view_model.dart';

/// The team's upcoming and past events (native team home). An archived team
/// opens on the past events.
class TeamScheduleTab extends ConsumerStatefulWidget {
  const TeamScheduleTab({
    required this.teamId,
    required this.archived,
    super.key,
  });

  final int teamId;
  final bool archived;

  @override
  ConsumerState<TeamScheduleTab> createState() => _TeamScheduleTabState();
}

class _TeamScheduleTabState extends ConsumerState<TeamScheduleTab> {
  late ScheduleTab _tab = widget.archived
      ? ScheduleTab.past
      : ScheduleTab.upcoming;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        ref
            .read(
              teamScheduleViewModelProvider((teamId: widget.teamId, tab: _tab))
                  .notifier,
            )
            .loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final args = (teamId: widget.teamId, tab: _tab);
    final state = ref.watch(teamScheduleViewModelProvider(args));
    final vm = ref.read(teamScheduleViewModelProvider(args).notifier);

    Widget body() {
      if (state.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (state.failure != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TestId(
                TeamDetailsTestIds.scheduleError,
                child: Text(l10n.teamScheduleLoadError),
              ),
              TestId(
                TeamDetailsTestIds.scheduleRetry,
                child: TextButton(
                  onPressed: vm.refresh,
                  child: Text(l10n.retryAction),
                ),
              ),
            ],
          ),
        );
      }
      if (state.isEmpty) {
        return Center(
          child: TestId(
            TeamDetailsTestIds.scheduleEmpty,
            child: Text(
              _tab == ScheduleTab.upcoming
                  ? l10n.teamScheduleEmptyUpcoming
                  : l10n.teamScheduleEmptyPast,
            ),
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: vm.refresh,
        child: ListView.builder(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: state.items.length + (state.loadingMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i >= state.items.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final item = state.items[i];
            final id = item.eventId;
            return EventTile(
              item: item,
              testId: TeamDetailsTestIds.scheduleEvent(id ?? i),
              onTap: id == null
                  ? null
                  : () => context.push(AppRoutes.eventFor(id)),
            );
          },
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SegmentedButton<ScheduleTab>(
            segments: [
              ButtonSegment(
                value: ScheduleTab.upcoming,
                label: TestId(
                  TeamDetailsTestIds.scheduleUpcoming,
                  child: Text(l10n.teamScheduleUpcoming),
                ),
              ),
              ButtonSegment(
                value: ScheduleTab.past,
                label: TestId(
                  TeamDetailsTestIds.schedulePast,
                  child: Text(l10n.teamSchedulePast),
                ),
              ),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() => _tab = s.first),
          ),
        ),
        Expanded(child: body()),
      ],
    );
  }
}
