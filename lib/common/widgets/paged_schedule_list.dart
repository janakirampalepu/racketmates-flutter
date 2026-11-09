import 'package:flutter/material.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/widgets/event_tile.dart';
import 'package:racketmates/common/widgets/load_error_body.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/screens/schedule/schedule_state.dart';
import 'package:racketmates/screens/schedule/schedule_test_ids.dart';

/// One scrollable, paginated schedule list (upcoming or past, global or
/// team-scoped) with pull-to-refresh and load-more-on-scroll — the body
/// shared by the main Schedule screen's list, Team Schedule, and the Past
/// events screen so the paging/empty/error behavior stays identical.
/// [header] renders above the events (e.g. the Drafts/To-be-rescheduled/Past
/// entry rows) and scrolls away with the list, matching native (both
/// platforms put these inside the same scroll view as the events, not in a
/// fixed area above it).
class PagedScheduleList extends StatelessWidget {
  const PagedScheduleList({
    required this.state,
    required this.testName,
    required this.emptyText,
    required this.loadErrorText,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onRetry,
    this.header = const [],
    super.key,
  });

  final ScheduleListState state;
  final String testName;
  final String emptyText;
  final String loadErrorText;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;
  final List<Widget> header;

  @override
  Widget build(BuildContext context) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.failure != null && state.items.isEmpty) {
      return Center(
        child: LoadErrorBody(
          error: state.failure,
          fallbackText: loadErrorText,
          retryId: ScheduleTestIds.retry(testName),
          onRetry: onRetry,
        ),
      );
    }
    if (state.isEmpty && header.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            TestId(
              ScheduleTestIds.empty(testName),
              child: Center(child: Text(emptyText)),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < 300) onLoadMore();
          return false;
        },
        child: ListView.builder(
          key: Key(ScheduleTestIds.list(testName)),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount:
              header.length +
              (state.isEmpty ? 1 : state.items.length) +
              (state.loadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < header.length) return header[index];
            final i = index - header.length;
            if (state.isEmpty) {
              return TestId(
                ScheduleTestIds.empty(testName),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text(emptyText)),
                ),
              );
            }
            if (i >= state.items.length) {
              return TestId(
                ScheduleTestIds.loadingMore(testName),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            final item = state.items[i];
            final id = item.eventId;
            return EventTile(
              item: item,
              testId: ScheduleTestIds.event(testName, id ?? i),
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
