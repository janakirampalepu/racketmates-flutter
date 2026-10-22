import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/create_event/match_draft.dart';
import 'package:racketmates/common/widgets/step_scaffold.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/create_event_assign_type/create_event_assign_type_test_ids.dart';

/// Assign players to matches now, or invite players and assign later (native
/// `AssignTypeFragment`). Assigning now needs singles or doubles on every
/// match, since an undecided match has no spots to fill.
class CreateEventAssignTypeScreen extends ConsumerStatefulWidget {
  const CreateEventAssignTypeScreen({super.key});

  @override
  ConsumerState<CreateEventAssignTypeScreen> createState() =>
      _CreateEventAssignTypeScreenState();
}

class _CreateEventAssignTypeScreenState
    extends ConsumerState<CreateEventAssignTypeScreen> {
  bool _showError = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(createEventFlowProvider) ?? const EventDraft();
    final flow = ref.read(createEventFlowProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final lesson = draft.spec?.individualLesson ?? false;

    Widget option({
      required String id,
      required String title,
      required String subtitle,
      required bool selected,
      required VoidCallback onTap,
    }) => TestId(
      id,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: ListTile(
          selected: selected,
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: selected ? const Icon(Icons.check_circle) : null,
          onTap: () {
            setState(() => _showError = false);
            onTap();
          },
        ),
      ),
    );

    return StepScaffold(
      rootId: CreateEventAssignTypeTestIds.root,
      titleId: CreateEventAssignTypeTestIds.title,
      title: lesson ? l10n.createLessonAssignTitle : l10n.createAssignTypeTitle,
      primaryLabel: ref.msg(MessageKeys.buttonNext, l10n.nextAction),
      primaryId: CreateEventAssignTypeTestIds.next,
      onPrimary: () {
        final undecided = draft.matches.any(
          (m) => m.matchType == MatchKeys.undecided,
        );
        if (draft.assignNow && undecided) {
          setState(() => _showError = true);
          return;
        }
        context.push(
          AppRoutes.routeForStep(flow.next(CreateEventStep.assignType)!),
        );
      },
      onBack: () => context.pop(),
      children: [
        option(
          id: CreateEventAssignTypeTestIds.assignNow,
          title: lesson ? l10n.createLessonAssignOne : l10n.createAssignNow,
          subtitle: lesson
              ? l10n.createLessonAssignOneHint
              : l10n.createAssignNowHint,
          selected: draft.assignNow,
          onTap: () => flow.setAssignNow(value: true),
        ),
        option(
          id: CreateEventAssignTypeTestIds.assignLater,
          title: lesson ? l10n.createLessonAssignMany : l10n.createAssignLater,
          subtitle: lesson
              ? l10n.createLessonAssignManyHint
              : l10n.createAssignLaterHint,
          selected: !draft.assignNow,
          onTap: () => flow.setAssignNow(value: false),
        ),
        if (_showError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TestId(
              CreateEventAssignTypeTestIds.error,
              child: Semantics(
                liveRegion: true,
                child: Text(
                  l10n.createAssignUndecided,
                  style: TextStyle(color: scheme.error),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
