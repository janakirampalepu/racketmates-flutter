import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/config/config_providers.dart';
import 'package:racketmates/app/config/app_environment.dart';

/// Detects a rooted (Android) or jailbroken (iOS) device. The native apps
/// refuse to run on such a device, clear the session and show a security
/// warning. The checks live in the platform code (`DeviceIntegrityPlugin` /
/// `DeviceIntegrityChecker`), ported from the native apps' checks.
abstract class DeviceIntegrity {
  /// True when the device looks rooted/jailbroken. [allowSimulator] lets a
  /// development build run on the iOS simulator (native: non-production).
  Future<bool> isCompromised({required bool allowSimulator});
}

class MethodChannelDeviceIntegrity implements DeviceIntegrity {
  const MethodChannelDeviceIntegrity();

  static const channel = MethodChannel(
    'io.appsmaker.racketmates/device_integrity',
  );

  @override
  Future<bool> isCompromised({required bool allowSimulator}) async {
    try {
      return await channel.invokeMethod<bool>('isCompromised', {
            'allowSimulator': allowSimulator,
          }) ??
          false;
    } on MissingPluginException {
      return false; // no platform code (tests, unsupported platform)
    } on PlatformException {
      // A failing check must not lock everyone out; the native apps also
      // carry on when a check throws.
      return false;
    }
  }
}

final deviceIntegrityProvider = Provider<DeviceIntegrity>(
  (ref) => const MethodChannelDeviceIntegrity(),
);

/// Development builds may run on a simulator; production never does.
bool allowSimulatorFor(AppEnvironment environment) =>
    environment != AppEnvironment.production;

/// Whether this device is rooted/jailbroken, with the environment's rules.
final deviceCompromisedCheckProvider = Provider<Future<bool> Function()>((ref) {
  final environment = ref.watch(environmentConfigProvider).environment;
  final integrity = ref.watch(deviceIntegrityProvider);
  return () =>
      integrity.isCompromised(allowSimulator: allowSimulatorFor(environment));
});
