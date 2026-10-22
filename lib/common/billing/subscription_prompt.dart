import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/router/app_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/billing/billing_sync.dart';
import 'package:racketmates/common/session/session_info_controller.dart';
import 'package:racketmates/common/session/session_info_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which reminder a user without a subscription gets.
enum SubscriptionPromptKind { trialEnding, trialEnded }

/// Days left from which the trial reminder shows (native `SEVEN_REMAIN_DAYS`).
const trialReminderDays = 7;

/// The reminder due for [user], if any: once while the trial has 1-7 days
/// left, once when it is over with nothing bought (native `MainActivity.
/// checkSubscriptionStatus`). A user who closed the reminder is not reminded
/// of the same stage again.
SubscriptionPromptKind? promptFor(
  SessionInfoUser? user, {
  required bool seenEnding,
  required bool seenEnded,
}) {
  if (user == null) return null;
  final days = user.trialRemainingDays ?? 0;
  if (user.isTrial && days >= 1 && days <= trialReminderDays && !seenEnding) {
    return SubscriptionPromptKind.trialEnding;
  }
  if (user.isTrialEnded &&
      (user.subscribedDeviceType ?? '').isEmpty &&
      !seenEnded) {
    return SubscriptionPromptKind.trialEnded;
  }
  return null;
}

/// Remembers, per user, which reminders were closed.
abstract class SubscriptionPromptStore {
  Future<bool> seen(SubscriptionPromptKind kind, int userId);
  Future<void> markSeen(SubscriptionPromptKind kind, int userId);
}

class PrefsSubscriptionPromptStore implements SubscriptionPromptStore {
  PrefsSubscriptionPromptStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  String _key(SubscriptionPromptKind kind) => switch (kind) {
    SubscriptionPromptKind.trialEnding => 'subs_alert_7_days_users',
    SubscriptionPromptKind.trialEnded => 'subs_alert_0_days_users',
  };

  @override
  Future<bool> seen(SubscriptionPromptKind kind, int userId) async =>
      (await _prefs.getStringList(_key(kind)))?.contains('$userId') ?? false;

  @override
  Future<void> markSeen(SubscriptionPromptKind kind, int userId) async {
    final users = [...?await _prefs.getStringList(_key(kind)), '$userId'];
    await _prefs.setStringList(_key(kind), users.toSet().toList());
  }
}

final subscriptionPromptStoreProvider = Provider<SubscriptionPromptStore>(
  (ref) => PrefsSubscriptionPromptStore(),
);

/// The reminder being shown, so closing the screen can record it.
class ShownPrompt extends Notifier<SubscriptionPromptKind?> {
  @override
  SubscriptionPromptKind? build() => null;

  // Riverpod 3 notifiers expose state through a setter on the notifier itself.
  // ignore: use_setters_to_change_properties
  void set(SubscriptionPromptKind? kind) => state = kind;
}

final shownPromptProvider =
    NotifierProvider<ShownPrompt, SubscriptionPromptKind?>(ShownPrompt.new);

/// Opens the subscription screen as a reminder when one is due (watched once
/// by the app). Waits until the user is on a signed-in screen, and shows at
/// most one reminder per launch.
final subscriptionPromptSyncProvider = Provider<void>((ref) {
  if (!ref.watch(billingSupportedProvider)) return;
  final router = ref.read(appRouterProvider);
  var shown = false;
  var checking = false;

  Future<void> check() async {
    if (shown || checking) return;
    final session = ref.read(sessionControllerProvider);
    final info = ref.read(sessionInfoControllerProvider);
    final userId = info.user?.id;
    if (session is! SignedIn || !info.loaded || userId == null) return;
    final location = router.routerDelegate.currentConfiguration.uri.path;
    // Not over a screen the user is in the middle of.
    if (!const {
      AppRoutes.home,
      AppRoutes.schedule,
      AppRoutes.chat,
      AppRoutes.teams,
    }.contains(location)) {
      return;
    }
    checking = true;
    try {
      final store = ref.read(subscriptionPromptStoreProvider);
      final kind = promptFor(
        info.user,
        seenEnding: await store.seen(
          SubscriptionPromptKind.trialEnding,
          userId,
        ),
        seenEnded: await store.seen(SubscriptionPromptKind.trialEnded, userId),
      );
      if (kind == null || shown || !ref.mounted) return;
      shown = true;
      ref.read(shownPromptProvider.notifier).set(kind);
      unawaited(router.push(AppRoutes.subscription));
    } finally {
      checking = false;
    }
  }

  void onNavigated() => unawaited(check());
  router.routerDelegate.addListener(onNavigated);
  ref
    ..onDispose(() => router.routerDelegate.removeListener(onNavigated))
    ..listen(
      sessionInfoControllerProvider,
      (_, _) => unawaited(check()),
      fireImmediately: true,
    );
});
