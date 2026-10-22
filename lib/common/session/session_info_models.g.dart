// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_info_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionInfoResponse _$SessionInfoResponseFromJson(Map<String, dynamic> json) =>
    SessionInfoResponse(
      user: json['user'] == null
          ? null
          : SessionInfoUser.fromJson(json['user'] as Map<String, dynamic>),
      subscription: json['subscription'] == null
          ? null
          : SessionSubscription.fromJson(
              json['subscription'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$SessionInfoResponseToJson(
  SessionInfoResponse instance,
) => <String, dynamic>{
  'user': instance.user,
  'subscription': instance.subscription,
};

SessionInfoUser _$SessionInfoUserFromJson(Map<String, dynamic> json) =>
    SessionInfoUser(
      id: (json['id'] as num?)?.toInt(),
      hasFullFeatureAccess: json['has_full_feature_access'] as bool?,
      subscribedDeviceType: json['subscribed_device_type'] as String?,
      trialRemainingDays: (json['trial_remaining_days'] as num?)?.toInt(),
      trialEndDate: json['trial_end_date'] as String?,
      userPermissions: (json['user_permissions'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, AccessInfo.fromJson(e as Map<String, dynamic>)),
      ),
      roles: (json['roles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      timezoneIdentifier: json['timezone_identifier'] as String?,
      supportChatRoomUrl: json['support_chat_room_url'] as String?,
      distanceType: json['distance_type'] as String?,
    );

Map<String, dynamic> _$SessionInfoUserToJson(SessionInfoUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'has_full_feature_access': instance.hasFullFeatureAccess,
      'subscribed_device_type': instance.subscribedDeviceType,
      'trial_remaining_days': instance.trialRemainingDays,
      'trial_end_date': instance.trialEndDate,
      'user_permissions': instance.userPermissions,
      'roles': instance.roles,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'email': instance.email,
      'timezone_identifier': instance.timezoneIdentifier,
      'support_chat_room_url': instance.supportChatRoomUrl,
      'distance_type': instance.distanceType,
    };

SessionSubscription _$SessionSubscriptionFromJson(Map<String, dynamic> json) =>
    SessionSubscription(
      purchaseTokens: (json['purchase_tokens'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      originalTransactionIds:
          (json['original_transaction_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
    );

Map<String, dynamic> _$SessionSubscriptionToJson(
  SessionSubscription instance,
) => <String, dynamic>{
  'purchase_tokens': instance.purchaseTokens,
  'original_transaction_ids': instance.originalTransactionIds,
};
