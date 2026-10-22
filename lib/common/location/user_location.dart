import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/location/location_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserLocationState {
  const UserLocationState({
    this.permission = LocationPermission.notDetermined,
    this.position,
    this.loading = false,
  });

  final LocationPermission permission;

  /// The last fix; null until one was read (or when it cannot be).
  final LatLng? position;
  final bool loading;

  bool get known => position != null;
}

/// Where the user is (native `checkLocationPermission` + `AppGlobals.mLocation`):
/// the system asks once, a refusal is remembered by the system, and the app
/// then works without a position (searches are by text only).
class UserLocation extends Notifier<UserLocationState> {
  @override
  UserLocationState build() => const UserLocationState();

  LocationPlatform get _platform => ref.read(locationPlatformProvider);

  /// Reads the permission and, when granted (asking first while undecided),
  /// the position. Cheap to call again: a known position is kept unless
  /// [refresh] is set.
  Future<void> ensure({bool refresh = false}) async {
    if (state.loading || (state.known && !refresh)) return;
    state = UserLocationState(
      permission: state.permission,
      position: state.position,
      loading: true,
    );
    var permission = await _platform.permission();
    if (permission == LocationPermission.notDetermined) {
      permission = await _platform.requestPermission();
    }
    final position = permission == LocationPermission.granted
        ? await _platform.currentPosition()
        : null;
    if (!ref.mounted) return;
    state = UserLocationState(permission: permission, position: position);
  }

  /// After the user changed the permission in the system settings.
  Future<void> recheck() => ensure(refresh: true);

  Future<void> openSettings() => _platform.openSettings();
}

final userLocationProvider = NotifierProvider<UserLocation, UserLocationState>(
  UserLocation.new,
);

/// Default search radius (native `DEFAULT_DISTANCE`).
const defaultSearchDistance = 30;

/// Remembers the chosen search radius (native `LOCATION_FILTER_DISTANCE_RANGE`).
abstract class DistanceFilterStore {
  Future<int> read();
  Future<void> write(int distance);
}

class PrefsDistanceFilterStore implements DistanceFilterStore {
  PrefsDistanceFilterStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _key = 'location_filter_distance';
  final SharedPreferencesAsync _prefs;

  @override
  Future<int> read() async =>
      await _prefs.getInt(_key) ?? defaultSearchDistance;

  @override
  Future<void> write(int distance) => _prefs.setInt(_key, distance);
}

final distanceFilterStoreProvider = Provider<DistanceFilterStore>(
  (ref) => PrefsDistanceFilterStore(),
);

/// The search radius in the user's distance unit.
class SearchDistance extends AsyncNotifier<int> {
  @override
  Future<int> build() => ref.read(distanceFilterStoreProvider).read();

  Future<void> set(int distance) async {
    state = AsyncData(distance);
    await ref.read(distanceFilterStoreProvider).write(distance);
  }

  Future<void> reset() => set(defaultSearchDistance);
}

final searchDistanceProvider = AsyncNotifierProvider<SearchDistance, int>(
  SearchDistance.new,
);
