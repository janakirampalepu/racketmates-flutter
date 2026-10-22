import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/session/session_info_models.dart';
import 'package:racketmates/common/session/session_info_repository.dart';
import 'package:racketmates/common/sign_up/sign_up_flow.dart';

/// What `session_info` last said (empty until the first answer, or when signed
/// out).
class SessionInfoState {
  const SessionInfoState({this.user, this.subscription});

  final SessionInfoUser? user;
  final SessionSubscription? subscription;

  bool get loaded => user != null;

  /// Full access (subscribed or trial). Before the first answer: false, like
  /// the native `isSubscribedUser` default.
  bool get isSubscribed => user?.isSubscribed ?? false;
}

/// The server's zone is out of date when it has none or another one (native
/// `refreshSessionInfo`).
bool timezoneNeedsUpdate({String? server, required String device}) =>
    server == null || server.isEmpty || server != device;

/// Loads `current_session/session_info` and keeps the user's time zone in sync
/// with the device. Failures keep the previous answer: the permissions only
/// refine what the server enforces anyway.
class SessionInfoController extends Notifier<SessionInfoState> {
  bool _refreshing = false;

  @override
  SessionInfoState build() => const SessionInfoState();

  Future<void> refresh() async {
    if (_refreshing || ref.read(sessionControllerProvider) is! SignedIn) return;
    _refreshing = true;
    try {
      final repo = ref.read(sessionInfoRepositoryProvider);
      final response = await repo.fetch();
      if (!ref.mounted) return;
      state = SessionInfoState(
        user: response.user,
        subscription: response.subscription,
      );
      await _syncTimezone(response.user?.timezoneIdentifier);
    } on AppFailure {
      // Keep what is known; the next trigger tries again.
    } finally {
      _refreshing = false;
    }
  }

  /// `PUT update_time_zone` when the device's zone differs from the server's.
  /// A device whose zone cannot be read leaves the server's untouched.
  Future<void> _syncTimezone(String? server) async {
    final device = await ref.read(deviceTimezoneOrNullProvider.future);
    if (device == null || !ref.mounted) return;
    if (!timezoneNeedsUpdate(server: server, device: device)) return;
    try {
      await ref.read(sessionInfoRepositoryProvider).updateTimeZone(device);
    } on AppFailure {
      // Tried again on the next refresh.
    }
  }

  void clear() => state = const SessionInfoState();
}

final sessionInfoControllerProvider =
    NotifierProvider<SessionInfoController, SessionInfoState>(
      SessionInfoController.new,
    );

/// Keeps [sessionInfoControllerProvider] current: refreshes whenever a session
/// starts (launch, sign-in, restored session) and forgets everything on
/// sign-out. Watched once by the app; resume and token refresh call
/// `refresh` themselves.
final sessionInfoSyncProvider = Provider<void>((ref) {
  ref.listen(sessionControllerProvider, (previous, next) {
    final controller = ref.read(sessionInfoControllerProvider.notifier);
    if (next is SignedIn) {
      final changed =
          previous is! SignedIn ||
          previous.token.accessToken != next.token.accessToken;
      if (changed) unawaited(controller.refresh());
    } else if (next is SignedOut) {
      controller.clear();
    }
  }, fireImmediately: true);
});
