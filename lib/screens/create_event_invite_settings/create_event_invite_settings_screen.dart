import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/widgets/number_stepper.dart';
import 'package:racketmates/common/widgets/step_scaffold.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/create_event_invite_settings/create_event_invite_settings_test_ids.dart';

/// Player limits and how players are accepted (native
/// `InvitePlayerSettingsFragment`; the whole-team pool only exists for team
/// events). The acceptance choice is offered because there is one time option.
class CreateEventInviteSettingsScreen extends ConsumerWidget {
  const CreateEventInviteSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(createEventFlowProvider) ?? const EventDraft();
    final flow = ref.read(createEventFlowProvider.notifier);
    return StepScaffold(
      rootId: CreateEventInviteSettingsTestIds.root,
      titleId: CreateEventInviteSettingsTestIds.title,
      title: ref.msg(
        MessageKeys.createPoolTitle,
        l10n.createInviteSettingsTitle,
      ),
      primaryLabel: ref.msg(MessageKeys.buttonNext, l10n.nextAction),
      primaryId: CreateEventInviteSettingsTestIds.next,
      onPrimary: () => context.push(
        AppRoutes.routeForStep(flow.next(CreateEventStep.inviteSettings)!),
      ),
      onBack: () => context.pop(),
      children: [
        _LimitRow(
          label: ref.msg(
            MessageKeys.createMaxPlayersLabel,
            l10n.createMaxPlayersLabel,
          ),
          // One student per lesson: the limit is fixed at one.
          stepper: (draft.spec?.individualLesson ?? false)
              ? TestId(
                  '${CreateEventInviteSettingsTestIds.playersPrefix}_value',
                  child: Text(
                    '${draft.playersLimit}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                )
              : NumberStepper(
                  idPrefix: CreateEventInviteSettingsTestIds.playersPrefix,
                  label: l10n.createMaxPlayersLabel,
                  decreaseLabel: l10n.createDecrease,
                  increaseLabel: l10n.createIncrease,
                  value: draft.playersLimit,
                  onChanged: flow.setPlayersLimit,
                ),
        ),
        _LimitRow(
          label: ref.msg(
            MessageKeys.createRsvpLimitLabel,
            l10n.createRsvpLimitLabel,
          ),
          stepper: NumberStepper(
            idPrefix: CreateEventInviteSettingsTestIds.rsvpPrefix,
            label: l10n.createRsvpLimitLabel,
            decreaseLabel: l10n.createDecrease,
            increaseLabel: l10n.createIncrease,
            value: draft.rsvpLimit,
            min: draft.playersLimit,
            onChanged: flow.setRsvpLimit,
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            ref.msg(
              MessageKeys.createAcceptanceLabel,
              l10n.createAcceptanceLabel,
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        RadioGroup<String>(
          groupValue: draft.acceptanceType,
          onChanged: (v) {
            if (v != null) flow.setAcceptanceType(v);
          },
          child: Column(
            children: [
              TestId(
                CreateEventInviteSettingsTestIds.orderOfResponse,
                child: RadioListTile<String>(
                  value: acceptOrderOfResponse,
                  title: Text(l10n.createAcceptOrderOfResponse),
                ),
              ),
              TestId(
                CreateEventInviteSettingsTestIds.pickManually,
                child: RadioListTile<String>(
                  value: acceptPickManually,
                  title: Text(l10n.createAcceptPickManually),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LimitRow extends StatelessWidget {
  const _LimitRow({required this.label, required this.stepper});

  final String label;
  final Widget stepper;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        stepper,
      ],
    ),
  );
}
