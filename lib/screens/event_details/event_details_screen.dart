import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/events/event_labels.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/events/rsvp_actions.dart';
import 'package:racketmates/common/events/rsvp_preferences.dart';
import 'package:racketmates/common/chat/event_chat.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/chat_new/new_chat_test_ids.dart';
import 'package:racketmates/screens/event_details/event_chat_actions.dart';
import 'package:racketmates/screens/event_details/event_details_state.dart';
import 'package:racketmates/screens/event_details/event_details_test_ids.dart';
import 'package:racketmates/screens/event_details/event_details_view_model.dart';
import 'package:racketmates/screens/event_details/rsvp_preferences_sheet.dart';

/// Event view for a participant (native `ViewEventDetailsFragment`): type,
/// status, when/where, the user's own status, spots, notes, players, plus the
/// RSVP actions the backend allows and cancel for managers. Choosing between
/// several time options / partners, scoring, chat and full manage screens come
/// with later milestones.
class EventDetailsScreen extends ConsumerWidget {
  const EventDetailsScreen({required this.eventId, super.key});

  final int eventId;

  String _actionLabel(AppLocalizations l10n, RsvpAction action) =>
      switch (action) {
        RsvpAction.accept => l10n.rsvpAccept,
        RsvpAction.decline => l10n.rsvpDecline,
        RsvpAction.rejoin => l10n.rsvpRejoin,
        RsvpAction.leave => l10n.rsvpLeave,
        RsvpAction.joinWaitlist => l10n.rsvpJoinWaitlist,
        RsvpAction.editResponse => l10n.rsvpEditResponse,
      };

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String dismissLabel,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TestId(
              EventDetailsTestIds.confirmDismissButton,
              child: TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(dismissLabel),
              ),
            ),
            TestId(
              EventDetailsTestIds.confirmButton,
              child: FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(confirmLabel),
              ),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    RsvpOption option,
  ) async {
    final l10n = AppLocalizations.of(context);
    final vm = ref.read(eventDetailsViewModelProvider(eventId).notifier);
    final messenger = ScaffoldMessenger.of(context);
    if (option.block == RsvpBlock.requiresSubscription) {
      messenger.showSnackBar(
        SnackBar(content: Text(option.message ?? l10n.rsvpNeedsSubscription)),
      );
      return;
    }
    if (option.block == RsvpBlock.needsOptionPicker) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.rsvpNeedsPicker)));
      return;
    }
    switch (option.action) {
      case RsvpAction.decline:
        final ok = await _confirm(
          context,
          title: l10n.rsvpDeclineTitle,
          message: l10n.rsvpDeclineMessage,
          confirmLabel: l10n.rsvpDecline,
          dismissLabel: l10n.closeAction,
        );
        if (ok) await vm.rsvp(option.action);
      case RsvpAction.leave:
        final ok = await _confirm(
          context,
          title: l10n.rsvpLeaveTitle,
          message: l10n.rsvpLeaveMessage,
          confirmLabel: l10n.rsvpLeave,
          dismissLabel: l10n.closeAction,
        );
        if (ok) await vm.rsvp(option.action);
      case RsvpAction.accept || RsvpAction.rejoin || RsvpAction.joinWaitlist:
        final event = ref
            .read(eventDetailsViewModelProvider(eventId))
            .event
            .value;
        final mine = event?.currentUserEventDetails?.firstOrNull;
        if (event != null && asksPreferences(event, mine)) {
          // Round robins: how the player wants to play goes with the answer.
          final prefs = await showRsvpPreferences(
            context,
            event: event,
            me: mine,
            editing: false,
          );
          if (prefs != null) await vm.rsvp(option.action, preferences: prefs);
        } else {
          await vm.rsvp(option.action);
        }
      default:
        await vm.rsvp(option.action);
    }
  }

  Future<void> _editPartner(BuildContext context, WidgetRef ref) async {
    final vm = ref.read(eventDetailsViewModelProvider(eventId).notifier);
    final event = ref.read(eventDetailsViewModelProvider(eventId)).event.value;
    if (event == null) return;
    final prefs = await showRsvpPreferences(
      context,
      event: event,
      me: event.currentUserEventDetails?.firstOrNull,
      editing: true,
    );
    if (prefs != null) await vm.updatePreferences(prefs);
  }

  Future<void> _onCancelEvent(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_CancelChoice>(
      context: context,
      builder: (_) => const _CancelEventDialog(),
    );
    if (result == null || !context.mounted) return;
    await ref
        .read(eventDetailsViewModelProvider(eventId).notifier)
        .cancelEvent(reason: result.reason, removeEvent: result.remove);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = eventDetailsViewModelProvider(eventId);
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);

    ref.listen(provider.select((s) => s.feedback), (_, feedback) {
      if (feedback == null) return;
      final fallback = switch (feedback.kind) {
        FeedbackKind.cancel =>
          feedback.isError ? l10n.cancelEventFailed : l10n.cancelEventDone,
        FeedbackKind.scores =>
          feedback.isError
              ? l10n.eventScoresConfirmFailed
              : l10n.eventScoresConfirmed,
        FeedbackKind.rsvp =>
          feedback.isError ? l10n.rsvpActionFailed : l10n.rsvpDone,
        FeedbackKind.preferences =>
          feedback.isError ? l10n.eventPrefsFailed : l10n.eventPrefsSaved,
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(feedback.text ?? fallback)));
      vm.clearFeedback();
    });
    ref.listen(provider.select((s) => s.removed), (_, removed) {
      if (removed && context.mounted) context.pop();
    });

    final event = state.event.value;
    final options = event == null
        ? const <RsvpOption>[]
        : rsvpOptionsFor(event);
    final confirmScores = event != null && canConfirmScores(event);
    final chatOptions = event == null
        ? const <EventChatOption>[]
        : chatOptionsFor(ref, event);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eventDetailsTitle),
        leading: TestId(
          EventDetailsTestIds.back,
          child: BackButton(onPressed: () => context.pop()),
        ),
        actions: [
          if (event != null && chatOptions.isNotEmpty)
            TestId(
              EventChatTestIds.button,
              child: IconButton(
                tooltip: l10n.eventChatAction,
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () => openEventChat(
                  context,
                  ref,
                  event,
                  chatOptions,
                  onCreated: vm.refresh,
                ),
              ),
            ),
          if (event != null && canManageEvent(event))
            TestId(
              EventDetailsTestIds.menu,
              child: PopupMenuButton<String>(
                tooltip: l10n.moreOptionsLabel,
                enabled: !state.busy,
                onSelected: (value) => value == 'manage'
                    ? context.push(AppRoutes.eventManageFor(eventId))
                    : _onCancelEvent(context, ref),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'manage',
                    child: TestId(
                      EventDetailsTestIds.menuManageEvent,
                      child: Text(l10n.eventManageAction),
                    ),
                  ),
                  if (canCancelEvent(event))
                    PopupMenuItem(
                      value: 'cancel',
                      child: TestId(
                        EventDetailsTestIds.menuCancelEvent,
                        child: Text(l10n.cancelEventAction),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: options.isEmpty && !confirmScores
          ? null
          : SafeArea(
              child: TestId(
                EventDetailsTestIds.actionBar,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      if (confirmScores)
                        Expanded(
                          child: TestId(
                            EventDetailsTestIds.confirmScores,
                            child: FilledButton(
                              onPressed: state.busy ? null : vm.acceptScores,
                              child: state.acceptingScores
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(l10n.eventConfirmScores),
                            ),
                          ),
                        ),
                      if (confirmScores && options.isNotEmpty)
                        const SizedBox(width: 12),
                      for (final option in options) ...[
                        Expanded(
                          child: TestId(
                            EventDetailsTestIds.action(option.action.name),
                            child: option.action == options.first.action
                                ? FilledButton(
                                    onPressed: state.busy
                                        ? null
                                        : () => _onAction(context, ref, option),
                                    child: state.busyAction == option.action
                                        ? const SizedBox.square(
                                            dimension: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            _actionLabel(l10n, option.action),
                                          ),
                                  )
                                : OutlinedButton(
                                    onPressed: state.busy
                                        ? null
                                        : () => _onAction(context, ref, option),
                                    child: Text(
                                      _actionLabel(l10n, option.action),
                                    ),
                                  ),
                          ),
                        ),
                        if (option != options.last) const SizedBox(width: 12),
                      ],
                    ],
                  ),
                ),
              ),
            ),
      body: TestId(
        EventDetailsTestIds.root,
        child: state.event.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.eventLoadError),
                TestId(
                  EventDetailsTestIds.retry,
                  child: TextButton(
                    onPressed: vm.load,
                    child: Text(l10n.retryAction),
                  ),
                ),
              ],
            ),
          ),
          data: (event) => _Body(
            event: event,
            busy: state.busy,
            onEditPartner: () => _editPartner(context, ref),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.event,
    required this.busy,
    required this.onEditPartner,
  });

  final EventDetails event;
  final bool busy;
  final VoidCallback onEditPartner;

  String _when(BuildContext context, EventScheduleOption option) {
    final start = option.start?.toLocal();
    if (start == null) return '';
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMMMEd(locale).format(start);
    final from = DateFormat.jm(locale).format(start);
    final end = option.end?.toLocal();
    final to = end == null ? '' : ' – ${DateFormat.jm(locale).format(end)}';
    return '$date, $from$to';
  }

  /// The player's partner on a fixed-partner event (native
  /// `refreshEventPartnerForSelectedUser`).
  List<Widget> _partnerSection(
    BuildContext context,
    AppLocalizations l10n,
    CurrentUserEventDetail? mine,
  ) {
    final standing = partnerStandingFor(event, mine);
    if (standing == PartnerStanding.none) return const [];
    final partner = mine?.eventPartner;
    return [
      TestId(
        EventDetailsTestIds.partnerSection,
        child: switch (standing) {
          PartnerStanding.needsChoice => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(child: Text(l10n.eventPartnerChoose)),
                TestId(
                  EventDetailsTestIds.partnerChoose,
                  child: TextButton(
                    onPressed: busy ? null : onEditPartner,
                    child: Text(l10n.eventPartnerChooseAction),
                  ),
                ),
              ],
            ),
          ),
          _ => _Row(
            label: standing == PartnerStanding.mine
                ? l10n.eventPartnerYours
                : l10n.eventPartnerRequested,
            value: partner?.name ?? '',
            trailing: standing == PartnerStanding.mine
                ? TestId(
                    EventDetailsTestIds.partnerEdit,
                    child: IconButton(
                      tooltip: l10n.eventPartnerEdit,
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: busy ? null : onEditPartner,
                    ),
                  )
                : null,
          ),
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final option = event.eventScheduleOptions?.firstOrNull;
    final place = option?.place;
    final mine = event.currentUserEventDetails?.firstOrNull;
    final players = event.players;
    final spots = event.regularSpotsLeft;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TestId(
          EventDetailsTestIds.title,
          child: Semantics(
            header: true,
            child: Text(
              humanizeKey(event.eventType),
              style: theme.textTheme.headlineSmall,
            ),
          ),
        ),
        if (event.status != null)
          TestId(
            EventDetailsTestIds.status,
            child: Text(
              '${l10n.eventStatusLabel}: ${humanizeKey(event.status)}',
            ),
          ),
        const SizedBox(height: 16),
        if (option != null)
          TestId(
            EventDetailsTestIds.when,
            child: _Row(
              label: l10n.eventWhenLabel,
              value: _when(context, option),
            ),
          ),
        if (place?.name != null)
          TestId(
            EventDetailsTestIds.where,
            child: _Row(
              label: l10n.eventWhereLabel,
              value: [
                place!.name!,
                if (place.address != null) place.address!,
              ].join('\n'),
            ),
          ),
        if (mine?.statusTitle != null)
          TestId(
            EventDetailsTestIds.yourStatus,
            child: _Row(
              label: l10n.eventYourStatus,
              value: [
                mine!.statusTitle!,
                if (mine.statusSubText != null) mine.statusSubText!,
              ].join('\n'),
            ),
          ),
        ..._partnerSection(context, l10n, mine),
        if (spots != null)
          TestId(
            EventDetailsTestIds.spots,
            child: Text(l10n.eventSpotsLeft(spots)),
          ),
        if ((event.notesForEvent ?? '').isNotEmpty)
          TestId(
            EventDetailsTestIds.notes,
            child: _Row(
              label: l10n.eventNotesLabel,
              value: event.notesForEvent!,
            ),
          ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            l10n.eventParticipantsLabel,
            style: theme.textTheme.titleLarge,
          ),
        ),
        TestId(
          EventDetailsTestIds.players,
          child: players.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(l10n.eventNoPlayers),
                )
              : Column(
                  children: [
                    for (final p in players)
                      TestId(
                        EventDetailsTestIds.player(p.id ?? p.userId ?? 0),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(
                            (p.user?.displayName.isNotEmpty ?? false)
                                ? p.user!.displayName
                                : l10n.unknownPlayer,
                          ),
                          subtitle: p.participantLabel == null
                              ? null
                              : Text(p.participantLabel!),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              Text(value),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class _CancelChoice {
  const _CancelChoice({required this.reason, required this.remove});

  final String reason;
  final bool remove;
}

/// Reason + "also remove from the schedule" (native `CancelDetailsFragment`).
/// Stateful so it owns (and disposes) its text controller with the dialog.
class _CancelEventDialog extends StatefulWidget {
  const _CancelEventDialog();

  @override
  State<_CancelEventDialog> createState() => _CancelEventDialogState();
}

class _CancelEventDialogState extends State<_CancelEventDialog> {
  final _reason = TextEditingController();
  bool _remove = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.cancelEventTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TestId(
              EventDetailsTestIds.cancelReason,
              child: TextField(
                controller: _reason,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.cancelEventReasonLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            TestId(
              EventDetailsTestIds.cancelRemoveSwitch,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.cancelEventRemoveLabel),
                value: _remove,
                onChanged: (v) => setState(() => _remove = v),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TestId(
          EventDetailsTestIds.cancelKeep,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancelEventKeep),
          ),
        ),
        TestId(
          EventDetailsTestIds.cancelConfirm,
          child: FilledButton(
            onPressed: () =>
                Navigator.of(context)
                    .pop(_CancelChoice(reason: _reason.text, remove: _remove)),
            child: Text(l10n.cancelEventConfirm),
          ),
        ),
      ],
    );
  }
}
