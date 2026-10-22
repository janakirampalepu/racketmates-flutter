import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/security/device_integrity.dart';
import 'package:racketmates/common/startup/downtime.dart';

/// Something that stops the app from being used. While one is set the router
/// keeps the user on its screen (like a mandatory upgrade).
sealed class AppGate {
  const AppGate();
}

/// Rooted or jailbroken device: the app refuses to run (native `RootedActivity`).
class DeviceBlocked extends AppGate {
  const DeviceBlocked();
}

/// The API is down or in maintenance (native `CompleteDowntimeActivity`).
class Downtime extends AppGate {
  const Downtime(this.incident);

  final Incident incident;
}

class AppGateNotifier extends Notifier<AppGate?> {
  @override
  AppGate? build() => null;

  // Riverpod 3 notifiers expose state through a setter on the notifier itself.
  // ignore: use_setters_to_change_properties
  void set(AppGate? gate) => state = gate;
}

final appGateProvider = NotifierProvider<AppGateNotifier, AppGate?>(
  AppGateNotifier.new,
);

/// Runs the device and downtime checks. A compromised device ends the session
/// (native clears it before showing the warning) and blocks for good.
class AppGateChecker {
  AppGateChecker(this._ref);

  final Ref _ref;

  /// Root/jailbreak check. True (and the gate set) when blocked.
  Future<bool> checkDevice() async {
    if (_ref.read(appGateProvider) is DeviceBlocked) return true;
    if (!await _ref.read(deviceCompromisedCheckProvider)()) return false;
    await _ref.read(sessionControllerProvider.notifier).expire();
    _ref.read(appGateProvider.notifier).set(const DeviceBlocked());
    return true;
  }

  /// Downtime check. Returns the incident (and sets the gate) when the API is
  /// down; clears a downtime gate that no longer applies.
  Future<Incident?> checkDowntime() async {
    final incident = await _ref
        .read(downtimeRepositoryProvider)
        .currentIncident();
    final gate = _ref.read(appGateProvider);
    if (incident != null) {
      if (gate is! DeviceBlocked) {
        _ref.read(appGateProvider.notifier).set(Downtime(incident));
      }
    } else if (gate is Downtime) {
      _ref.read(appGateProvider.notifier).set(null);
    }
    return incident;
  }

  /// Both checks, for resuming the app. Does nothing during cold start (the
  /// splash runs them itself).
  Future<void> checkOnResume() async {
    if (_ref.read(sessionControllerProvider) is SessionRestoring) return;
    if (await checkDevice()) return;
    await checkDowntime();
  }
}

final appGateCheckerProvider = Provider<AppGateChecker>(AppGateChecker.new);
