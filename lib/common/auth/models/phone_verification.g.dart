// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phone_verification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MobileNumberStatus _$MobileNumberStatusFromJson(Map<String, dynamic> json) =>
    MobileNumberStatus(
      userExist: json['user_exist'] as bool?,
      isSignedUp: json['is_signed_up'] as bool?,
    );

Map<String, dynamic> _$MobileNumberStatusToJson(MobileNumberStatus instance) =>
    <String, dynamic>{
      'user_exist': instance.userExist,
      'is_signed_up': instance.isSignedUp,
    };

SmsCodePayload _$SmsCodePayloadFromJson(Map<String, dynamic> json) =>
    SmsCodePayload(
      mobileNumber: json['mobile_number'] as String?,
      countryCode: json['country_code'] as String?,
      code: json['code'] as String?,
      status: json['status'] as String?,
      playerExist: json['player_exist'] as bool?,
      valid: json['valid'] as bool?,
      isSignedUp: json['is_signed_up'] as bool?,
      regionCode: json['region_code'] as String?,
      verificationCode: json['verification_code'] as String?,
    );

Map<String, dynamic> _$SmsCodePayloadToJson(SmsCodePayload instance) =>
    <String, dynamic>{
      'mobile_number': ?instance.mobileNumber,
      'country_code': ?instance.countryCode,
      'code': ?instance.code,
      'status': ?instance.status,
      'player_exist': ?instance.playerExist,
      'valid': ?instance.valid,
      'is_signed_up': ?instance.isSignedUp,
      'region_code': ?instance.regionCode,
      'verification_code': ?instance.verificationCode,
    };
