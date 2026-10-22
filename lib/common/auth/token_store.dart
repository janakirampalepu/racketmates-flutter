import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:racketmates/common/auth/models/session_token.dart';

/// Persistence for the OAuth session. Implementations must use secure storage.
abstract class TokenStore {
  Future<SessionToken?> read();
  Future<void> write(SessionToken token);
  Future<void> clear();
}

/// Keychain (iOS) / EncryptedSharedPreferences-backed (Android) store.
///
/// Native upgrade: the native apps keep their own copy of the session (see
/// `native_session.dart`); `SessionController.restore` imports it once.
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'session_token';
  final FlutterSecureStorage _storage;

  @override
  Future<SessionToken?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return SessionToken.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // Corrupt payload: treat as signed out rather than crash on startup.
      await _storage.delete(key: _key);
      return null;
    }
  }

  @override
  Future<void> write(SessionToken token) =>
      _storage.write(key: _key, value: jsonEncode(token.toJson()));

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

class InMemoryTokenStore implements TokenStore {
  InMemoryTokenStore([this._token]);

  SessionToken? _token;

  @override
  Future<SessionToken?> read() async => _token;

  @override
  Future<void> write(SessionToken token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
