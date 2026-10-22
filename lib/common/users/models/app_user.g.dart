// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserRoleSport _$UserRoleSportFromJson(Map<String, dynamic> json) =>
    UserRoleSport(
      id: (json['id'] as num?)?.toInt(),
      sportType: json['sport_type'] as String?,
    );

Map<String, dynamic> _$UserRoleSportToJson(UserRoleSport instance) =>
    <String, dynamic>{'id': instance.id, 'sport_type': instance.sportType};

UserRole _$UserRoleFromJson(Map<String, dynamic> json) => UserRole(
  id: (json['id'] as num?)?.toInt(),
  role: json['role'] as String?,
  userRoleSports: (json['user_role_sports'] as List<dynamic>?)
      ?.map((e) => UserRoleSport.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$UserRoleToJson(UserRole instance) => <String, dynamic>{
  'id': instance.id,
  'role': instance.role,
  'user_role_sports': instance.userRoleSports,
};

UserCountry _$UserCountryFromJson(Map<String, dynamic> json) => UserCountry(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  code: json['code'] as String?,
  regionCode: json['region_code'] as String?,
);

Map<String, dynamic> _$UserCountryToJson(UserCountry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
      'region_code': instance.regionCode,
    };

AppUser _$AppUserFromJson(Map<String, dynamic> json) => AppUser(
  id: (json['id'] as num?)?.toInt(),
  uid: json['uid'] as String?,
  uuid: json['uuid'] as String?,
  firstName: json['first_name'] as String?,
  lastName: json['last_name'] as String?,
  mobileNumber: json['mobile_number'] as String?,
  email: json['email'] as String?,
  roles: (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList(),
  userRoles: (json['user_roles'] as List<dynamic>?)
      ?.map((e) => UserRole.fromJson(e as Map<String, dynamic>))
      .toList(),
  children: (json['children'] as List<dynamic>?)
      ?.map((e) => AppUser.fromJson(e as Map<String, dynamic>))
      .toList(),
  isSignedUp: json['is_signed_up'] as bool?,
  country: json['country'] == null
      ? null
      : UserCountry.fromJson(json['country'] as Map<String, dynamic>),
  timezoneIdentifier: json['timezone_identifier'] as String?,
  avatarFileAttachmentUrl: json['avatar_file_attachment_url'] as String?,
  thumbnailAttachmentUrl: json['thumbnail_attachment_url'] as String?,
  consentForTextMessages: json['consent_for_text_messages'] as bool?,
);

Map<String, dynamic> _$AppUserToJson(AppUser instance) => <String, dynamic>{
  'id': instance.id,
  'uid': instance.uid,
  'uuid': instance.uuid,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'mobile_number': instance.mobileNumber,
  'email': instance.email,
  'roles': instance.roles,
  'user_roles': instance.userRoles,
  'children': instance.children,
  'is_signed_up': instance.isSignedUp,
  'country': instance.country,
  'timezone_identifier': instance.timezoneIdentifier,
  'avatar_file_attachment_url': instance.avatarFileAttachmentUrl,
  'thumbnail_attachment_url': instance.thumbnailAttachmentUrl,
  'consent_for_text_messages': instance.consentForTextMessages,
};

UserDetails _$UserDetailsFromJson(Map<String, dynamic> json) => UserDetails(
  user: json['user'] == null
      ? null
      : AppUser.fromJson(json['user'] as Map<String, dynamic>),
  message: json['message'] as String?,
);

Map<String, dynamic> _$UserDetailsToJson(UserDetails instance) =>
    <String, dynamic>{'user': instance.user, 'message': instance.message};

DuplicateCheck _$DuplicateCheckFromJson(Map<String, dynamic> json) =>
    DuplicateCheck(
      result: json['result'] as bool?,
      emailResult: json['email_result'] as bool?,
      displayNameResult: json['display_name_result'] as bool?,
    );

Map<String, dynamic> _$DuplicateCheckToJson(DuplicateCheck instance) =>
    <String, dynamic>{
      'result': instance.result,
      'email_result': instance.emailResult,
      'display_name_result': instance.displayNameResult,
    };
