import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/auth/models/session_token.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/config/config_providers.dart';

/// Owns the signed-in/out state. Navigation reacts to it through the router's
/// redirect; widgets never navigate on logout themselves.
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() => const SessionRestoring();

  /// Reads the persisted session (cold start).
  Future<void> restore() async {
    final token = await ref.read(tokenStoreProvider).read();
    state = (token != null && token.hasRefreshToken)
        ? SignedIn(token)
        : const SignedOut();
  }

  Future<void> signedIn(SessionToken token) async {
    await ref.read(tokenStoreProvider).write(token);
    state = SignedIn(token);
  }

  /// User-initiated logout: best-effort `oauth/revoke`, then clear locally.
  /// Device-token revocation (`current_session/revoke_device_token`) belongs
  /// to the notifications module and must run before this call.
  Future<void> signOut() async {
    final current = state;
    await _clear();
    if (current is SignedIn && current.token.accessToken != null) {
      final config = ref.read(environmentConfigProvider);
      try {
        await ref.read(authApiProvider).revokeToken({
          'client_id': config.oauthClientId,
          'client_secret': config.oauthClientSecret,
          'token': current.token.accessToken,
        });
      } on DioException {
        // Local sign-out already happened; revocation is best-effort.
      }
    }
  }

  /// Refresh was rejected for good: clear locally, no remote calls
  /// (native `appUnauthorisedLogout`).
  Future<void> expire() async {
    if (state is SignedOut) return;
    await _clear();
  }

  Future<void> _clear() async {
    await ref.read(tokenStoreProvider).clear();
    state = const SignedOut();
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
