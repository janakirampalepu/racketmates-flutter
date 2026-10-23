import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/profile/roles_edit.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/sign_up/sport_labels.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/common/users/user_profile_provider.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/profile/profile_test_ids.dart';

/// The roles of the user and their sports (native settings role rows): player
/// and coach open their sports, parent opens the kids.
class MyRolesScreen extends ConsumerWidget {
  const MyRolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(userProfileProvider);

    Widget body(AppUser user) {
      String sportsText(String role) => [
        for (final s in SportKey.values)
          if (sportsOfRole(user, role).contains(s)) sportLabel(l10n, s),
      ].join(', ');
      final kids = user.children?.length ?? 0;

      Widget tile(
        String id,
        IconData icon,
        String title,
        String subtitle,
        String route,
      ) => TestId(
        id,
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context
              .push(route)
              .then((_) => ref.invalidate(userProfileProvider)),
        ),
      );

      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(l10n.rolesHint),
          ),
          tile(
            RolesTestIds.player,
            Icons.sports_tennis,
            l10n.rolePlayer,
            user.roleOf(RoleKeys.player) == null
                ? l10n.roleNotActive
                : l10n.roleActiveSports(sportsText(RoleKeys.player)),
            AppRoutes.roleSportsFor(RoleKeys.player),
          ),
          tile(
            RolesTestIds.coach,
            Icons.school_outlined,
            l10n.roleCoach,
            user.roleOf(RoleKeys.coach) == null
                ? l10n.roleNotActive
                : l10n.roleActiveSports(sportsText(RoleKeys.coach)),
            AppRoutes.roleSportsFor(RoleKeys.coach),
          ),
          tile(
            RolesTestIds.parent,
            Icons.family_restroom,
            l10n.roleParent,
            kids == 0 ? l10n.roleNotActive : l10n.roleParentKids(kids),
            AppRoutes.kids,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: TestId(
          RolesTestIds.title,
          child: Semantics(header: true, child: Text(l10n.rolesTitle)),
        ),
      ),
      body: TestId(
        RolesTestIds.root,
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              _LoadError(onRetry: () => ref.invalidate(userProfileProvider)),
          data: (user) => user == null
              ? _LoadError(onRetry: () => ref.invalidate(userProfileProvider))
              : body(user),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TestId(RolesTestIds.loadError, child: Text(l10n.profileLoadError)),
          TestId(
            RolesTestIds.retry,
            child: TextButton(
              onPressed: onRetry,
              child: Text(l10n.retryAction),
            ),
          ),
        ],
      ),
    );
  }
}
