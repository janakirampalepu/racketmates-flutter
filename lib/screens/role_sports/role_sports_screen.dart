import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/profile/roles_edit.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/sign_up/sport_labels.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/common/users/user_profile_provider.dart';
import 'package:racketmates/common/users/user_repository.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/profile/profile_test_ids.dart';

/// The sports of the player or coach role (native `PlayerSportsListFragment` /
/// `CoachSportsListFragment` in profile mode). A role needs a sport; a role
/// the user does not have yet is added when it is saved.
class RoleSportsScreen extends ConsumerWidget {
  const RoleSportsScreen({required this.role, super.key});

  final String role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(userProfileProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: TestId(
          RolesTestIds.sportsTitle,
          child: Semantics(
            header: true,
            child: Text(
              role == RoleKeys.coach
                  ? l10n.sportsCoachTitle
                  : l10n.sportsPlayerTitle,
            ),
          ),
        ),
      ),
      body: TestId(
        RolesTestIds.sportsRoot,
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(l10n.profileLoadError)),
          data: (user) => user == null
              ? Center(child: Text(l10n.profileLoadError))
              : _Form(user: user, role: role),
        ),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.user, required this.role});

  final AppUser user;
  final String role;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  late Set<SportKey> _selected = sportsOfRole(widget.user, widget.role);
  bool _missing = false;
  bool _saving = false;
  bool _failed = false;

  Future<void> _save() async {
    if (!sportsValid(_selected)) {
      setState(() => _missing = true);
      return;
    }
    final id = widget.user.id;
    if (id == null || _saving) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final existing = widget.user.roleOf(widget.role);
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      final repo = ref.read(userRepositoryProvider);
      final body = buildRoleSportsBody(widget.user, widget.role, _selected);
      if (existing?.id != null) {
        await repo.updateRole(id, existing!.id!, body);
      } else {
        await repo.addRole(id, body);
      }
      ref.invalidate(userProfileProvider);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            existing == null ? l10n.roleSportsAdded : l10n.roleSportsSaved,
          ),
        ),
      );
      context.pop();
    } on AppFailure {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final sport in SportKey.values)
          TestId(
            RolesTestIds.sport(sport.key),
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(sportLabel(l10n, sport)),
              value: _selected.contains(sport),
              onChanged: (v) => setState(() {
                _selected = {
                  for (final s in _selected)
                    if (s != sport) s,
                  if (v ?? false) sport,
                };
                _missing = false;
              }),
            ),
          ),
        if (_missing)
          TestId(
            RolesTestIds.sportsError,
            child: Semantics(
              liveRegion: true,
              child: Text(
                l10n.sportRequiredError,
                style: TextStyle(color: errorColor),
              ),
            ),
          ),
        if (_failed)
          TestId(
            RolesTestIds.sportsFailed,
            child: Semantics(
              liveRegion: true,
              child: Text(
                l10n.roleSportsFailed,
                style: TextStyle(color: errorColor),
              ),
            ),
          ),
        const SizedBox(height: 16),
        TestId(
          RolesTestIds.sportsSave,
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.roleSportsSave),
          ),
        ),
      ],
    );
  }
}
