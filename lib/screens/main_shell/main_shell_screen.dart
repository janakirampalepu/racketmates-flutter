import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/chat/chat_controller.dart';
import 'package:racketmates/common/widgets/native_widgets.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/main_shell/main_shell_test_ids.dart';

/// Bottom navigation host (native `MainActivity`): Home, Schedule, Chat, Teams.
/// Each tab keeps its own navigation stack and scroll state.
///
/// Native's own `BottomNavigationView` (`activity_main.xml`) and iOS's
/// `TabView` (`GlobalTabsView.swift`) are both **icon-only** —
/// `labelVisibilityMode="unlabeled"` on Android, an empty `Text("")` label
/// on iOS — flat (no selection pill/indicator), on the window background,
/// with a 1dp top divider at 50% alpha. Flutter's default `NavigationBar`
/// shows text labels and a rounded selection indicator; both are removed
/// here to match.
class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = context.native;
    final unread = ref.watch(chatUnreadProvider).value ?? 0;
    final l10n = AppLocalizations.of(context);
    final tabs = [
      (
        MainShellTestIds.navHome,
        'ic_nav_home_unchecked',
        'ic_nav_home_checked',
        l10n.navHome,
      ),
      (
        MainShellTestIds.navSchedule,
        'ic_nav_schedule_unchecked',
        'ic_nav_schedule_checked',
        l10n.navSchedule,
      ),
      (
        MainShellTestIds.navChat,
        'ic_nav_chat_unchecked',
        'ic_nav_chat_checked',
        l10n.navChat,
      ),
      (
        MainShellTestIds.navTeams,
        'ic_nav_teams_unchecked',
        'ic_nav_teams_checked',
        l10n.navTeams,
      ),
    ];
    return Scaffold(
      body: TestId(MainShellTestIds.root, child: navigationShell),
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
            onDestinationSelected: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            destinations: [
              for (final (id, icon, selected, label) in tabs)
                TestId(
                  id,
                  child: NavigationDestination(
                    icon: _badged(
                      l10n,
                      id,
                      SvgIcon(icon, size: 24, color: n.textSecondary),
                      unread,
                    ),
                    selectedIcon: _badged(
                      l10n,
                      id,
                      SvgIcon(selected, size: 24, color: n.imagePrimeryColor),
                      unread,
                    ),
                    label: label,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The unread count on the chat tab.
Widget _badged(AppLocalizations l10n, String id, Widget icon, int unread) {
  if (id != MainShellTestIds.navChat || unread <= 0) return icon;
  return Badge(
    label: Text(unread > 99 ? '99+' : '$unread'),
    child: Semantics(label: l10n.navChatUnread(unread), child: icon),
  );
}
