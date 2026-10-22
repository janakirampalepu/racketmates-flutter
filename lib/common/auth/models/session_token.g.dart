// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionToken _$SessionTokenFromJson(Map<String, dynamic> json) => SessionToken(
  accessToken: json['access_token'] as String?,
  tokenType: json['token_type'] as String?,
  expiresIn: (json['expires_in'] as num?)?.toInt(),
  refreshToken: json['refresh_token'] as String?,
  createdAt: (json['created_at'] as num?)?.toInt(),
  user: json['user'] == null
      ? null
      : SessionTokenUser.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SessionTokenToJson(SessionToken instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'token_type': instance.tokenType,
      'expires_in': instance.expiresIn,
      'refresh_token': instance.refreshToken,
      'created_at': instance.createdAt,
      'user': instance.user,
    };

SessionTokenUser _$SessionTokenUserFromJson(Map<String, dynamic> json) =>
    SessionTokenUser(
      id: (json['id'] as num?)?.toInt(),
      uid: json['uid'] as String?,
      uuid: json['uuid'] as String?,
      isSignedUp: json['is_signed_up'] as bool?,
    );

Map<String, dynamic> _$SessionTokenUserToJson(SessionTokenUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'uid': instance.uid,
      'uuid': instance.uuid,
      'is_signed_up': instance.isSignedUp,
    };
