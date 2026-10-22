import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:retrofit/retrofit.dart';

part 'create_event_api.g.dart';

/// `GET users` response when searching players.
@JsonSerializable(fieldRename: FieldRename.snake)
class UserSearchResponse {
  const UserSearchResponse({this.users});

  factory UserSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$UserSearchResponseFromJson(json);

  final List<AppUser>? users;

  Map<String, dynamic> toJson() => _$UserSearchResponseToJson(this);
}

/// `GET timezone_infos/lookup` response.
@JsonSerializable(fieldRename: FieldRename.snake)
class TimezoneLookupResponse {
  const TimezoneLookupResponse({this.timezoneInfo});

  factory TimezoneLookupResponse.fromJson(Map<String, dynamic> json) =>
      _$TimezoneLookupResponseFromJson(json);

  final TimezoneInfo? timezoneInfo;

  Map<String, dynamic> toJson() => _$TimezoneLookupResponseToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class TimezoneInfo {
  const TimezoneInfo({
    this.id,
    this.name,
    this.utcOffsetTime,
    this.abbreviation,
  });

  factory TimezoneInfo.fromJson(Map<String, dynamic> json) =>
      _$TimezoneInfoFromJson(json);

  final int? id;
  final String? name;
  final int? utcOffsetTime;
  final String? abbreviation;

  Map<String, dynamic> toJson() => _$TimezoneInfoToJson(this);
}

@RestApi()
abstract class CreateEventApi {
  factory CreateEventApi(Dio dio, {String? baseUrl}) = _CreateEventApi;

  @POST('events')
  Future<EventDetailsResponse> createEvent(@Body() Map<String, dynamic> body);

  @GET('users')
  Future<UserSearchResponse> searchUsers({
    @Query('search') String? search,
    @Query('roles[]') List<String>? roles,
    @Query('sport_types[]') List<String>? sportTypes,
    @Query('include_user_ids[]') List<int>? includeUserIds,
    @Query('exclude_user_ids[]') List<int>? excludeUserIds,
  });

  @GET('timezone_infos/lookup')
  Future<TimezoneLookupResponse> timezoneLookup({
    @Query('latitude') String? latitude,
    @Query('longitude') String? longitude,
    @Query('time') String? time,
  });
}
