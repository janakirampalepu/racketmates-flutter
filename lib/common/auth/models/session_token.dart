import 'package:json_annotation/json_annotation.dart';

part 'session_token.g.dart';

/// Response of `POST oauth/token` (password and refresh grants). Field names
/// mirror the native `SessionToken` model (snake_case JSON).
@JsonSerializable(fieldRename: FieldRename.snake)
class SessionToken {
  const SessionToken({
    this.accessToken,
    this.tokenType,
    this.expiresIn,
    this.refreshToken,
    this.createdAt,
    this.user,
  });

  factory SessionToken.fromJson(Map<String, dynamic> json) =>
      _$SessionTokenFromJson(json);

  final String? accessToken;
  final String? tokenType;

  /// Lifetime in seconds.
  final int? expiresIn;
  final String? refreshToken;

  /// Issue time, epoch seconds.
  final int? createdAt;
  final SessionTokenUser? user;

  Map<String, dynamic> toJson() => _$SessionTokenToJson(this);

  /// Epoch seconds at which the access token expires, or null if unknown.
  int? get expiresAtEpochSeconds =>
      (createdAt == null || expiresIn == null) ? null : createdAt! + expiresIn!;

  /// Native rule: expired when `created_at + expires_in <= now` (UTC seconds).
  bool isExpiredAt(DateTime now) {
    final expiresAt = expiresAtEpochSeconds;
    if (expiresAt == null) return false;
    return expiresAt <= now.toUtc().millisecondsSinceEpoch ~/ 1000;
  }

  bool get hasRefreshToken => (refreshToken ?? '').isNotEmpty;
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SessionTokenUser {
  const SessionTokenUser({this.id, this.uid, this.uuid, this.isSignedUp});

  factory SessionTokenUser.fromJson(Map<String, dynamic> json) =>
      _$SessionTokenUserFromJson(json);

  final int? id;
  final String? uid;
  final String? uuid;

  /// False while sign-up is unfinished (native `IS_SIGN_UP_COMPLETE`).
  final bool? isSignedUp;

  Map<String, dynamic> toJson() => _$SessionTokenUserToJson(this);
}
