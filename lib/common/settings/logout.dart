import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/chat/chat_controller.dart';
import 'package:racketmates/common/notifications/push_registrar.dart';

/// Logs the user out: revokes this device's push token while requests are
/// still authorized, signs out of chat, then revokes the OAuth token and clears the session
/// (native `SettingsFragment`). Both revocations are best effort.
final logoutProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    await ref.read(pushRegistrarProvider).unregister();
    await ref.read(chatControllerProvider.notifier).disconnect();
    await ref.read(sessionControllerProvider.notifier).signOut();
  },
);
