import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
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

/// The kids of a parent (native `KidsListFragment` / `EnableParentRoleFragment`
/// in profile mode): add, edit and remove, up to two. A user without kids is
/// offered the parent role by adding the first one; removing the last kid
/// turns the parent role off.
class KidsSettingsScreen extends ConsumerStatefulWidget {
  const KidsSettingsScreen({super.key});

  @override
  ConsumerState<KidsSettingsScreen> createState() => _KidsSettingsScreenState();
}

class _KidsSettingsScreenState extends ConsumerState<KidsSettingsScreen> {
  bool _busy = false;
  bool _removeFailed = false;

  Future<void> _open([int? id]) async {
    await context.push(AppRoutes.kidEditFor(id));
    ref.invalidate(userProfileProvider);
  }

  Future<void> _remove(AppUser kid, {required bool last}) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final id = kid.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.kidRemoveTitle(kid.displayName)),
        content: Text(
          last
              ? l10n.kidRemoveLastText(kid.displayName)
              : l10n.kidRemoveText(kid.displayName),
        ),
        actions: [
          TestId(
            KidsSettingsTestIds.confirmNo,
            child: TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.teamActionNo),
            ),
          ),
          TestId(
            KidsSettingsTestIds.confirmYes,
            child: FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.teamActionYes),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _removeFailed = false;
    });
    try {
      await ref.read(userRepositoryProvider).deleteUser(id);
      ref.invalidate(userProfileProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.kidRemoved)));
    } on AppFailure {
      if (mounted) setState(() => _removeFailed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(userProfileProvider);

    Widget body(AppUser user) {
      final kids = user.children ?? const <AppUser>[];
      if (kids.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: TestId(
            KidsSettingsTestIds.enable,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.family_restroom, size: 72),
                const SizedBox(height: 16),
                Text(
                  l10n.kidsEnableTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(l10n.kidsEnableText, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                TestId(
                  KidsSettingsTestIds.add,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => _open(),
                    child: Text(l10n.kidsEnableAction),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return ListView(
        children: [
          if (_busy) const LinearProgressIndicator(),
          for (final kid in kids)
            TestId(
              KidsSettingsTestIds.kid(kid.id ?? 0),
              child: ListTile(
                title: Text(kid.displayName),
                subtitle: Text(
                  [
                    for (final s in SportKey.values)
                      if (sportsOfRole(kid, RoleKeys.player).contains(s))
                        sportLabel(l10n, s),
                  ].join(', '),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TestId(
                      KidsSettingsTestIds.edit(kid.id ?? 0),
                      child: IconButton(
                        tooltip: l10n.kidEdit,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: _busy ? null : () => _open(kid.id),
                      ),
                    ),
                    TestId(
                      KidsSettingsTestIds.remove(kid.id ?? 0),
                      child: IconButton(
                        tooltip: l10n.kidRemove,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _busy
                            ? null
                            : () => _remove(kid, last: kids.length == 1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_removeFailed)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TestId(
                KidsSettingsTestIds.removeFailed,
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.kidRemoveFailed,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: kids.length >= maxKids
                ? TestId(
                    KidsSettingsTestIds.max,
                    child: Text(l10n.kidsMaxReached),
                  )
                : TestId(
                    KidsSettingsTestIds.add,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addKidAction),
                      onPressed: _busy ? null : () => _open(),
                    ),
                  ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: TestId(
          KidsSettingsTestIds.title,
          child: Semantics(header: true, child: Text(l10n.kidsTitle)),
        ),
      ),
      body: TestId(
        KidsSettingsTestIds.root,
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(l10n.profileLoadError)),
          data: (user) => user == null
              ? Center(child: Text(l10n.profileLoadError))
              : body(user),
        ),
      ),
    );
  }
}
