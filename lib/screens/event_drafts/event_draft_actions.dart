import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/create_event_repository.dart';
import 'package:racketmates/common/create_event/draft_codec.dart';
import 'package:racketmates/common/create_event/drafts_models.dart';
import 'package:racketmates/common/create_event/drafts_repository.dart';
import 'package:racketmates/common/create_event/event_request.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/common/places/places_repository.dart';
import 'package:racketmates/common/teams/teams_repository.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/event_drafts/event_drafts_test_ids.dart';

/// The saved drafts of the user.
final draftsProvider = FutureProvider.autoDispose<List<DraftSummary>>(
  (ref) => ref
      .watch(draftsRepositoryProvider)
      .list(userIds: ref.watch(selectedUserIdsProvider)),
);

/// App bar actions of a create-event step: save what was entered as a draft,
/// or leave without saving (native exit sheet). Nothing before the event type
/// is chosen.
List<Widget> eventDraftActions(BuildContext context, WidgetRef ref) {
  final draft = ref.watch(createEventFlowProvider);
  if (draft?.spec == null) return const [];
  final l10n = AppLocalizations.of(context);
  return [
    TestId(
      EventDraftActionIds.menu,
      child: PopupMenuButton<String>(
        tooltip: l10n.eventDraftMenu,
        onSelected: (value) => value == 'save'
            ? saveEventDraft(context, ref)
            : discardEvent(context, ref),
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'save',
            child: TestId(
              EventDraftActionIds.save,
              child: Text(l10n.eventDraftSave),
            ),
          ),
          PopupMenuItem(
            value: 'discard',
            child: TestId(
              EventDraftActionIds.discard,
              child: Text(l10n.eventDraftDiscard),
            ),
          ),
        ],
      ),
    ),
  ];
}

/// Saves the event as a draft (`POST events` with `request_save_as_draft`, the
/// resumed draft's id replacing it) and shows the drafts.
Future<void> saveEventDraft(BuildContext context, WidgetRef ref) async {
  final draft = ref.read(createEventFlowProvider);
  if (draft == null || draft.spec == null) return;
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final location = GoRouterState.of(context).uri.path;
  final step = AppRoutes.stepForRoute(location);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: TestId(
            EventDraftActionIds.saving,
            child: Semantics(
              label: l10n.eventDraftSave,
              child: const CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    ),
  );
  var saved = false;
  try {
    await ref
        .read(createEventRepositoryProvider)
        .create(buildCreateEventBody(draft, asDraft: true, screen: step));
    saved = true;
  } on AppFailure {
    saved = false;
  }
  if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  if (!saved) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.eventDraftSaveFailed)));
    return;
  }
  ref
    ..read(createEventFlowProvider.notifier).reset()
    ..invalidate(draftsProvider);
  messenger.showSnackBar(SnackBar(content: Text(l10n.eventDraftSaved)));
  router.go(AppRoutes.schedule);
  unawaited(router.push(AppRoutes.drafts));
}

/// Leaves the wizard without saving; a draft that was resumed is deleted.
Future<void> discardEvent(BuildContext context, WidgetRef ref) async {
  final draft = ref.read(createEventFlowProvider);
  final l10n = AppLocalizations.of(context);
  final router = GoRouter.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final resumed = draft?.draftEventId;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.eventDraftDiscardTitle),
      content: Text(
        resumed == null
            ? l10n.eventDraftDiscardText
            : '${l10n.eventDraftDiscardText} ${l10n.eventDraftDiscardSavedText}',
      ),
      actions: [
        TestId(
          EventDraftActionIds.discardKeep,
          child: TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.eventDraftKeep),
          ),
        ),
        TestId(
          EventDraftActionIds.discardConfirm,
          child: FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.eventDraftLeave),
          ),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  if (resumed != null) {
    try {
      await ref.read(draftsRepositoryProvider).delete(resumed);
      ref.invalidate(draftsProvider);
    } on AppFailure {
      messenger.showSnackBar(SnackBar(content: Text(l10n.draftDeleteFailed)));
      return;
    }
  }
  ref.read(createEventFlowProvider.notifier).reset();
  router.go(AppRoutes.home);
}

/// Opens a saved draft in the wizard at the step the user left. False (and a
/// message) when the draft cannot be read.
Future<void> resumeEventDraft(
  BuildContext context,
  WidgetRef ref,
  DraftSummary summary,
) async {
  final id = summary.eventId;
  if (id == null) return;
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: TestId(
            EventDraftsTestIds.opening,
            child: Semantics(
              label: l10n.draftOpening,
              child: const CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    ),
  );
  ResumedDraft? resumed;
  try {
    final body = await ref
        .read(draftsRepositoryProvider)
        .request(id, hourFormat: ref.read(hourFormatProvider));
    resumed = await resumeDraft(
      parseDraftRequest(body),
      draftEventId: id,
      users: ref.read(createEventRepositoryProvider).usersByIds,
      place: ref.read(placesRepositoryProvider).details,
      team: ref.read(teamsRepositoryProvider).details,
    );
  } on AppFailure {
    resumed = null;
  } on DraftNotResumable {
    resumed = null;
  }
  if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  if (resumed == null) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.draftOpenFailed)));
    return;
  }
  ref.read(createEventFlowProvider.notifier).seed(resumed.draft);
  unawaited(router.push(AppRoutes.routeForStep(resumed.step)));
}
