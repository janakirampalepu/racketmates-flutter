import 'package:dio/dio.dart';
import 'package:racketmates/app/config/environment_config.dart';
import 'package:racketmates/common/auth/auth_api.dart';
import 'package:racketmates/common/auth/models/session_token.dart';
import 'package:racketmates/common/auth/token_store.dart';

sealed class RefreshOutcome {
  const RefreshOutcome();
}

class Refreshed extends RefreshOutcome {
  const Refreshed(this.token);

  final SessionToken token;
}

/// Network/5xx/etc.: keep the session, fail only the request.
class RefreshFailed extends RefreshOutcome {
  const RefreshFailed();
}

/// Refresh rejected for good (HTTP 400, or repeated 401): sign the user out.
class SessionExpired extends RefreshOutcome {
  const SessionExpired();
}

/// Single-flight OAuth refresh reproducing the native semantics:
/// * `POST oauth/token` with `grant_type=refresh_token`;
/// * HTTP 400 -> session expired immediately;
/// * HTTP 401 -> retried, session expired after [maxUnauthorized] attempts
///   (native `MAX_UNAUTHORISED_API_CALLS_COUNT = 5`);
/// * any other failure -> [RefreshFailed] (no logout).
/// Unlike the native code (shared mutable flags, recursion), concurrent callers
/// share one in-flight refresh.
class TokenRefresher {
  TokenRefresher({
    required this.api,
    required this.store,
    required this.config,
    this.maxUnauthorized = 5,
  });

  static const refreshGrantType = 'refresh_token';

  final AuthApi api;
  final TokenStore store;
  final EnvironmentConfig config;
  final int maxUnauthorized;
  Future<RefreshOutcome>? _inFlight;

  /// [staleAccessToken] is the access token the failing request used; if the
  /// stored token already differs, another caller refreshed and no new
  /// refresh is made.
  Future<RefreshOutcome> refresh({String? staleAccessToken}) {
    final running = _inFlight;
    if (running != null) return running;
    final future = _refresh(staleAccessToken)
        .whenComplete(() => _inFlight = null);
    _inFlight = future;
    return future;
  }

  Future<RefreshOutcome> _refresh(String? stale) async {
    final current = await store.read();
    if (current == null || !current.hasRefreshToken) {
      return const SessionExpired();
    }
    if (stale != null && current.accessToken != stale) {
      return Refreshed(current);
    }
    for (var attempt = 1; attempt <= maxUnauthorized; attempt++) {
      try {
        final token = await api.token({
          'client_id': config.oauthClientId,
          'client_secret': config.oauthClientSecret,
          'grant_type': refreshGrantType,
          'refresh_token': current.refreshToken,
        });
        await store.write(token);
        return Refreshed(token);
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        if (status == 400) return const SessionExpired();
        if (status != 401) return const RefreshFailed();
      }
    }
    return const SessionExpired();
  }
}
