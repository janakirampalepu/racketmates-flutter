import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/errors/failure_message.dart';
import 'package:racketmates/common/sign_up/create_account_controller.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/sign_up/sign_up_flow.dart';
import 'package:racketmates/common/sign_up/sign_up_steps.dart';
import 'package:racketmates/common/sign_up/sport_labels.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/common/widgets/native_widgets.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/sports_selection/sports_selection_test_ids.dart';

/// Sports for the player or coach role (route param `player` | `coach`).
class SportsSelectionScreen extends ConsumerStatefulWidget {
  const SportsSelectionScreen({required this.role, super.key});

  /// `RoleKeys.player` or `RoleKeys.coach`.
  final String role;

  @override
  ConsumerState<SportsSelectionScreen> createState() =>
      _SportsSelectionScreenState();
}

class _SportsSelectionScreenState extends ConsumerState<SportsSelectionScreen> {
  bool _showError = false;

  bool get _isCoach => widget.role == RoleKeys.coach;

  Future<void> _next() async {
    final draft = ref.read(signUpFlowProvider)!;
    final selected = _isCoach ? draft.coachSports : draft.playerSports;
    if (selected.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    final step = _isCoach
        ? stepAfterCoachSports(draft)
        : stepAfterPlayerSports(draft);
    switch (step) {
      case SignUpStep.coachSports:
        await context.push(AppRoutes.sports('coach'));
      case SignUpStep.kidForm:
        await context.push(AppRoutes.kidForm);
      case SignUpStep.kidsList:
        await context.push(AppRoutes.kidsList);
      case SignUpStep.playerSports:
        break;
      case SignUpStep.createAccount:
        final ok = await ref
            .read(createAccountControllerProvider.notifier)
            .submit();
        if (ok && mounted) context.go(AppRoutes.profilePicture);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(signUpFlowProvider);
    final selected = _isCoach
        ? (draft?.coachSports ?? const <SportKey>{})
        : (draft?.playerSports ?? const <SportKey>{});
    final create = ref.watch(createAccountControllerProvider);
    return SignUpScaffold(
      rootId: SportsSelectionTestIds.root,
      titleId: SportsSelectionTestIds.title,
      title: _isCoach
          ? ref.preMsg(MessageKeys.preCoachSportTitle, l10n.sportsCoachTitle)
          : ref.preMsg(MessageKeys.prePlayerSportTitle, l10n.sportsPlayerTitle),
      primaryLabel: l10n.nextAction,
      primaryId: SportsSelectionTestIds.next,
      loading: create.loading,
      onPrimary: _next,
      onBack: () => context.pop(),
      children: [
        for (final sport in SportKey.values)
          TestId(
            SportsSelectionTestIds.sport(sport.key),
            child: NativeChoiceCard(
              icon: 'ic_${sport.name}_sport',
              iconSize: 28,
              padding: 12,
              titleSize: 12,
              title: sportLabel(l10n, sport),
              selected: selected.contains(sport),
              onChanged: () {
                ref
                    .read(signUpFlowProvider.notifier)
                    .toggleSport(widget.role, sport);
                setState(() => _showError = false);
              },
            ),
          ),
        if (_showError || create.failure != null)
          TestId(
            SportsSelectionTestIds.error,
            child: Semantics(
              liveRegion: true,
              child: Text(
                _showError
                    ? ref.preMsg(
                        MessageKeys.preSportRequiredTitle,
                        l10n.sportRequiredError,
                      )
                    : failureMessage(l10n, create.failure!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
      ],
    );
  }
}
