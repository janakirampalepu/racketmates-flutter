import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/billing/billing_sync.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/links/external_links.dart';
import 'package:racketmates/common/profile/roles_edit.dart';
import 'package:racketmates/common/session/session_info_controller.dart';
import 'package:racketmates/common/settings/logout.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/sign_up/sport_labels.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/common/users/user_profile_provider.dart';
import 'package:racketmates/common/widgets/native_widgets.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/app_update/store_launcher.dart';
import 'package:racketmates/screens/profile/profile_test_ids.dart';
import 'package:racketmates/screens/settings/settings_test_ids.dart';

/// Settings (native `ProfileSettingsView`): a profile header card with the
/// user's avatar, name and inline role rows (player/coach/parent), then
/// Account, Preferences and App sections of bordered rows, and finally the
/// sign-out/delete-account footer buttons.
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

  void _openHelp(String? supportChannel) {
    if (supportChannel != null && supportChannel.isNotEmpty) {
      context.push(AppRoutes.chatChannelFor(supportChannel));
    } else {
      // Native silently no-ops when there's no support room; a contact
      // form is a more useful fallback than a dead tap.
      context.push(AppRoutes.contactUs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final sdp = context.sdp;
    final profile = ref.watch(userProfileProvider).value;
    final session = ref.watch(sessionInfoControllerProvider);
    final user = session.user;
    final supportChannel = user?.supportChatRoomUrl;
    // Bought in a store (a trial has no store subscription yet).
    final paid = (user?.subscribedDeviceType ?? '').isNotEmpty;
    final premium = session.loaded && user!.isSubscribed && !user.isTrial;
    final subscriptionBadge = !session.loaded
        ? null
        : user!.isTrial
        ? l10n.settingsSubscriptionTrial(user.trialRemainingDays ?? 0)
        : user.isSubscribed
        ? ref.msg(
            MessageKeys.settingsSubscriptionPremiumText,
            l10n.settingsSubscriptionPremium,
          )
        : ref.msg(
            MessageKeys.settingsSubscriptionFreeText,
            l10n.settingsSubscriptionFree,
          );
    final phone = profile?.mobileNumber;
    final countryCode = profile?.country?.code;
    final phoneDisplay = (phone == null || phone.isEmpty)
        ? ''
        : (countryCode != null && countryCode.isNotEmpty
              ? '+$countryCode $phone'
              : phone);

    Widget sectionTitle(String text, {String? trailing}) => Padding(
      padding: EdgeInsets.only(bottom: sdp(12)),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              color: n.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            Text(trailing, style: TextStyle(color: n.textSecondary)),
        ],
      ),
    );

    Widget row({
      required String id,
      required IconData icon,
      required String title,
      Widget? trailing,
      bool externalLink = false,
      VoidCallback? onTap,
    }) => TestId(
      id,
      child: InkWell(
        borderRadius: BorderRadius.circular(sdp(12)),
        onTap: _loggingOut ? null : onTap,
        child: Container(
          padding: EdgeInsets.all(sdp(16)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(sdp(12)),
            border: Border.all(color: n.borderSolidPrimary),
          ),
          child: Row(
            children: [
              Icon(icon, color: n.iconPrimary, size: sdp(24)),
              SizedBox(width: sdp(12)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: n.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null) ...[SizedBox(width: sdp(12)), trailing],
              SizedBox(width: sdp(12)),
              Icon(
                externalLink ? Icons.open_in_new : Icons.chevron_right,
                color: n.iconPrimary,
                size: sdp(externalLink ? 20 : 18),
              ),
            ],
          ),
        ),
      ),
    );

    Widget section(
      String title, {
      String? versionText,
      required List<Widget> children,
    }) => Padding(
      padding: EdgeInsets.fromLTRB(sdp(16), 0, sdp(16), sdp(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle(title, trailing: versionText),
          for (final (i, child) in children.indexed) ...[
            if (i > 0) SizedBox(height: sdp(12)),
            child,
          ],
        ],
      ),
    );

    return Scaffold(
      backgroundColor: n.backgroundSolidPrimary,
      appBar: AppBar(
        backgroundColor: n.backgroundSolidPrimary,
        automaticallyImplyLeading: false,
        leading: BackButton(
          onPressed: () => context.pop(),
          color: n.iconPrimary,
        ),
        title: TestId(
          SettingsTestIds.title,
          child: Semantics(
            header: true,
            child: Text(
              ref.msg(MessageKeys.settingsNavTitle, l10n.settingsTitle),
            ),
          ),
        ),
        actions: [
          TestId(
            SettingsTestIds.help,
            child: IconButton(
              tooltip: l10n.settingsHelp,
              icon: Icon(Icons.contact_support_outlined, color: n.iconPrimary),
              onPressed: () => _openHelp(supportChannel),
            ),
          ),
        ],
      ),
      body: TestId(
        SettingsTestIds.root,
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(sdp(16), sdp(16), sdp(16), sdp(24)),
              children: [
                _ProfileHeaderCard(profile: profile),
                SizedBox(height: sdp(24)),
                section(
                  ref.msg(
                    MessageKeys.settingsAccountGroupLabel,
                    l10n.settingsAccount,
                  ),
                  children: [
                    row(
                      id: SettingsTestIds.myNumber,
                      icon: Icons.phone_iphone_outlined,
                      title: ref.msg(
                        MessageKeys.settingsChangePhoneNumberTitle,
                        l10n.settingsMyNumber,
                      ),
                      trailing: Text(
                        phoneDisplay,
                        style: TextStyle(color: n.textSecondary),
                      ),
                      onTap: () => context.push(AppRoutes.changePhone),
                    ),
                    row(
                      id: SettingsTestIds.locations,
                      icon: Icons.place_outlined,
                      title: ref.msg(
                        MessageKeys.settingsMyFavoriteVenuesOptionTitle,
                        l10n.settingsFavoriteVenues,
                      ),
                      onTap: () => context.push(AppRoutes.locations),
                    ),
                  ],
                ),
                section(
                  ref.msg(
                    MessageKeys.settingsPersonalizationGroupLabel,
                    l10n.settingsPreferencesGroupLabel,
                  ),
                  children: [
                    row(
                      id: SettingsTestIds.reminders,
                      icon: Icons.calendar_today_outlined,
                      title: ref.msg(
                        MessageKeys.settingsEventRemindersOptionTitle,
                        l10n.settingsReminders,
                      ),
                      onTap: () => context.push(AppRoutes.eventReminders),
                    ),
                    row(
                      id: SettingsTestIds.notifications,
                      icon: Icons.notifications_outlined,
                      title: ref.msg(
                        MessageKeys.settingsNotificationsOptionTitle,
                        l10n.settingsNotifications,
                      ),
                      onTap: () => context.push(AppRoutes.notificationSettings),
                    ),
                  ],
                ),
                section(
                  ref.msg(
                    MessageKeys.settingsAppGroupLabel,
                    l10n.settingsAppGroupLabel,
                  ),
                  versionText: ref.watch(_appVersionProvider).value,
                  children: [
                    if (ref.watch(billingSupportedProvider))
                      row(
                        id: SettingsTestIds.subscriptionTile,
                        icon: Icons.workspace_premium_outlined,
                        title: ref.msg(
                          MessageKeys.settingsSubscriptionOptionTitle,
                          l10n.settingsSubscription,
                        ),
                        trailing: subscriptionBadge == null
                            ? null
                            : _SubscriptionBadge(
                                text: subscriptionBadge,
                                premium: premium,
                              ),
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
                    row(
                      id: SettingsTestIds.share,
                      icon: Icons.ios_share,
                      title: ref.msg(
                        MessageKeys.settingsShareWithFriendsOptionTitle,
                        l10n.settingsShare,
                      ),
                      onTap: () => context.push(AppRoutes.shareWithFriends),
                    ),
                    row(
                      id: SettingsTestIds.rate,
                      icon: Icons.star_outline,
                      title: ref.msg(
                        MessageKeys.settingsRateRacketmatesOptionTitle,
                        l10n.settingsRate,
                      ),
                      externalLink: true,
                      onTap: () =>
                          ref.read(storeLauncherProvider).openStorePage(),
                    ),
                    if (supportChannel != null && supportChannel.isNotEmpty)
                      row(
                        id: SettingsTestIds.support,
                        icon: Icons.support_agent,
                        title: ref.msg(
                          MessageKeys.settingsContactUsOptionTitle,
                          l10n.settingsContact,
                        ),
                        onTap: () => context.push(
                          AppRoutes.chatChannelFor(supportChannel),
                        ),
                      )
                    else
                      row(
                        id: SettingsTestIds.contact,
                        icon: Icons.support_agent,
                        title: ref.msg(
                          MessageKeys.settingsContactUsOptionTitle,
                          l10n.settingsContact,
                        ),
                        onTap: () => context.push(AppRoutes.contactUs),
                      ),
                  ],
                ),
                TestId(
                  SettingsTestIds.logout,
                  child: _FooterButton(
                    icon: Icons.logout,
                    label: ref.msg(
                      MessageKeys.settingsLogoutButton,
                      l10n.signOutAction,
                    ),
                    background: n.backgroundSolidSecondary2,
                    foreground: n.textPrimary,
                    iconColor: n.iconPrimary,
                    onTap: _logOut,
                  ),
                ),
                SizedBox(height: sdp(12)),
                TestId(
                  SettingsTestIds.deleteAccount,
                  child: _FooterButton(
                    icon: Icons.delete_outline,
                    label: ref.msg(
                      MessageKeys.settingsDeleteAccountButton,
                      l10n.settingsDeleteAccount,
                    ),
                    background: n.statusColorsDarkRed,
                    foreground: n.textPrimary,
                    iconColor: n.statusColorsLightRed,
                    onTap: () => context.push(AppRoutes.deleteAccount),
                  ),
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

/// `{versionName}({versionCode})` (native `Bundle.appVersionAndBuildNumber`)
/// — not server-driven, there is nothing to fetch it from.
final _appVersionProvider = FutureProvider.autoDispose<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version}(${info.buildNumber})';
});

/// The avatar + edit icon + name/email + inline Player/Coach/Parent rows
/// (native `profileHeaderCard`): one card, the avatar overlapping its top
/// edge.
class _ProfileHeaderCard extends ConsumerWidget {
  const _ProfileHeaderCard({required this.profile});

  final AppUser? profile;

  static const _avatarSize = 64.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final sdp = context.sdp;
    final avatarRadius = sdp(_avatarSize) / 2;

    Widget divider() => Container(height: 1, color: n.borderSolidPrimary);

    Widget roleRow({
      required String id,
      required IconData icon,
      required Color iconColor,
      required String title,
      required String subtitle,
      required Widget? badge,
      required bool inactive,
      required VoidCallback onTap,
    }) => TestId(
      id,
      child: InkWell(
        borderRadius: BorderRadius.circular(sdp(8)),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: sdp(12), vertical: sdp(10)),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: sdp(32)),
              SizedBox(width: sdp(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: n.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: n.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (badge != null) ...[badge, SizedBox(width: sdp(4))],
              Icon(
                inactive ? Icons.add_circle_outline : Icons.chevron_right,
                color: n.iconPrimary,
                size: sdp(inactive ? 22 : 18),
              ),
            ],
          ),
        ),
      ),
    );

    // A still-loading or failed profile fetch shouldn't block this whole
    // card behind a spinner (nothing here, including the edit button to
    // the screen that reports that failure, needs the profile to render) —
    // render it with empty fields instead, same leniency the rest of this
    // screen already has for a null profile.
    final user = profile ?? const AppUser();
    final name = [
      user.firstName,
      user.lastName,
    ].whereType<String>().join(' ').trim();
    final hasPlayer = user.roleOf(RoleKeys.player) != null;
    final hasCoach = user.roleOf(RoleKeys.coach) != null;
    final kids = user.children ?? const <AppUser>[];

    String sportsText(String role) => [
      for (final s in SportKey.values)
        if (sportsOfRole(user, role).contains(s)) sportLabel(l10n, s),
    ].join(', ');

    Widget sportIcons(String role) {
      final sports = [
        for (final s in SportKey.values)
          if (sportsOfRole(user, role).contains(s)) s,
      ];
      if (sports.isEmpty) return const SizedBox.shrink();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in sports)
            Padding(
              padding: EdgeInsets.only(left: sdp(4)),
              child: SvgIcon(
                sportIconName(s),
                size: sdp(20),
                color: n.iconPrimary,
              ),
            ),
        ],
      );
    }

    Widget kidAvatars() {
      if (kids.isEmpty) return const SizedBox.shrink();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final kid in kids.take(3))
            Padding(
              padding: EdgeInsets.only(left: sdp(4)),
              child: _InitialsAvatar(user: kid, size: sdp(28)),
            ),
        ],
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: EdgeInsets.only(top: avatarRadius),
          decoration: BoxDecoration(
            color: n.backgroundSolidSecondary2,
            borderRadius: BorderRadius.circular(sdp(16)),
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TestId(
                  SettingsTestIds.profile,
                  child: IconButton(
                    tooltip: l10n.settingsProfile,
                    icon: Icon(Icons.edit_outlined, color: n.iconPrimary),
                    onPressed: () => context.push(AppRoutes.profile),
                  ),
                ),
              ),
              SizedBox(height: avatarRadius),
              TestId(
                SettingsTestIds.name,
                child: Text(
                  name,
                  style: TextStyle(
                    color: n.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if ((user.email ?? '').isNotEmpty)
                Text(user.email!, style: TextStyle(color: n.textSecondary)),
              SizedBox(height: sdp(12)),
              divider(),
              roleRow(
                id: RolesTestIds.player,
                icon: Icons.sports_tennis,
                iconColor: hasPlayer ? n.iconPrimary : n.textTertiary,
                title: l10n.rolePlayer,
                subtitle: hasPlayer
                    ? l10n.roleActiveSports(sportsText(RoleKeys.player))
                    : ref.msg(
                        MessageKeys.settingsNotAPlayerText,
                        l10n.roleNotActive,
                      ),
                badge: hasPlayer ? sportIcons(RoleKeys.player) : null,
                inactive: !hasPlayer,
                onTap: () =>
                    context.push(AppRoutes.roleSportsFor(RoleKeys.player)),
              ),
              divider(),
              roleRow(
                id: RolesTestIds.coach,
                icon: Icons.school_outlined,
                iconColor: hasCoach ? n.iconPrimary : n.textTertiary,
                title: l10n.roleCoach,
                subtitle: hasCoach
                    ? l10n.roleActiveSports(sportsText(RoleKeys.coach))
                    : ref.msg(
                        MessageKeys.settingsNotACoachText,
                        l10n.roleNotActive,
                      ),
                badge: hasCoach ? sportIcons(RoleKeys.coach) : null,
                inactive: !hasCoach,
                onTap: () =>
                    context.push(AppRoutes.roleSportsFor(RoleKeys.coach)),
              ),
              divider(),
              roleRow(
                id: RolesTestIds.parent,
                icon: Icons.family_restroom,
                iconColor: kids.isNotEmpty ? n.iconPrimary : n.textTertiary,
                title: l10n.roleParent,
                subtitle: kids.isEmpty
                    ? ref.msg(
                        MessageKeys.settingsNotAParentText,
                        l10n.roleNotActive,
                      )
                    : l10n.roleParentKids(kids.length),
                badge: kidAvatars(),
                inactive: kids.isEmpty,
                onTap: () => context.push(AppRoutes.kids),
              ),
              SizedBox(height: sdp(8)),
            ],
          ),
        ),
        _InitialsAvatar(user: user, size: sdp(_avatarSize)),
      ],
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.user, required this.size});

  final AppUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    String first(String? s) =>
        (s == null || s.trim().isEmpty) ? '' : s.trim()[0].toUpperCase();
    final url = user.thumbnailAttachmentUrl ?? user.avatarFileAttachmentUrl;
    final initials = Text(
      '${first(user.firstName)}${first(user.lastName)}',
      style: TextStyle(
        color: n.imagePrimeryColor,
        fontWeight: FontWeight.bold,
        fontSize: size * 0.36,
      ),
    );
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: n.avatarBgColor),
      clipBehavior: Clip.antiAlias,
      child: (url == null || url.isEmpty)
          ? initials
          : Image.network(
              url,
              fit: BoxFit.cover,
              // A broken/unreachable photo falls back to initials rather
              // than an uncaught image-load exception.
              errorBuilder: (context, error, stackTrace) => initials,
            ),
    );
  }
}

/// The "Free"/"Premium" pill next to the Subscription row.
class _SubscriptionBadge extends StatelessWidget {
  const _SubscriptionBadge({required this.text, required this.premium});

  final String text;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: sdp(8), vertical: sdp(4)),
      decoration: BoxDecoration(
        color: premium ? n.backgroundSolidGreen3 : n.statusColorsDarkGray,
        borderRadius: BorderRadius.circular(sdp(32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            premium ? Icons.star : Icons.check_circle_outline,
            size: sdp(12),
            color: n.textPrimary,
          ),
          SizedBox(width: sdp(4)),
          Text(text, style: TextStyle(color: n.textPrimary, fontSize: 12)),
        ],
      ),
    );
  }
}

/// A full-width pill button (native `logoutView`/`deleteAccountView`).
class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sdp = context.sdp;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(sdp(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(sdp(16)),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: sdp(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: sdp(18), color: iconColor),
              SizedBox(width: sdp(12)),
              Text(label, style: TextStyle(color: foreground)),
            ],
          ),
        ),
      ),
    );
  }
}
