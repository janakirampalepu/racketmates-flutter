import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/widgets/native_widgets.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/team_shell/team_shell_test_ids.dart';

/// Team Context (native `TeamsHostActivity`, iOS `TeamTabView`): a
/// dedicated bottom-nav shell entered by tapping a team, mirroring the
/// global app shell (`MainShellScreen`) but scoped to one team. Three real
/// tabs — Team Home, Team Schedule, Team Chat — reuse the exact same icon
/// assets as the global shell (native's `teams_bottom_menu.xml` points at
/// the same `bottom_home_selection`/`bottom_schedule_selection`/
/// `bottom_chat_selection` drawables; iOS's `TeamTabView` reuses the same
/// tab images too).
///
/// The 4th item is not a tab: native's `team_close` menu entry and iOS's
/// `.gotoGlobalTeamList` case both just leave this context and land on the
/// global Teams tab (Android `finish()`s `TeamsHostActivity`; iOS calls
/// `showHomeScreen(selection: 3)`) — so it's wired to `context.go(AppRoutes.
/// teams)` instead of switching a branch, and is never the selected
/// destination.
class TeamShellScreen extends ConsumerWidget {
  const TeamShellScreen({
    required this.navigationShell,
    required this.teamId,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final int teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = context.native;
    final l10n = AppLocalizations.of(context);
    final tabs = [
      (
        TeamShellTestIds.navHome,
        'ic_nav_home_unchecked',
        'ic_nav_home_checked',
        l10n.navHome,
      ),
      (
        TeamShellTestIds.navSchedule,
        'ic_nav_schedule_unchecked',
        'ic_nav_schedule_checked',
        l10n.navSchedule,
      ),
      (
        TeamShellTestIds.navChat,
        'ic_nav_chat_unchecked',
        'ic_nav_chat_checked',
        l10n.navChat,
      ),
    ];
    return Scaffold(
      body: TestId(TeamShellTestIds.root, child: navigationShell),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(
            height: 1,
            thickness: 1,
            color: n.borderSolidPrimary.withValues(alpha: 0.5),
          ),
          NavigationBar(
            backgroundColor: n.windowBackgroundColor,
            elevation: 0,
            indicatorColor: Colors.transparent,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              if (index == tabs.length) {
                context.go(AppRoutes.teams);
                return;
              }
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            destinations: [
              for (final (id, icon, selected, label) in tabs)
                TestId(
                  id,
                  child: NavigationDestination(
                    icon: SvgIcon(icon, size: 24, color: n.textSecondary),
                    selectedIcon: SvgIcon(
                      selected,
                      size: 24,
                      color: n.imagePrimeryColor,
                    ),
                    label: label,
                  ),
                ),
              TestId(
                TeamShellTestIds.navClose,
                child: NavigationDestination(
                  // Always the same red icon, never "selected" (native's
                  // `ic_team_close_check` has no checked/unchecked state).
                  icon: const SvgIcon(
                    'ic_team_close',
                    size: 22,
                    color: Color(0xFFCE1126),
                  ),
                  label: l10n.exitTeamContext,
                  tooltip: l10n.exitTeamContext,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
