import 'dart:io';

import 'package:dio/dio.dart';
import 'package:racketmates/app/config/environment_config.dart';

/// Builds the single Dio instance shared by all Retrofit clients.
///
/// Reproduces the native header contract: `Accept` (API version),
/// `app-version`, `Accept-Language` and `Authorization: Bearer`.
/// Token refresh (single-flight, one retry on 401, forced logout rules) is
/// added in the auth milestone; see CLAUDE.md section 1.4.
Dio createDio(
  EnvironmentConfig config, {
  required String appVersion,
  String? Function()? accessToken,
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
        final token = accessToken?.call();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );
  return dio;
}
