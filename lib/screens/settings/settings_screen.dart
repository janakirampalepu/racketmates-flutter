import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/billing/billing_sync.dart';
import 'package:racketmates/common/links/external_links.dart';
import 'package:racketmates/common/session/session_info_controller.dart';
import 'package:racketmates/common/settings/logout.dart';
import 'package:racketmates/common/users/user_profile_provider.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/app_update/store_launcher.dart';
import 'package:racketmates/screens/settings/settings_test_ids.dart';

/// Settings (native `SettingsFragment`): who is signed in, the subscription
/// status, notification and reminder preferences, rating, and log out. The
/// profile editor, roles, favourite venues, sharing, contact, subscription
/// purchase and account deletion are later work.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loggingOut = false;

  Future<void> _logOut() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsLogoutTitle),
        content: Text(l10n.settingsLogoutMessage),
        actions: [
          TestId(
            SettingsTestIds.logoutCancel,
            child: TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.closeAction),
            ),
          ),
          TestId(
            SettingsTestIds.logoutConfirm,
            child: FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.settingsLogoutConfirm),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loggingOut = true);
    // The router moves to the welcome screen as soon as the session ends.
    await ref.read(logoutProvider)();
    if (mounted) setState(() => _loggingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(userProfileProvider).value;
    final session = ref.watch(sessionInfoControllerProvider);
    final user = session.user;
    final supportChannel = user?.supportChatRoomUrl;
    // Bought in a store (a trial has no store subscription yet).
    final paid = (user?.subscribedDeviceType ?? '').isNotEmpty;
    final name = [
      profile?.firstName,
      profile?.lastName,
    ].whereType<String>().join(' ').trim();
    final subscription = !session.loaded
        ? null
        : user!.isTrial
        ? l10n.settingsSubscriptionTrial(user.trialRemainingDays ?? 0)
        : user.isSubscribed
        ? l10n.settingsSubscriptionPremium
        : l10n.settingsSubscriptionFree;

    Widget tile({
      required String id,
      required IconData icon,
      required String title,
      String? subtitle,
      required VoidCallback onTap,
      Color? color,
    }) => TestId(
      id,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: color == null ? const Icon(Icons.chevron_right) : null,
        onTap: _loggingOut ? null : onTap,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: TestId(
          SettingsTestIds.title,
          child: Semantics(header: true, child: Text(l10n.settingsTitle)),
        ),
      ),
      body: TestId(
        SettingsTestIds.root,
        child: Stack(
          children: [
            ListView(
              children: [
                if (name.isNotEmpty || subscription != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (name.isNotEmpty)
                          TestId(
                            SettingsTestIds.name,
                            child: Text(
                              name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        if (subscription != null)
                          TestId(
                            SettingsTestIds.subscription,
                            child: Text(subscription),
                          ),
                      ],
                    ),
                  ),
                if (ref.watch(billingSupportedProvider))
                  tile(
                    id: SettingsTestIds.subscriptionTile,
                    icon: Icons.workspace_premium_outlined,
                    title: l10n.settingsSubscription,
                    subtitle: paid
                        ? l10n.settingsSubscriptionManage
                        : l10n.settingsSubscriptionPlans,
                    onTap: () => paid
                        ? ref
                              .read(externalLinksProvider)
                              .open(
                                defaultTargetPlatform == TargetPlatform.iOS
                                    ? SubscriptionLinks.manageApple
                                    : SubscriptionLinks.manageAndroid,
                              )
                        : context.push(AppRoutes.subscription),
                  ),
                tile(
                  id: SettingsTestIds.locations,
                  icon: Icons.place_outlined,
                  title: l10n.settingsLocations,
                  subtitle: l10n.settingsLocationsHint,
                  onTap: () => context.push(AppRoutes.locations),
                ),
                tile(
                  id: SettingsTestIds.profile,
                  icon: Icons.person_outline,
                  title: l10n.settingsProfile,
                  subtitle: l10n.settingsProfileHint,
                  onTap: () => context.push(AppRoutes.profile),
                ),
                tile(
                  id: SettingsTestIds.roles,
                  icon: Icons.sports_tennis,
                  title: l10n.settingsRoles,
                  subtitle: l10n.settingsRolesHint,
                  onTap: () => context.push(AppRoutes.roles),
                ),
                tile(
                  id: SettingsTestIds.notifications,
                  icon: Icons.notifications_outlined,
                  title: l10n.settingsNotifications,
                  subtitle: l10n.settingsNotificationsHint,
                  onTap: () => context.push(AppRoutes.notificationSettings),
                ),
                tile(
                  id: SettingsTestIds.reminders,
                  icon: Icons.alarm,
                  title: l10n.settingsReminders,
                  subtitle: l10n.settingsRemindersHint,
                  onTap: () => context.push(AppRoutes.eventReminders),
                ),
                if (supportChannel != null && supportChannel.isNotEmpty)
                  tile(
                    id: SettingsTestIds.support,
                    icon: Icons.support_agent,
                    title: l10n.settingsSupport,
                    subtitle: l10n.settingsSupportHint,
                    onTap: () =>
                        context.push(AppRoutes.chatChannelFor(supportChannel)),
                  ),
                tile(
                  id: SettingsTestIds.share,
                  icon: Icons.ios_share,
                  title: l10n.settingsShare,
                  subtitle: l10n.settingsShareHint,
                  onTap: () => context.push(AppRoutes.shareWithFriends),
                ),
                if (supportChannel == null || supportChannel.isEmpty)
                  tile(
                    id: SettingsTestIds.contact,
                    icon: Icons.mail_outline,
                    title: l10n.settingsContact,
                    subtitle: l10n.settingsContactHint,
                    onTap: () => context.push(AppRoutes.contactUs),
                  ),
                tile(
                  id: SettingsTestIds.rate,
                  icon: Icons.star_outline,
                  title: l10n.settingsRate,
                  onTap: () => ref.read(storeLauncherProvider).openStorePage(),
                ),
                const Divider(),
                tile(
                  id: SettingsTestIds.deleteAccount,
                  icon: Icons.delete_forever_outlined,
                  title: l10n.settingsDeleteAccount,
                  subtitle: l10n.settingsDeleteAccountHint,
                  onTap: () => context.push(AppRoutes.deleteAccount),
                ),
                tile(
                  id: SettingsTestIds.logout,
                  icon: Icons.logout,
                  title: l10n.settingsLogout,
                  color: Theme.of(context).colorScheme.error,
                  onTap: _logOut,
                ),
              ],
            ),
            if (_loggingOut)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: Center(
                    child: Semantics(
                      label: l10n.settingsLoggingOut,
                      child: const CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
