import 'package:json_annotation/json_annotation.dart';

part 'phone_verification.g.dart';

/// `POST validations/verify_mobile_number` response.
@JsonSerializable(fieldRename: FieldRename.snake)
class MobileNumberStatus {
  const MobileNumberStatus({this.userExist, this.isSignedUp});

  factory MobileNumberStatus.fromJson(Map<String, dynamic> json) =>
      _$MobileNumberStatusFromJson(json);

  final bool? userExist;
  final bool? isSignedUp;

  /// Registered number (user exists and finished sign-up).
  bool get isRegistered => (userExist ?? false) && (isSignedUp ?? false);
}

/// Request/response of `verifications/send_sms_code` and
/// `verifications/verify_sms_code` (native `FormSmsCode`).
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class SmsCodePayload {
  const SmsCodePayload({
    this.mobileNumber,
    this.countryCode,
    this.code,
    this.status,
    this.playerExist,
    this.valid,
    this.isSignedUp,
    this.regionCode,
    this.verificationCode,
  });

  factory SmsCodePayload.fromJson(Map<String, dynamic> json) =>
      _$SmsCodePayloadFromJson(json);

  final String? mobileNumber;
  final String? countryCode;
  final String? code;
  final String? status;
  final bool? playerExist;
  final bool? valid;
  final bool? isSignedUp;
  final String? regionCode;
  final String? verificationCode;

  Map<String, dynamic> toJson() => _$SmsCodePayloadToJson(this);
}
