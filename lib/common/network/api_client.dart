import 'dart:io';

import 'package:dio/dio.dart';
import 'package:racketmates/app/config/environment_config.dart';

/// Builds the single Dio instance shared by all Retrofit clients.
///
/// Reproduces the native header contract: `Accept` (API version),
/// `app-version` and `Accept-Language`. `Authorization: Bearer` and token
/// refresh are added by `AuthInterceptor` (see `common/auth/`).
Dio createDio(
  EnvironmentConfig config, {
  required String appVersion,
  String Function()? acceptLanguage,
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
  return dio;
}
