import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/sign_up/sign_up_flow.dart';
import 'package:racketmates/common/sign_up/sign_up_steps.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/common/widgets/native_widgets.dart';
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

  String _subKey(String role) => switch (role) {
    RoleKeys.player => MessageKeys.prePlayerSub,
    RoleKeys.coach => MessageKeys.preCoachSub,
    _ => MessageKeys.preParentSub,
  };

  String _title(WidgetRef ref, AppLocalizations l10n, String role) =>
      ref.preMsg(switch (role) {
        RoleKeys.player => MessageKeys.prePlayerTitle,
        RoleKeys.coach => MessageKeys.preCoachTitle,
        _ => MessageKeys.preParentTitle,
      }, _label(l10n, role));

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
    return SignUpScaffold(
      rootId: RoleSelectionTestIds.root,
      titleId: RoleSelectionTestIds.title,
      title: ref.preMsg(MessageKeys.preRoleTitle, l10n.roleSelectionTitle),
      primaryLabel: l10n.nextAction,
      primaryId: RoleSelectionTestIds.next,
      onPrimary: _next,
      onBack: () => context.pop(),
      children: [
        for (final role in RoleKeys.all)
          TestId(
            RoleSelectionTestIds.role(role),
            child: NativeChoiceCard(
              icon: switch (role) {
                RoleKeys.player => 'ic_role_player_v3',
                RoleKeys.coach => 'ic_role_coach_v3',
                _ => 'ic_parent_role_v3',
              },
              iconSize: 40,
              title: _title(ref, l10n, role),
              // The description is server copy; there is no offline text.
              subtitle: ref.preMsg(_subKey(role), ''),
              selected: roles.contains(role),
              onChanged: () {
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
                ref.preMsg(
                  MessageKeys.preRoleRequiredTitle,
                  l10n.roleRequiredError,
                ),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
      ],
    );
  }
}
