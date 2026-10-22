import 'package:dio/dio.dart';
import 'package:racketmates/common/create_event/create_event_api.dart'
    show UserSearchResponse;
import 'package:retrofit/retrofit.dart';

part 'chat_api.g.dart';

/// Sendbird token, default chat rooms and chat room creation (native
/// `ApiServices`).
@RestApi()
abstract class ChatApi {
  factory ChatApi(Dio dio, {String? baseUrl}) = _ChatApi;

  /// `{token, expires_at}`; the token authenticates this user with Sendbird.
  @GET('current_session/sendbird_token')
  Future<dynamic> sendbirdToken();

  /// Creates the rooms every user has (support chat) on the server.
  @POST('current_session/setup_default_chat_rooms')
  Future<void> setupDefaultChatRooms();

  /// `{chat_room: {id, channel_url}}`; the room is created once, later calls
  /// return it.
  @PUT('events/{eventId}/setup_players_chat_room')
  Future<dynamic> setupPlayersChatRoom(
    @Path('eventId') int eventId,
    @Body() Map<String, dynamic> body,
  );

  @PUT('events/{eventId}/setup_captains_chat_room')
  Future<dynamic> setupCaptainsChatRoom(@Path('eventId') int eventId);

  /// A one-to-one room: `{chat_room: {chat_room_type: crt_direct, uids}}`.
  @POST('chat_rooms')
  Future<dynamic> createChatRoom(@Body() Map<String, dynamic> body);

  /// Players to start a one-to-one chat with.
  @GET('users')
  Future<UserSearchResponse> searchPlayers({
    @Query('search') String? search,
    @Query('exclude_user_ids[]') List<int>? excludeUserIds,
    @Query('is_signed_up') bool? isSignedUp,
  });
}
