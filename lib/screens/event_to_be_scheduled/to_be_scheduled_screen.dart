import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/widgets/event_tile.dart';
import 'package:racketmates/common/widgets/load_error_body.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/event_to_be_scheduled/to_be_scheduled_view_model.dart';
import 'package:racketmates/screens/schedule/schedule_test_ids.dart';

/// Events that still need a time picked (native `DraftEventsFragment` in its
/// `EVENT_STATUS_TO_BE_RESCHEDULE` mode, reached from a dedicated button on
/// the main Schedule screen, not a Schedule tab).
class ToBeScheduledScreen extends ConsumerWidget {
  const ToBeScheduledScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items = ref.watch(toBeScheduledProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          ref.msg(
            MessageKeys.scheduleYetToBeRescheduledTitle,
            l10n.toBeScheduledTitle,
          ),
        ),
      ),
      body: TestId(
        ToBeScheduledTestIds.root,
        child: items.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: LoadErrorBody(
              error: error,
              fallbackText: l10n.toBeScheduledLoadError,
              retryId: ToBeScheduledTestIds.retry,
              onRetry: () => ref.invalidate(toBeScheduledProvider),
              errorTestId: ToBeScheduledTestIds.error,
            ),
          ),
          data: (list) => list.isEmpty
              ? Center(
                  child: TestId(
                    ToBeScheduledTestIds.empty,
                    child: Text(l10n.toBeScheduledEmpty),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async =>
                      ref.refresh(toBeScheduledProvider.future),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final item = list[i];
                      final id = item.eventId;
                      return EventTile(
                        item: item,
                        testId: ToBeScheduledTestIds.event(id ?? i),
                        onTap: id == null
                            ? null
                            : () => context.push(AppRoutes.eventFor(id)),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
