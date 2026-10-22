import 'package:json_annotation/json_annotation.dart';
import 'package:racketmates/common/events/models/event_details.dart';

part 'session_info_models.g.dart';

/// `GET current_session/session_info`: the signed-in user's subscription,
/// permissions and support chat room (native `UserSessionInfoResponce`).
@JsonSerializable(fieldRename: FieldRename.snake)
class SessionInfoResponse {
  const SessionInfoResponse({this.user, this.subscription});

  factory SessionInfoResponse.fromJson(Map<String, dynamic> json) =>
      _$SessionInfoResponseFromJson(json);

  final SessionInfoUser? user;
  final SessionSubscription? subscription;

  Map<String, dynamic> toJson() => _$SessionInfoResponseToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SessionInfoUser {
  const SessionInfoUser({
    this.id,
    this.hasFullFeatureAccess,
    this.subscribedDeviceType,
    this.trialRemainingDays,
    this.trialEndDate,
    this.userPermissions,
    this.roles,
    this.firstName,
    this.lastName,
    this.email,
    this.timezoneIdentifier,
    this.supportChatRoomUrl,
    this.distanceType,
  });

  factory SessionInfoUser.fromJson(Map<String, dynamic> json) =>
      _$SessionInfoUserFromJson(json);

  final int? id;
  final bool? hasFullFeatureAccess;

  /// Which store the subscription was bought on; empty during a trial.
  final String? subscribedDeviceType;
  final int? trialRemainingDays;
  final String? trialEndDate;

  /// Global permissions keyed like the backend (`teams.create`,
  /// `events.create`, ...).
  final Map<String, AccessInfo>? userPermissions;
  final List<String>? roles;
  final String? firstName;
  final String? lastName;
  final String? email;

  /// The time zone the server has for the user (IANA id).
  final String? timezoneIdentifier;
  final String? supportChatRoomUrl;

  /// The user's distance unit (`dt_*` reference data key).
  final String? distanceType;

  Map<String, dynamic> toJson() => _$SessionInfoUserToJson(this);

  /// Full access: subscribed or in a trial (native `isSubscribedUser`).
  bool get isSubscribed => hasFullFeatureAccess ?? false;

  /// In a trial: no store subscription yet and days left (native
  /// `isTrialUser`).
  bool get isTrial =>
      (subscribedDeviceType ?? '').isEmpty && (trialRemainingDays ?? 0) > 0;

  /// The trial is over and nothing was bought (native `isTrielEnded`).
  bool get isTrialEnded =>
      hasFullFeatureAccess == false && (trialRemainingDays ?? 0) == 0;

  AccessInfo? permission(String key) => userPermissions?[key];
}

/// Purchases the backend knows about (Play Store `purchase_tokens`, App Store
/// `original_transaction_ids`).
@JsonSerializable(fieldRename: FieldRename.snake)
class SessionSubscription {
  const SessionSubscription({this.purchaseTokens, this.originalTransactionIds});

  factory SessionSubscription.fromJson(Map<String, dynamic> json) =>
      _$SessionSubscriptionFromJson(json);

  final List<String>? purchaseTokens;
  final List<String>? originalTransactionIds;

  Map<String, dynamic> toJson() => _$SessionSubscriptionToJson(this);
}
