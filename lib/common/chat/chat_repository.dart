import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/chat/chat_api.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/users/models/app_user.dart';

abstract class ChatRepository {
  /// A fresh Sendbird access token for the signed-in user.
  Future<String> sendbirdToken();

  Future<void> setupDefaultRooms();

  /// The channel url of the players' chat room of an event (created if it
  /// does not exist). [teamId] is the user's team in a team event.
  Future<String> playersChatRoom(int eventId, {int? teamId});

  Future<String> captainsChatRoom(int eventId);

  /// The channel url of the one-to-one room of the two users (created if it
  /// does not exist), by their `uid`.
  Future<String> directChatRoom({
    required String ownUid,
    required String otherUid,
  });

  /// Signed-up players matching [query], without the user themself.
  Future<List<AppUser>> searchPlayers(
    String query, {
    required int excludeUserId,
  });
}

class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl(this.api);

  final ChatApi api;

  @override
  Future<String> sendbirdToken() async {
    try {
      final body = await api.sendbirdToken();
      if (body is! Map) throw const ParseFailure();
      // Tolerate the token being wrapped in `data`.
      final data = body['data'];
      final token = body['token'] ?? (data is Map ? data['token'] : null);
      if (token is! String || token.isEmpty) throw const ParseFailure();
      return token;
    } on DioException catch (e) {
      throw mapDioException(e);
    } on TypeError {
      throw const ParseFailure();
    }
  }

  @override
  Future<void> setupDefaultRooms() async {
    try {
      await api.setupDefaultChatRooms();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// `{chat_room: {id, channel_url}}` -> the channel url.
  String _channelUrl(Object? body) {
    final room = body is Map ? body['chat_room'] : null;
    final url = room is Map ? room['channel_url'] : null;
    if (url is! String || url.isEmpty) throw const ParseFailure();
    return url;
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapDioException(e);
    } on TypeError {
      throw const ParseFailure();
    }
  }

  @override
  Future<String> playersChatRoom(int eventId, {int? teamId}) => _guard(
    () async => _channelUrl(
      await api.setupPlayersChatRoom(eventId, {'team_id': teamId}),
    ),
  );

  @override
  Future<String> captainsChatRoom(int eventId) =>
      _guard(() async => _channelUrl(await api.setupCaptainsChatRoom(eventId)));

  @override
  Future<String> directChatRoom({
    required String ownUid,
    required String otherUid,
  }) => _guard(
    () async => _channelUrl(
      await api.createChatRoom({
        'chat_room': {
          'chat_room_type': 'crt_direct',
          'uids': [ownUid, otherUid],
        },
      }),
    ),
  );

  @override
  Future<List<AppUser>> searchPlayers(
    String query, {
    required int excludeUserId,
  }) async {
    final response = await _guard(
      () => api.searchPlayers(
        search: query.trim(),
        excludeUserIds: [excludeUserId],
        isSignedUp: true,
      ),
    );
    return response.users ?? const [];
  }
}

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepositoryImpl(ChatApi(ref.watch(apiDioProvider))),
);
