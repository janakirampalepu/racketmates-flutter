import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/config/app_environment.dart';
import 'package:racketmates/common/auth/auth_api.dart';
import 'package:racketmates/common/auth/auth_interceptor.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/token_refresher.dart';
import 'package:racketmates/common/auth/token_store.dart';
import 'package:racketmates/common/config/config_providers.dart';
import 'package:racketmates/common/network/api_client.dart';
import 'package:racketmates/common/network/network_providers.dart';
import 'package:racketmates/common/session/session_info_controller.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());

Dio _baseDio(Ref ref) {
  final config = ref.watch(environmentConfigProvider);
  final dio = createDio(
    config,
    appVersion: ref.watch(appVersionProvider),
    // Native ships Chucker for every non-production build; matched here by
    // environment, not debug/release, so a QA or staging release build also
    // gets it.
    enableInspector: config.environment != AppEnvironment.production,
  )..httpClientAdapter = ref.watch(apiHttpClientAdapterProvider);
  ref.onDispose(dio.close);
  return dio;
}

/// Dio WITHOUT the auth interceptor: token/metadata endpoints.
final authDioProvider = Provider<Dio>(_baseDio);

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(authDioProvider)),
);

final tokenRefresherProvider = Provider<TokenRefresher>(
  (ref) => TokenRefresher(
    api: ref.watch(authApiProvider),
    store: ref.watch(tokenStoreProvider),
    config: ref.watch(environmentConfigProvider),
    onRefreshed: (_) =>
        unawaited(ref.read(sessionInfoControllerProvider.notifier).refresh()),
  ),
);

/// Authenticated Dio used by every Retrofit client except [AuthApi].
final apiDioProvider = Provider<Dio>((ref) {
  final dio = _baseDio(ref);
  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      store: ref.watch(tokenStoreProvider),
      refresher: ref.watch(tokenRefresherProvider),
      onSessionExpired: () =>
          ref.read(sessionControllerProvider.notifier).expire(),
    ),
  );
  return dio;
});
