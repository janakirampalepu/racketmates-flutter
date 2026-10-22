import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/notifications/push_models.dart';
import 'package:racketmates/common/notifications/push_platform.dart';
import 'package:racketmates/common/notifications/push_registrar.dart';
import 'package:racketmates/common/notifications/push_status.dart';
import 'package:racketmates/common/settings/settings_repository.dart';
import 'package:racketmates/common/users/user_profile_provider.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/notification_settings/notification_settings_test_ids.dart';

/// Notification preferences (native `PushNotificationFragment`): whether push
/// notifications are on for this device, and the text-message consent.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  late final AppLifecycleListener _lifecycle;
  bool? _textConsent; // null until the user flips it: the profile's value shows
  bool _saving = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // Coming back from the system settings: show the new state.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(pushStatusProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _allow() async {
    final permission = await ref.read(pushPlatformProvider).requestPermission();
    if (permission == PushPermission.granted) {
      unawaited(ref.read(pushRegistrarProvider).start());
    }
    ref.invalidate(pushStatusProvider);
  }

  Future<void> _setTextConsent({required bool value}) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _textConsent = value;
      _saving = true;
      _failed = false;
    });
    try {
      await ref.read(settingsRepositoryProvider).setTextConsent(consent: value);
      if (!mounted) return;
      ref.invalidate(userProfileProvider);
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.notificationsSaved)));
    } on AppFailure {
      if (!mounted) return;
      setState(() {
        _textConsent = !value; // back to what the server has
        _saving = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(pushStatusProvider);
    final profile = ref.watch(userProfileProvider).value;
    final textConsent =
        _textConsent ?? profile?.consentForTextMessages ?? false;

    Widget push(PushStatus s) {
      if (!s.available) {
        return TestId(
          NotificationSettingsTestIds.pushHint,
          child: Text(l10n.notificationsPushUnavailable),
        );
      }
      final granted = s.permission == PushPermission.granted;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TestId(
            NotificationSettingsTestIds.pushStatus,
            child: Text(
              granted ? l10n.notificationsPushOn : l10n.notificationsPushOff,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (!granted) ...[
            const SizedBox(height: 4),
            TestId(
              NotificationSettingsTestIds.pushHint,
              child: Text(
                s.permission == PushPermission.notDetermined
                    ? l10n.notificationsPushNotAsked
                    : l10n.notificationsPushOffHint,
              ),
            ),
            const SizedBox(height: 8),
            if (s.permission == PushPermission.notDetermined)
              TestId(
                NotificationSettingsTestIds.allow,
                child: FilledButton(
                  onPressed: _allow,
                  child: Text(l10n.notificationsAllow),
                ),
              )
            else
              TestId(
                NotificationSettingsTestIds.openSettings,
                child: FilledButton(
                  onPressed: () =>
                      ref.read(pushPlatformProvider).openSettings(),
                  child: Text(l10n.notificationsOpenSettings),
                ),
              ),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: TestId(
          NotificationSettingsTestIds.title,
          child: Semantics(header: true, child: Text(l10n.notificationsTitle)),
        ),
      ),
      body: TestId(
        NotificationSettingsTestIds.root,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.notificationsPush,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            status.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Text(l10n.notificationsPushUnavailable),
              data: push,
            ),
            const Divider(height: 32),
            TestId(
              NotificationSettingsTestIds.textSwitch,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.notificationsText),
                subtitle: Text(l10n.notificationsTextHint),
                value: textConsent,
                onChanged: _saving ? null : (v) => _setTextConsent(value: v),
              ),
            ),
            if (_failed)
              TestId(
                NotificationSettingsTestIds.error,
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.notificationsFailed,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
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
