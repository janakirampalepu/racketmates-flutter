import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/config/config_providers.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/sign_up/sign_up_flow.dart';
import 'package:racketmates/common/support/support_api.dart';

/// The device facts sent with a request to support (native `UserFeedback`).
class DeviceDetails {
  const DeviceDetails({
    required this.manufacturer,
    required this.model,
    required this.platform,
    required this.platformVersion,
  });

  final String manufacturer;
  final String model;
  final String platform;
  final String platformVersion;
}

abstract class DeviceDetailsSource {
  Future<DeviceDetails> read();
}

class PlatformDeviceDetails implements DeviceDetailsSource {
  @override
  Future<DeviceDetails> read() async {
    final plugin = DeviceInfoPlugin();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = await plugin.iosInfo;
      return DeviceDetails(
        manufacturer: 'Apple',
        model: ios.utsname.machine,
        platform: 'ios',
        platformVersion: ios.systemVersion,
      );
    }
    final android = await plugin.androidInfo;
    return DeviceDetails(
      manufacturer: android.manufacturer,
      model: android.model,
      platform: 'android',
      platformVersion: '${android.version.sdkInt} (${android.version.release})',
    );
  }
}

final deviceDetailsSourceProvider = Provider<DeviceDetailsSource>(
  (ref) => PlatformDeviceDetails(),
);

/// Native `AppConstants.DELETE_USER_*`: an account deletion is a feedback with
/// this subject and text; support does the deleting.
abstract final class DeleteAccountRequest {
  static const subject = 'Delete My Account';
  static const feedback = 'Please delete my account at the earliest';
  static const fallbackEmail = 'noemail@gmail.com';
}

abstract class SupportRepository {
  /// Sends a message to support (or a deletion request) with the device facts.
  Future<void> sendFeedback({
    required String email,
    required String subject,
    required String feedback,
    String? mobileNumber,
  });
}

class SupportRepositoryImpl implements SupportRepository {
  const SupportRepositoryImpl(
    this.api, {
    required this.device,
    required this.appVersion,
    required this.timezone,
    required this.locale,
  });

  final SupportApi api;
  final DeviceDetailsSource device;
  final String appVersion;
  final Future<String?> Function() timezone;
  final String Function() locale;

  @override
  Future<void> sendFeedback({
    required String email,
    required String subject,
    required String feedback,
    String? mobileNumber,
  }) async {
    final details = await device.read();
    final zone = await timezone();
    try {
      await api.sendFeedback({
        'user_feedback': {
          'email': email,
          'subject': subject,
          'feedback': feedback,
          'mobile_number': mobileNumber,
          'device_manufacturer': details.manufacturer,
          'device_model': details.model,
          'device_platform': details.platform,
          'device_platform_version': details.platformVersion,
          'device_timezone': zone,
          'device_locale': locale(),
          'app_version': appVersion,
        },
      });
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => SupportRepositoryImpl(
    SupportApi(ref.watch(apiDioProvider)),
    device: ref.watch(deviceDetailsSourceProvider),
    appVersion: ref.watch(appVersionProvider),
    timezone: () => ref.read(deviceTimezoneOrNullProvider.future),
    locale: () =>
        WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag(),
  ),
);
