import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/chat/chat_client.dart';
import 'package:racketmates/common/chat/chat_repository.dart';
import 'package:racketmates/common/config/config_providers.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/notifications/push_platform.dart';
import 'package:racketmates/common/sign_up/sign_up_flow.dart';

enum ChatStatus {
  /// Not signed in, or sign-up is not finished.
  idle,

  /// No Sendbird application id in this build.
  unavailable,
  connecting,
  connected,
  failed,
}

/// The Sendbird connection of the signed-in user (native `AppController.
/// connectToSendBird`): fetch a token from the backend, connect, and fetch a
/// new token once if Sendbird says it expired.
class ChatController extends Notifier<ChatStatus> {
  int _attempt = 0;
  StreamSubscription<String>? _tokens;

  @override
  ChatStatus build() {
    ref.onDispose(() => unawaited(_tokens?.cancel()));
    return ChatStatus.idle;
  }

  ChatClient get _client => ref.read(chatClientProvider);

  String? get _userId {
    final session = ref.read(sessionControllerProvider);
    return session is SignedIn ? session.token.user?.uid : null;
  }

  bool get _active => _userId != null && ref.read(signUpFlowProvider) == null;

  /// Connects (or reconnects after a failure). Does nothing while connected.
  Future<void> connect() async {
    if (state == ChatStatus.connecting || state == ChatStatus.connected) return;
    final appId = ref.read(environmentConfigProvider).sendbirdAppId;
    if (appId.isEmpty) {
      state = ChatStatus.unavailable;
      return;
    }
    final userId = _userId;
    if (userId == null || !_active) return;

    final attempt = ++_attempt;
    state = ChatStatus.connecting;
    bool stale() => !ref.mounted || attempt != _attempt;

    if (!await _client.init(appId)) {
      if (!stale()) state = ChatStatus.failed;
      return;
    }
    final repository = ref.read(chatRepositoryProvider);
    var result = ChatConnectResult.failed;
    try {
      // A token Sendbird rejects as expired is replaced once.
      for (var tries = 0; tries < 2; tries++) {
        final token = await repository.sendbirdToken();
        if (stale()) return;
        result = await _client.connect(userId: userId, token: token);
        if (stale()) {
          if (result == ChatConnectResult.connected) await _client.disconnect();
          return;
        }
        if (result != ChatConnectResult.tokenInvalid) break;
      }
    } on AppFailure {
      if (!stale()) state = ChatStatus.failed;
      return;
    }
    if (result != ChatConnectResult.connected) {
      state = ChatStatus.failed;
      return;
    }
    state = ChatStatus.connected;
    unawaited(_afterConnected());
  }

  Future<void> _afterConnected() async {
    final client = _client;
    final push = ref.read(pushPlatformProvider);
    final repository = ref.read(chatRepositoryProvider);
    final apns = chatUsesApns(defaultTargetPlatform);
    final token = await push.token();
    if (!ref.mounted) return;
    if (token != null) await client.registerPushToken(token, apns: apns);
    if (!ref.mounted || state != ChatStatus.connected) return;
    unawaited(_tokens?.cancel());
    _tokens = push.tokens.listen((t) {
      if (ref.mounted && state == ChatStatus.connected) {
        unawaited(client.registerPushToken(t, apns: apns));
      }
    });
    try {
      await repository.setupDefaultRooms();
    } on AppFailure {
      // The support room is created on a later launch.
    }
  }

  /// Ends the chat session: Sendbird stops pushing to this device and the
  /// connection and cached chats are dropped. Safe to call when not connected.
  Future<void> disconnect() async {
    _attempt++;
    final wasConnected = state == ChatStatus.connected;
    unawaited(_tokens?.cancel());
    _tokens = null;
    if (ref.mounted) state = ChatStatus.idle;
    if (wasConnected) {
      final token = await ref.read(pushPlatformProvider).token();
      if (token != null) {
        await _client.unregisterPushToken(
          token,
          apns: chatUsesApns(defaultTargetPlatform),
        );
      }
    }
    await _client.disconnect();
  }
}

final chatControllerProvider = NotifierProvider<ChatController, ChatStatus>(
  ChatController.new,
);

/// Total unread chat messages (the badge on the chat tab); 0 when not
/// connected.
final chatUnreadProvider = StreamProvider<int>((ref) {
  if (ref.watch(chatControllerProvider) != ChatStatus.connected) {
    return Stream.value(0);
  }
  return ref.watch(chatClientProvider).unreadCount();
});

/// Keeps the chat connection in step with the session (watched by the app):
/// connect when a user is signed in and sign-up is finished, disconnect when
/// the session ends.
final chatSyncProvider = Provider<void>((ref) {
  final controller = ref.read(chatControllerProvider.notifier);
  void sync() {
    final session = ref.read(sessionControllerProvider);
    final done = ref.read(signUpFlowProvider) == null;
    if (session is SignedIn && done) {
      unawaited(controller.connect());
    } else if (session is SignedOut) {
      unawaited(controller.disconnect());
    }
  }

  ref
    ..listen(sessionControllerProvider, (_, _) => sync(), fireImmediately: true)
    ..listen(signUpFlowProvider, (_, _) => sync());
});
