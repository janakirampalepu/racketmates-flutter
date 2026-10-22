import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LocationPermission { granted, denied, notDetermined }

/// A position on the map.
class LatLng {
  const LatLng(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is LatLng &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

/// The device location behind a channel (`io.appsmaker.racketmates/location`):
/// permission while the app is in use and one position fix. Android uses the
/// platform location manager, iOS Core Location.
abstract class LocationPlatform {
  Future<LocationPermission> permission();

  /// Asks the user (the system only prompts while undecided).
  Future<LocationPermission> requestPermission();

  /// The current position, or null when it cannot be read (location services
  /// off, no fix, no permission).
  Future<LatLng?> currentPosition();

  /// Opens the system settings of this app.
  Future<void> openSettings();
}

class ChannelLocationPlatform implements LocationPlatform {
  static const channel = MethodChannel('io.appsmaker.racketmates/location');

  Future<T?> _invoke<T>(String method) async {
    try {
      return await channel.invokeMethod<T>(method);
    } on MissingPluginException {
      return null; // no platform code (tests, unsupported platform)
    } on PlatformException {
      return null;
    }
  }

  LocationPermission _permission(String? value) => switch (value) {
    'granted' => LocationPermission.granted,
    'denied' => LocationPermission.denied,
    _ => LocationPermission.notDetermined,
  };

  @override
  Future<LocationPermission> permission() async =>
      _permission(await _invoke<String>('permissionStatus'));

  @override
  Future<LocationPermission> requestPermission() async =>
      _permission(await _invoke<String>('requestPermission'));

  @override
  Future<LatLng?> currentPosition() async {
    final map = await _invoke<Map<Object?, Object?>>('currentPosition');
    final lat = (map?['latitude'] as num?)?.toDouble();
    final lng = (map?['longitude'] as num?)?.toDouble();
    return lat == null || lng == null ? null : LatLng(lat, lng);
  }

  @override
  Future<void> openSettings() => _invoke<void>('openSettings');
}

final locationPlatformProvider = Provider<LocationPlatform>(
  (ref) => ChannelLocationPlatform(),
);
