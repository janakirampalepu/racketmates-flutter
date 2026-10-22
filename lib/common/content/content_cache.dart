import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// What was last fetched, so the app has strings and labels offline and on a
/// cold start before the network answers.
class ContentSnapshot {
  const ContentSnapshot({
    this.messages,
    this.preLoginMessages,
    this.referenceData,
    this.messagesVersion,
    this.referenceVersion,
    this.language,
  });

  final Map<String, dynamic>? messages;
  final Map<String, dynamic>? preLoginMessages;
  final List<dynamic>? referenceData;

  /// `resource_strings_latest_version` / `reference_data_last_updated` the
  /// cached copies correspond to.
  final int? messagesVersion;
  final int? referenceVersion;

  /// Language tag the copies were fetched for (`Accept-Language`).
  final String? language;
}

abstract class ContentCache {
  Future<ContentSnapshot> read();
  Future<void> write({
    Map<String, dynamic>? messages,
    Map<String, dynamic>? preLoginMessages,
    List<dynamic>? referenceData,
    int? messagesVersion,
    int? referenceVersion,
    String? language,
  });
}

class PrefsContentCache implements ContentCache {
  PrefsContentCache([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _messages = 'content_messages';
  static const _preLogin = 'content_pre_login_messages';
  static const _reference = 'content_reference_data';
  static const _messagesVersion = 'content_messages_version';
  static const _referenceVersion = 'content_reference_version';
  static const _language = 'content_language';

  final SharedPreferencesAsync _prefs;

  Future<T?> _json<T>(String key) async {
    final raw = await _prefs.getString(key);
    if (raw == null) return null;
    try {
      final value = jsonDecode(raw);
      return value is T ? value : null;
    } on FormatException {
      return null; // corrupt cache: behave as empty
    }
  }

  @override
  Future<ContentSnapshot> read() async => ContentSnapshot(
    messages: await _json<Map<String, dynamic>>(_messages),
    preLoginMessages: await _json<Map<String, dynamic>>(_preLogin),
    referenceData: await _json<List<dynamic>>(_reference),
    messagesVersion: await _prefs.getInt(_messagesVersion),
    referenceVersion: await _prefs.getInt(_referenceVersion),
    language: await _prefs.getString(_language),
  );

  @override
  Future<void> write({
    Map<String, dynamic>? messages,
    Map<String, dynamic>? preLoginMessages,
    List<dynamic>? referenceData,
    int? messagesVersion,
    int? referenceVersion,
    String? language,
  }) async {
    if (messages != null) {
      await _prefs.setString(_messages, jsonEncode(messages));
    }
    if (preLoginMessages != null) {
      await _prefs.setString(_preLogin, jsonEncode(preLoginMessages));
    }
    if (referenceData != null) {
      await _prefs.setString(_reference, jsonEncode(referenceData));
    }
    if (messagesVersion != null) {
      await _prefs.setInt(_messagesVersion, messagesVersion);
    }
    if (referenceVersion != null) {
      await _prefs.setInt(_referenceVersion, referenceVersion);
    }
    if (language != null) {
      await _prefs.setString(_language, language);
    }
  }
}

class InMemoryContentCache implements ContentCache {
  ContentSnapshot snapshot = const ContentSnapshot();

  @override
  Future<ContentSnapshot> read() async => snapshot;

  @override
  Future<void> write({
    Map<String, dynamic>? messages,
    Map<String, dynamic>? preLoginMessages,
    List<dynamic>? referenceData,
    int? messagesVersion,
    int? referenceVersion,
    String? language,
  }) async {
    snapshot = ContentSnapshot(
      messages: messages ?? snapshot.messages,
      preLoginMessages: preLoginMessages ?? snapshot.preLoginMessages,
      referenceData: referenceData ?? snapshot.referenceData,
      messagesVersion: messagesVersion ?? snapshot.messagesVersion,
      referenceVersion: referenceVersion ?? snapshot.referenceVersion,
      language: language ?? snapshot.language,
    );
  }
}
