import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/router/app_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/notifications/push_models.dart';
import 'package:racketmates/common/startup/app_gate.dart';
import 'package:racketmates/common/startup/pending_upgrade.dart';

/// The destination of a tapped notification that could not be opened yet
/// (signed out, still starting, blocked by a gate).
class PendingNotificationRoute extends Notifier<NotificationRoute?> {
  @override
  NotificationRoute? build() => null;

  // Riverpod 3 notifiers expose state through a setter on the notifier itself.
  // ignore: use_setters_to_change_properties
  void set(NotificationRoute? route) => state = route;
}

final pendingNotificationRouteProvider =
    NotifierProvider<PendingNotificationRoute, NotificationRoute?>(
      PendingNotificationRoute.new,
    );

/// Opens the screen a notification points to. The same message can reach the
/// app through several paths (launch, tap, foreground banner), so each message
/// id is only handled once.
class NotificationNavigator {
  NotificationNavigator(this._ref);

  final Ref _ref;
  final List<String> _seen = [];
  static const _remembered = 20;

  /// Called when the user opens [message] (tapped it, or tapped "View" on the
  /// banner shown while the app was open).
  void handleOpened(PushMessage message) {
    final id = message.id;
    if (id != null) {
      if (_seen.contains(id)) return;
      _seen.add(id);
      if (_seen.length > _remembered) _seen.removeAt(0);
    }
    final route = routeForNotification(message.data);
    if (_ready) {
      _open(route);
    } else {
      _ref.read(pendingNotificationRouteProvider.notifier).set(route);
    }
  }

  /// The user can be taken somewhere: signed in, nothing blocks the app, and
  /// startup has landed on a signed-in screen (the splash and the sign-up
  /// steps would otherwise redirect straight over the destination).
  bool get _ready =>
      _ref.read(sessionControllerProvider) is SignedIn &&
      AppRoutes.isProtected(
        _ref
            .read(appRouterProvider)
            .routerDelegate
            .currentConfiguration
            .uri
            .path,
      ) &&
      _ref.read(appGateProvider) == null &&
      !(_ref.read(pendingUpgradeProvider)?.isMandatory ?? false);

  /// Opens a route kept while the app was not ready, once it is.
  void flushPending() {
    final pending = _ref.read(pendingNotificationRouteProvider);
    if (pending == null || !_ready) return;
    _ref.read(pendingNotificationRouteProvider.notifier).set(null);
    _open(pending);
  }

  void _open(NotificationRoute route) {
    final router = _ref.read(appRouterProvider);
    switch (route) {
      case OpenHome():
        router.go(AppRoutes.home);
      case OpenEvent(:final eventId):
        // Back from the event returns to home (native `fromNotifications`).
        router
          ..go(AppRoutes.home)
          ..push(AppRoutes.eventFor(eventId));
      case OpenTeam(:final teamId):
        router
          ..go(AppRoutes.teams)
          ..push(AppRoutes.teamFor(teamId));
      case OpenTeams():
        router.go(AppRoutes.teams);
      case OpenChat(:final channelUrl):
        router.go(AppRoutes.chat);
        if (channelUrl != null) {
          router.push(AppRoutes.chatChannelFor(channelUrl));
        }
    }
  }
}

final notificationNavigatorProvider = Provider<NotificationNavigator>(
  NotificationNavigator.new,
);
