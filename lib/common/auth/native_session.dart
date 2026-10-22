import 'dart:convert';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/models/session_token.dart';

/// The session the native app left on the device: the Android app keeps it in
/// `EncryptedSharedPreferences` (`sessionDetails`), the iOS app in the
/// Keychain (`session_response`). Reading it lets a user who updates from the
/// native app stay signed in instead of having to sign in again.
abstract class NativeSessionSource {
  /// The stored session JSON, or null when there is none.
  Future<String?> read();

  /// Removes the native copy once it has been imported.
  Future<void> clear();
}

class MethodChannelNativeSessionSource implements NativeSessionSource {
  const MethodChannelNativeSessionSource();

  static const channel = MethodChannel(
    'io.appsmaker.racketmates/native_session',
  );

  @override
  Future<String?> read() async {
    try {
      return await channel.invokeMethod<String>('read');
    } on MissingPluginException {
      return null; // no platform code (tests, unsupported platform)
    } on PlatformException {
      return null; // unreadable (e.g. key lost): sign in again
    }
  }

  @override
  Future<void> clear() async {
    try {
      await channel.invokeMethod<void>('clear');
    } on MissingPluginException {
      // nothing to clear
    } on PlatformException {
      // best effort
    }
  }
}

final nativeSessionSourceProvider = Provider<NativeSessionSource>(
  (ref) => const MethodChannelNativeSessionSource(),
);

/// Turns the native JSON into a session, or null when it cannot be used:
/// malformed, no refresh token (it could not be renewed), or a sign-up the
/// user never finished (`is_signed_up: false`: the native app sends those
/// users back through sign-up, which here means signing in again).
///
/// Android stores the OAuth response as is (`created_at`, integer
/// `expires_in`). iOS drops `token_type` and `created_at` and stores
/// `expires_in` as a decimal; without `created_at` the token is treated as not
/// yet known to be expired and the first 401 refreshes it.
SessionToken? parseNativeSession(
  String? raw, {
  required TargetPlatform platform,
}) {
  if (raw == null || raw.trim().isEmpty) return null;
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, dynamic>) return null;
  final Map<String, dynamic> json = decoded;
  String? text(String key) {
    final v = json[key];
    return v is String && v.isNotEmpty ? v : null;
  }

  int? whole(String key) {
    final v = json[key];
    return v is num ? v.toInt() : null;
  }

  final access = text('access_token');
  final refresh = text('refresh_token');
  if (access == null || refresh == null) return null;
  final userJson = json['user'];
  SessionTokenUser? user;
  if (userJson is Map<String, dynamic>) {
    if (userJson['is_signed_up'] == false) return null;
    user = SessionTokenUser(
      id: (userJson['id'] as num?)?.toInt(),
      uid: userJson['uid'] as String?,
      uuid: userJson['uuid'] as String?,
      isSignedUp: userJson['is_signed_up'] as bool?,
    );
  }
  return SessionToken(
    accessToken: access,
    tokenType: text('token_type') ?? 'Bearer',
    expiresIn: whole('expires_in'),
    refreshToken: refresh,
    createdAt: platform == TargetPlatform.iOS ? null : whole('created_at'),
    user: user,
  );
}

/// Imports the native session once: reads it, parses it, and removes the
/// native copy so a stale refresh token is not left lying around.
class NativeSessionImporter {
  const NativeSessionImporter(this.source);

  final NativeSessionSource source;

  Future<SessionToken?> import({TargetPlatform? platform}) async {
    final raw = await source.read();
    if (raw == null) return null;
    final token = parseNativeSession(
      raw,
      platform: platform ?? defaultTargetPlatform,
    );
    // A session that cannot be used is discarded too: it only leaves old
    // credentials behind.
    await source.clear();
    return token;
  }
}

final nativeSessionImporterProvider = Provider<NativeSessionImporter>(
  (ref) => NativeSessionImporter(ref.watch(nativeSessionSourceProvider)),
);
