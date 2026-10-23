import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_controller.dart';
import 'package:racketmates/common/create_event/drafts_models.dart';
import 'package:racketmates/common/create_event/drafts_repository.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/event_labels.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/sign_up/sport_labels.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/event_drafts/event_draft_actions.dart';
import 'package:racketmates/screens/event_drafts/event_drafts_test_ids.dart';

/// Events saved as drafts (native `DraftEventsFragment`): tap one to carry on
/// creating it, or delete it.
class EventDraftsScreen extends ConsumerWidget {
  const EventDraftsScreen({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    DraftSummary draft,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final id = draft.eventId;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.draftDeleteTitle),
        content: Text(l10n.draftDeleteText),
        actions: [
          TestId(
            EventDraftsTestIds.confirmNo,
            child: TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.teamActionNo),
            ),
          ),
          TestId(
            EventDraftsTestIds.confirmYes,
            child: FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.teamActionYes),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(draftsRepositoryProvider).delete(id);
      ref.invalidate(draftsProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.draftDeleted)));
    } on AppFailure {
      messenger.showSnackBar(SnackBar(content: Text(l10n.draftDeleteFailed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final drafts = ref.watch(draftsProvider);
    final reference = ref.watch(referenceDataProvider);
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: TestId(
          EventDraftsTestIds.title,
          child: Semantics(header: true, child: Text(l10n.draftsTitle)),
        ),
      ),
      body: TestId(
        EventDraftsTestIds.root,
        child: drafts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TestId(
                  EventDraftsTestIds.error,
                  child: Text(l10n.draftsLoadError),
                ),
                TestId(
                  EventDraftsTestIds.retry,
                  child: TextButton(
                    onPressed: () => ref.invalidate(draftsProvider),
                    child: Text(l10n.retryAction),
                  ),
                ),
              ],
            ),
          ),
          data: (list) => list.isEmpty
              ? Center(
                  child: TestId(
                    EventDraftsTestIds.empty,
                    child: Text(l10n.draftsEmpty),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => ref.refresh(draftsProvider.future),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final d = list[i];
                      final sport = SportKey.fromKey(d.sportType);
                      final updated = d.updatedAt;
                      return TestId(
                        EventDraftsTestIds.draft(d.eventId ?? i),
                        child: ListTile(
                          title: Text(
                            reference.label(d.eventType) ??
                                humanizeKey(d.eventType),
                          ),
                          subtitle: Text(
                            [
                              if (sport != null) sportLabel(l10n, sport),
                              if ((d.courtsLabel ?? '').isNotEmpty)
                                d.courtsLabel!,
                              if (updated != null)
                                l10n.draftsUpdated(
                                  DateFormat.yMMMd(locale).format(updated),
                                ),
                            ].join(' · '),
                          ),
                          trailing: TestId(
                            EventDraftsTestIds.delete(d.eventId ?? i),
                            child: IconButton(
                              tooltip: l10n.draftDelete,
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _delete(context, ref, d),
                            ),
                          ),
                          onTap: () => resumeEventDraft(context, ref, d),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
