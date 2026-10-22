import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/auth_api.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/auth/models/app_metadata.dart';
import 'package:racketmates/common/config/config_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class StartupRepository {
  /// `GET resources/metadata`; null when it cannot be fetched (offline etc.):
  /// startup continues without the upgrade check, like the native app.
  Future<AppMetadata?> fetchMetadata();

  Future<String?> lastPromptedVersion();
  Future<void> setLastPromptedVersion(String version);
}

class StartupRepositoryImpl implements StartupRepository {
  StartupRepositoryImpl({
    required this.api,
    required this.clientId,
    required this.clientSecret,
    required this.appVersion,
    required this.appType,
    SharedPreferencesAsync? prefs,
  }) : _prefs = prefs ?? SharedPreferencesAsync();

  static const _promptedKey = 'next_app_version_number';

  final AuthApi api;
  final String clientId;
  final String clientSecret;
  final String appVersion;
  final String appType;
  final SharedPreferencesAsync _prefs;

  @override
  Future<AppMetadata?> fetchMetadata() async {
    try {
      return await api.metadata(clientId, clientSecret, appType, appVersion);
    } on DioException {
      // Offline, timeout or server error: metadata is advisory, never block
      // startup on it (same as the native app).
      return null;
    }
  }

  @override
  Future<String?> lastPromptedVersion() => _prefs.getString(_promptedKey);

  @override
  Future<void> setLastPromptedVersion(String version) =>
      _prefs.setString(_promptedKey, version);
}

/// `app_type` query value: native sends `android` / `ios`.
String platformAppType(TargetPlatform platform) =>
    platform == TargetPlatform.iOS ? 'ios' : 'android';

final startupRepositoryProvider = Provider<StartupRepository>((ref) {
  final config = ref.watch(environmentConfigProvider);
  return StartupRepositoryImpl(
    api: ref.watch(authApiProvider),
    clientId: config.oauthClientId,
    clientSecret: config.oauthClientSecret,
    appVersion: ref.watch(appVersionProvider),
    appType: platformAppType(defaultTargetPlatform),
  );
});
