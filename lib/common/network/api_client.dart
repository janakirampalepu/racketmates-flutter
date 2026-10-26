import 'dart:io';

import 'package:dio/dio.dart';
import 'package:racketmates/app/config/environment_config.dart';
import 'package:racketmates/common/network/network_inspector.dart';

/// Builds the single Dio instance shared by all Retrofit clients.
///
/// Reproduces the native header contract: `Accept` (API version),
/// `app-version` and `Accept-Language`. `Authorization: Bearer` and token
/// refresh are added by `AuthInterceptor` (see `common/auth/`).
///
/// [enableInspector] attaches the in-app network viewer (native `Chucker`,
/// see `common/network/network_inspector.dart`). The caller (`_baseDio` in
/// `common/auth/auth_providers.dart`) passes `true` only outside the
/// production environment; the default here is `false` so a direct
/// `createDio()` call (as in `api_client_test.dart`, run outside a widget
/// tree) never touches it. Added right after the header interceptor below,
/// so it logs the request *before* `AuthInterceptor` (added separately, by
/// the caller) puts the bearer token on it — the token is never logged.
Dio createDio(
  EnvironmentConfig config, {
  required String appVersion,
  String Function()? acceptLanguage,
  bool enableInspector = false,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Accept'] = config.apiVersion;
        options.headers['app-version'] = appVersion;
        options.headers['Accept-Language'] =
            acceptLanguage?.call() ?? Platform.localeName.replaceAll('_', '-');
        handler.next(options);
      },
    ),
  );
  if (enableInspector) attachNetworkInspector(dio);
  return dio;
}
