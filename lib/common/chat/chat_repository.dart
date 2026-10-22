import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/chat/chat_api.dart';
import 'package:racketmates/common/errors/app_failure.dart';

abstract class ChatRepository {
  /// A fresh Sendbird access token for the signed-in user.
  Future<String> sendbirdToken();

  Future<void> setupDefaultRooms();
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
}

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepositoryImpl(ChatApi(ref.watch(apiDioProvider))),
);
