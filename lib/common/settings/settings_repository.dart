import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/settings/reminder_rules.dart';
import 'package:racketmates/common/settings/settings_api.dart';
import 'package:racketmates/common/settings/settings_models.dart';

abstract class SettingsRepository {
  Future<List<ReminderPreference>> reminders(int userId);

  Future<void> addReminder(
    int userId, {
    required int value,
    required String unit,
  });

  Future<void> removeReminder(int userId, int reminderId);

  /// `PUT update_text_consent?text_consent=`.
  Future<void> setTextConsent({required bool consent});

  /// `POST register_device_token`. The two platforms differ (native): Android
  /// sends the FCM token form-encoded, iOS the raw APNs token as JSON; both
  /// carry the platform and the preferred language.
  Future<void> registerDeviceToken(
    String token, {
    required TargetPlatform platform,
    required String language,
  });

  /// `POST revoke_device_token {device_token}`.
  Future<void> revokeDeviceToken(String token);
}

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this.api);

  final SettingsApi api;

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
  Future<List<ReminderPreference>> reminders(int userId) async {
    final response = await _guard(() => api.reminders(userId));
    return response.userReminderPreferences
            ?.whereType<ReminderPreference>()
            .toList() ??
        const [];
  }

  @override
  Future<void> addReminder(
    int userId, {
    required int value,
    required String unit,
  }) => _guard(
    () =>
        api.createReminder(userId, buildReminderBody(value: value, unit: unit)),
  );

  @override
  Future<void> removeReminder(int userId, int reminderId) =>
      _guard(() => api.deleteReminder(userId, reminderId));

  @override
  Future<void> setTextConsent({required bool consent}) =>
      _guard(() => api.updateTextConsent(consent));

  @override
  Future<void> registerDeviceToken(
    String token, {
    required TargetPlatform platform,
    required String language,
  }) => _guard(
    () => platform == TargetPlatform.iOS
        ? api.registerDeviceTokenJson({
            'device_token': token,
            'platform': 'ios',
            'preferred_language': language,
          })
        : api.registerDeviceTokenForm(token, 'android', language),
  );

  @override
  Future<void> revokeDeviceToken(String token) =>
      _guard(() => api.revokeDeviceToken({'device_token': token}));
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(SettingsApi(ref.watch(apiDioProvider))),
);
