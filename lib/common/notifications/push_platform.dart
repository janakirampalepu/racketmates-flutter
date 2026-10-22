import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/notifications/push_models.dart';

/// The platform side of push notifications. Android uses an FCM token, iOS the
/// raw APNs token (the backend expects exactly those); both live behind this
/// interface and the `io.appsmaker.racketmates/push` channel.
abstract class PushPlatform {
  /// Prepares push. False when it cannot work on this build (no Firebase
  /// configuration on Android): everything else then does nothing.
  Future<bool> initialize();

  Future<PushPermission> permission();

  /// Asks the user (Android 13+ / iOS prompt). Returns the new state.
  Future<PushPermission> requestPermission();

  /// The device token, or null while the platform has not produced one.
  Future<String?> token();

  /// The notification that launched the app, once.
  Future<PushMessage?> launchMessage();

  /// Opens the system notification settings of this app.
  Future<void> openSettings();

  /// A new or refreshed token.
  Stream<String> get tokens;

  /// A notification that arrived while the app is open.
  Stream<PushMessage> get foregroundMessages;

  /// The user tapped a notification while the app was running.
  Stream<PushMessage> get openedMessages;
}

class ChannelPushPlatform implements PushPlatform {
  ChannelPushPlatform() {
    channel.setMethodCallHandler(_onCall);
  }

  static const channel = MethodChannel('io.appsmaker.racketmates/push');

  final _tokens = StreamController<String>.broadcast();
  final _foreground = StreamController<PushMessage>.broadcast();
  final _opened = StreamController<PushMessage>.broadcast();

  Future<Object?> _onCall(MethodCall call) async {
    final args = call.arguments;
    switch (call.method) {
      case 'onToken':
        if (args is String && args.isNotEmpty) _tokens.add(args);
      case 'onMessage':
        if (args is Map) _foreground.add(PushMessage.fromMap(args));
      case 'onOpened':
        if (args is Map) _opened.add(PushMessage.fromMap(args));
    }
    return null;
  }

  Future<T?> _invoke<T>(String method) async {
    try {
      return await channel.invokeMethod<T>(method);
    } on MissingPluginException {
      return null; // no platform code (tests, unsupported platform)
    } on PlatformException {
      return null;
    }
  }

  PushPermission _permission(String? value) => switch (value) {
    'granted' => PushPermission.granted,
    'denied' => PushPermission.denied,
    _ => PushPermission.notDetermined,
  };

  @override
  Future<bool> initialize() async => await _invoke<bool>('initialize') ?? false;

  @override
  Future<PushPermission> permission() async =>
      _permission(await _invoke<String>('permissionStatus'));

  @override
  Future<PushPermission> requestPermission() async =>
      _permission(await _invoke<String>('requestPermission'));

  @override
  Future<String?> token() => _invoke<String>('token');

  @override
  Future<PushMessage?> launchMessage() async {
    final map = await _invoke<Map<Object?, Object?>>('launchMessage');
    return map == null ? null : PushMessage.fromMap(map);
  }

  @override
  Future<void> openSettings() => _invoke<void>('openSettings');

  @override
  Stream<String> get tokens => _tokens.stream;

  @override
  Stream<PushMessage> get foregroundMessages => _foreground.stream;

  @override
  Stream<PushMessage> get openedMessages => _opened.stream;
}

final pushPlatformProvider = Provider<PushPlatform>(
  (ref) => ChannelPushPlatform(),
);
