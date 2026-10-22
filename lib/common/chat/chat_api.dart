import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'chat_api.g.dart';

/// Sendbird token and default chat rooms (native `ApiServices`).
@RestApi()
abstract class ChatApi {
  factory ChatApi(Dio dio, {String? baseUrl}) = _ChatApi;

  /// `{token, expires_at}`; the token authenticates this user with Sendbird.
  @GET('current_session/sendbird_token')
  Future<dynamic> sendbirdToken();

  /// Creates the rooms every user has (support chat) on the server.
  @POST('current_session/setup_default_chat_rooms')
  Future<void> setupDefaultChatRooms();
}
