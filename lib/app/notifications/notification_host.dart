import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/notifications/notification_navigator.dart';
import 'package:racketmates/app/notifications/push_sync.dart';
import 'package:racketmates/l10n/app_localizations.dart';

/// The messenger the app shows in-app notifications with (the app has no
/// screen of its own to attach them to).
final rootMessengerKeyProvider = Provider<GlobalKey<ScaffoldMessengerState>>(
  (ref) => GlobalKey<ScaffoldMessengerState>(),
);

/// Shows a notification that arrives while the app is open as a banner with a
/// "View" action (the system does not display those itself).
class NotificationHost extends ConsumerWidget {
  const NotificationHost({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(foregroundPushProvider, (_, message) {
      if (message == null) return;
      final messenger = ref.read(rootMessengerKeyProvider).currentState;
      final text = [
        message.title,
        message.body,
      ].where((s) => s != null && s.isNotEmpty).join('\n');
      if (messenger != null && text.isNotEmpty) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Semantics(liveRegion: true, child: Text(text)),
              action: SnackBarAction(
                label: AppLocalizations.of(context).notificationViewAction,
                onPressed: () => ref
                    .read(notificationNavigatorProvider)
                    .handleOpened(message),
              ),
            ),
          );
      }
      ref.read(foregroundPushProvider.notifier).set(null);
    });
    return child;
  }
}
