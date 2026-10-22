import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/config/config_providers.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/session/session_api.dart';
import 'package:racketmates/common/session/session_info_models.dart';
import 'package:racketmates/screens/splash/repositories/startup_repository.dart';

abstract class SessionInfoRepository {
  /// `GET session_info` for this app version on this platform.
  Future<SessionInfoResponse> fetch();

  /// `PUT update_time_zone` with the device's IANA time zone id.
  Future<void> updateTimeZone(String identifier);
}

class SessionInfoRepositoryImpl implements SessionInfoRepository {
  const SessionInfoRepositoryImpl(
    this.api, {
    required this.appType,
    required this.version,
  });

  final SessionApi api;
  final String appType;
  final String version;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapDioException(e);
    } on TypeError {
      throw const ParseFailure();
    }
  }

  @override
  Future<SessionInfoResponse> fetch() =>
      _guard(() => api.sessionInfo(appType: appType, version: version));

  @override
  Future<void> updateTimeZone(String identifier) =>
      _guard(() => api.updateTimeZone({'timezone_identifier': identifier}));
}

final sessionInfoRepositoryProvider = Provider<SessionInfoRepository>(
  (ref) => SessionInfoRepositoryImpl(
    SessionApi(ref.watch(apiDioProvider)),
    appType: platformAppType(defaultTargetPlatform),
    version: ref.watch(appVersionProvider),
  ),
);
