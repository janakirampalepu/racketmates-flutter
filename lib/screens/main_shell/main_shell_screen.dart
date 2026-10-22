import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/chat/chat_controller.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/main_shell/main_shell_test_ids.dart';

/// Bottom navigation host (native `MainActivity`): Home, Schedule, Chat, Teams.
/// Each tab keeps its own navigation stack and scroll state.
class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(chatUnreadProvider).value ?? 0;
    final l10n = AppLocalizations.of(context);
    final tabs = [
      (MainShellTestIds.navHome, Icons.home_outlined, Icons.home, l10n.navHome),
      (
        MainShellTestIds.navSchedule,
        Icons.calendar_month_outlined,
        Icons.calendar_month,
        l10n.navSchedule,
      ),
      (
        MainShellTestIds.navChat,
        Icons.chat_bubble_outline,
        Icons.chat_bubble,
        l10n.navChat,
      ),
      (
        MainShellTestIds.navTeams,
        Icons.groups_outlined,
        Icons.groups,
        l10n.navTeams,
      ),
    ];
    return Scaffold(
      body: TestId(MainShellTestIds.root, child: navigationShell),
      bottomNavigationBar: NavigationBar(
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
                icon: _badged(l10n, id, Icon(icon), unread),
                selectedIcon: _badged(l10n, id, Icon(selected), unread),
                label: label,
              ),
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
