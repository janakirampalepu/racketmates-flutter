import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/sign_up/sign_up_flow.dart';
import 'package:racketmates/common/sign_up/sign_up_steps.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/common/widgets/step_scaffold.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/role_selection/role_selection_test_ids.dart';

/// Player / coach / parent (multi-select); next step follows the native role
/// rules in `sign_up_steps.dart`.
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  bool _showError = false;

  String _label(AppLocalizations l10n, String role) => switch (role) {
    RoleKeys.player => l10n.rolePlayer,
    RoleKeys.coach => l10n.roleCoach,
    _ => l10n.roleParent,
  };

  void _next() {
    final draft = ref.read(signUpFlowProvider)!;
    if (draft.roles.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    switch (stepAfterRoles(draft)) {
      case SignUpStep.playerSports:
        context.push(AppRoutes.sports('player'));
      case SignUpStep.coachSports:
        context.push(AppRoutes.sports('coach'));
      case SignUpStep.kidForm:
        context.push(AppRoutes.kidForm);
      case SignUpStep.kidsList:
        context.push(AppRoutes.kidsList);
      case SignUpStep.createAccount:
        break; // not reachable from role selection
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(signUpFlowProvider);
    final roles = draft?.roles ?? const <String>{};
    return StepScaffold(
      rootId: RoleSelectionTestIds.root,
      titleId: RoleSelectionTestIds.title,
      title: l10n.roleSelectionTitle,
      primaryLabel: l10n.nextAction,
      primaryId: RoleSelectionTestIds.next,
      onPrimary: _next,
      onBack: () => context.pop(),
      children: [
        for (final role in RoleKeys.all)
          TestId(
            RoleSelectionTestIds.role(role),
            child: CheckboxListTile(
              value: roles.contains(role),
              title: Text(_label(l10n, role)),
              onChanged: (_) {
                ref.read(signUpFlowProvider.notifier).toggleRole(role);
                setState(() => _showError = false);
              },
            ),
          ),
        if (_showError)
          TestId(
            RoleSelectionTestIds.error,
            child: Semantics(
              liveRegion: true,
              child: Text(
                l10n.roleRequiredError,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
      ],
    );
  }
}
