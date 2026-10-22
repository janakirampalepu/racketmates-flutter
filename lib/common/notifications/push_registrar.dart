import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/notifications/push_models.dart';
import 'package:racketmates/common/notifications/push_platform.dart';
import 'package:racketmates/common/settings/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Language sent with the device token. Native sends the device language when
/// the server supports it, else English; only English exists here until
/// language selection is built.
final preferredLanguageProvider = Provider<String>((ref) => 'en');

/// Where the registered token is remembered (so it is only sent when it
/// changes, and so sign-out can revoke it).
abstract class PushTokenStore {
  Future<({String token, int userId})?> read();
  Future<void> write(String token, int userId);
  Future<void> clear();
}

class PrefsPushTokenStore implements PushTokenStore {
  PrefsPushTokenStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _tokenKey = 'push_registered_token';
  static const _userKey = 'push_registered_user';
  final SharedPreferencesAsync _prefs;

  @override
  Future<({String token, int userId})?> read() async {
    final token = await _prefs.getString(_tokenKey);
    final user = await _prefs.getInt(_userKey);
    return token == null || user == null ? null : (token: token, userId: user);
  }

  @override
  Future<void> write(String token, int userId) async {
    await _prefs.setString(_tokenKey, token);
    await _prefs.setInt(_userKey, userId);
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
  }
}

final pushTokenStoreProvider = Provider<PushTokenStore>(
  (ref) => PrefsPushTokenStore(),
);

/// Registers this device for the signed-in user and revokes it on sign-out
/// (native `register_device_token` / `revoke_device_token`).
class PushRegistrar {
  PushRegistrar(this._ref);

  final Ref _ref;

  PushPlatform get _platform => _ref.read(pushPlatformProvider);

  int? get _userId {
    final session = _ref.read(sessionControllerProvider);
    return session is SignedIn ? session.token.user?.id : null;
  }

  /// Asks for permission (the platform only prompts when it has not been
  /// decided) and registers the token. Returns whether a token is registered.
  Future<bool> start() async {
    if (!await _platform.initialize()) return false;
    var permission = await _platform.permission();
    if (permission == PushPermission.notDetermined) {
      permission = await _platform.requestPermission();
    }
    if (permission != PushPermission.granted) return false;
    final token = await _platform.token();
    return token != null && await register(token);
  }

  /// Sends [token] unless it is the one already registered for this user.
  Future<bool> register(String token) async {
    final userId = _userId;
    if (userId == null) return false;
    final store = _ref.read(pushTokenStoreProvider);
    final known = await store.read();
    if (known != null && known.token == token && known.userId == userId) {
      return true;
    }
    try {
      await _ref
          .read(settingsRepositoryProvider)
          .registerDeviceToken(
            token,
            platform: defaultTargetPlatform,
            language: _ref.read(preferredLanguageProvider),
          );
    } on AppFailure {
      return false; // tried again on the next launch or token refresh
    }
    await store.write(token, userId);
    return true;
  }

  /// Revokes this device's token (best effort) and forgets it. Call before
  /// the session ends, while requests are still authorized.
  Future<void> unregister() async {
    final store = _ref.read(pushTokenStoreProvider);
    final known = await store.read();
    final token = known?.token ?? await _platform.token();
    if (token != null) {
      try {
        await _ref.read(settingsRepositoryProvider).revokeDeviceToken(token);
      } on AppFailure {
        // Signing out must not depend on it.
      }
    }
    await store.clear();
  }
}

final pushRegistrarProvider = Provider<PushRegistrar>(PushRegistrar.new);
