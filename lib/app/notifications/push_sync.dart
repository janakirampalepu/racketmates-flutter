import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/notifications/notification_navigator.dart';
import 'package:racketmates/app/router/app_router.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/notifications/push_models.dart';
import 'package:racketmates/common/notifications/push_platform.dart';
import 'package:racketmates/common/notifications/push_registrar.dart';
import 'package:racketmates/common/startup/app_gate.dart';
import 'package:racketmates/common/startup/pending_upgrade.dart';

/// The notification shown while the app is open (null = none).
class ForegroundPush extends Notifier<PushMessage?> {
  @override
  PushMessage? build() => null;

  // Riverpod 3 notifiers expose state through a setter on the notifier itself.
  // ignore: use_setters_to_change_properties
  void set(PushMessage? message) => state = message;
}

final foregroundPushProvider = NotifierProvider<ForegroundPush, PushMessage?>(
  ForegroundPush.new,
);

/// Wires push into the running app (watched once by the app): registers the
/// device when a session starts, keeps the token current, shows notifications
/// that arrive while the app is open, and opens the screen of a tapped one.
final pushSyncProvider = Provider<void>((ref) {
  final platform = ref.watch(pushPlatformProvider);
  final navigator = ref.read(notificationNavigatorProvider);

  // A notification that launched the app is kept until the user can be taken
  // there (it can be tapped before signing in).
  unawaited(
    platform.launchMessage().then((message) {
      if (message != null) navigator.handleOpened(message);
    }),
  );

  final subscriptions = [
    platform.tokens.listen((token) {
      unawaited(ref.read(pushRegistrarProvider).register(token));
    }),
    platform.openedMessages.listen(navigator.handleOpened),
    platform.foregroundMessages.listen((message) {
      if (ref.read(sessionControllerProvider) is SignedIn) {
        ref.read(foregroundPushProvider.notifier).set(message);
      }
    }),
  ];
  // The route that was waiting for startup to finish opens as soon as the
  // router lands somewhere it can.
  final router = ref.read(appRouterProvider);
  void onNavigated() => scheduleMicrotask(navigator.flushPending);
  router.routerDelegate.addListener(onNavigated);
  ref.onDispose(() {
    router.routerDelegate.removeListener(onNavigated);
    for (final s in subscriptions) {
      unawaited(s.cancel());
    }
  });

  ref
    ..listen(sessionControllerProvider, (previous, next) {
      if (next is SignedIn && previous is! SignedIn) {
        unawaited(ref.read(pushRegistrarProvider).start());
      }
      if (next is SignedIn) navigator.flushPending();
    }, fireImmediately: true)
    ..listen(appGateProvider, (_, _) => navigator.flushPending())
    ..listen(pendingUpgradeProvider, (_, _) => navigator.flushPending());
});
