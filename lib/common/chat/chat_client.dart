import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';

enum ChatConnectResult { connected, tokenInvalid, failed }

/// The chat service behind a small interface (the Sendbird SDK needs a live
/// connection, so everything else is tested against a fake).
abstract class ChatClient {
  /// Prepares the SDK for [appId]; safe to call again.
  Future<bool> init(String appId);

  Future<ChatConnectResult> connect({
    required String userId,
    required String token,
  });

  /// Disconnects and forgets cached data (native clears on logout).
  Future<void> disconnect();

  /// Lets Sendbird push chat messages to this device. [apns] is the iOS
  /// token, otherwise the FCM token.
  Future<void> registerPushToken(String token, {required bool apns});

  Future<void> unregisterPushToken(String token, {required bool apns});

  /// Unread messages over all channels, now and whenever it changes.
  Stream<int> unreadCount();
}

/// Sendbird error codes for a token that is wrong or expired.
const _invalidTokenCodes = {400300, 400301, 400302, 400309};

Future<FileInfo> _fileInfo(XFile file) async => FileInfo(
  file: File(file.path),
  fileName: file.name,
  mimeType: file.mimeType ?? lookupMimeType(file.path),
  fileSize: await file.length(),
);

class SendbirdChatClient implements ChatClient {
  bool _initialized = false;

  @override
  Future<bool> init(String appId) async {
    if (_initialized && SendbirdUIKit.isInitialized()) return true;
    try {
      final picker = ImagePicker();
      Future<FileInfo?> pick(ImageSource source, {bool video = false}) async {
        final file = video
            ? await picker.pickVideo(source: source)
            : await picker.pickImage(source: source);
        return file == null ? null : await _fileInfo(file);
      }

      await SendbirdUIKit.init(
        appId: appId,
        // Local collection caching (on by default) reads a channel's
        // `isHidden` flag from an on-device DB that the SDK's own `hide()`
        // only writes conditionally (skipped whenever the hide response's
        // `ts_message_offset` is null or unchanged from the channel's
        // current one — common for a freshly-created or quiet channel), so
        // the Active list can keep showing a just-archived channel straight
        // from a stale local row instead of ever re-asking the server.
        // Turning caching off makes every channel-list load a genuine
        // network query (`GroupChannelListQuery.next()`), which reflects
        // the server's authoritative hidden state either way; this app has
        // no offline-chat requirement to trade away for that.
        options: SendbirdChatOptions(useCollectionCaching: false),
        takePhoto: () => pick(ImageSource.camera),
        takeVideo: () => pick(ImageSource.camera, video: true),
        choosePhoto: () => pick(ImageSource.gallery),
        chooseMedia: () async {
          final file = await picker.pickMedia();
          return file == null ? null : await _fileInfo(file);
        },
      );
      _initialized = true;
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<ChatConnectResult> connect({
    required String userId,
    required String token,
  }) async {
    try {
      await SendbirdChat.connect(userId, accessToken: token);
    } on SendbirdException catch (e) {
      return _invalidTokenCodes.contains(e.code)
          ? ChatConnectResult.tokenInvalid
          : ChatConnectResult.failed;
    } on Object {
      return ChatConnectResult.failed;
    }
    // Lets the UIKit load its own settings (reactions, configuration).
    unawaited(SendbirdUIKit.connect(userId, accessToken: token));
    return ChatConnectResult.connected;
  }

  @override
  Future<void> disconnect() async {
    try {
      await SendbirdUIKit.disconnect();
    } on Object {
      // Nothing to disconnect.
    }
  }

  PushTokenType _type({required bool apns}) =>
      apns ? PushTokenType.apns : PushTokenType.fcm;

  @override
  Future<void> registerPushToken(String token, {required bool apns}) async {
    try {
      await SendbirdChat.registerPushToken(
        type: _type(apns: apns),
        token: token,
      );
    } on Object {
      // Chat messages then arrive without a push; the next launch retries.
    }
  }

  @override
  Future<void> unregisterPushToken(String token, {required bool apns}) async {
    try {
      await SendbirdChat.unregisterPushToken(
        type: _type(apns: apns),
        token: token,
      );
    } on Object {
      // Best effort.
    }
  }

  @override
  Stream<int> unreadCount() {
    const id = 'racketmates-unread';
    late final StreamController<int> controller;
    Future<void> refresh() async {
      try {
        final count = await SendbirdChat.getTotalUnreadMessageCount();
        if (!controller.isClosed) controller.add(count);
      } on Object {
        // Keep the last count.
      }
    }

    controller = StreamController<int>(
      onListen: () {
        SendbirdChat.addUserEventHandler(id, _UnreadHandler(refresh));
        unawaited(refresh());
      },
      onCancel: () {
        SendbirdChat.removeUserEventHandler(id);
        return controller.close();
      },
    );
    return controller.stream;
  }
}

class _UnreadHandler extends UserEventHandler {
  _UnreadHandler(this._refresh);

  final Future<void> Function() _refresh;

  @override
  void onFriendsDiscovered(List<User> users) {}

  @override
  void onTotalUnreadMessageCountChanged(UnreadMessageCount unreadMessageCount) {
    unawaited(_refresh());
  }
}

final chatClientProvider = Provider<ChatClient>((ref) => SendbirdChatClient());

/// Which push token type Sendbird needs on this platform.
bool chatUsesApns(TargetPlatform platform) => platform == TargetPlatform.iOS;
