import 'package:dio/dio.dart';
import 'package:racketmates/common/auth/models/session_token.dart';
import 'package:racketmates/common/auth/token_refresher.dart';
import 'package:racketmates/common/auth/token_store.dart';

/// Adds `Authorization: Bearer <token>`, refreshes proactively when the stored
/// token is expired, and on HTTP 401 refreshes once and retries the request
/// (native `TokenInterceptor` behavior).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.dio,
    required this.store,
    required this.refresher,
    required this.onSessionExpired,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const _retriedKey = 'auth_retried';
  static const _tokenKey = 'auth_token_used';

  final Dio dio;
  final TokenStore store;
  final TokenRefresher refresher;
  final void Function() onSessionExpired;
  final DateTime Function() _now;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    var token = await store.read();
    if (token != null && token.hasRefreshToken && token.isExpiredAt(_now())) {
      switch (await refresher.refresh(staleAccessToken: token.accessToken)) {
        case Refreshed(token: final fresh):
          token = fresh;
        case SessionExpired():
          onSessionExpired();
        case RefreshFailed():
          break;
      }
    }
    _apply(options, token);
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final canRetry =
        err.response?.statusCode == 401 && request.extra[_retriedKey] != true;
    if (!canRetry) return handler.next(err);

    final used = request.extra[_tokenKey] as String?;
    switch (await refresher.refresh(staleAccessToken: used)) {
      case Refreshed(token: final fresh):
        request.extra[_retriedKey] = true;
        _apply(request, fresh);
        try {
          return handler.resolve(await dio.fetch<dynamic>(request));
        } on DioException catch (retryError) {
          return handler.next(retryError);
        }
      case SessionExpired():
        onSessionExpired();
        return handler.next(err);
      case RefreshFailed():
        return handler.next(err);
    }
  }

  void _apply(RequestOptions options, SessionToken? token) {
    final access = token?.accessToken;
    options.extra[_tokenKey] = access;
    if (access != null && access.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $access';
    } else {
      options.headers.remove('Authorization');
    }
  }
}
