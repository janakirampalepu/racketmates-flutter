import 'package:json_annotation/json_annotation.dart';

part 'app_user.g.dart';

/// Role keys and sport keys exchanged with the backend (native
/// `ReferenceDataConstants` / `SportType`).
abstract final class RoleKeys {
  static const player = 'ur_player';
  static const coach = 'ur_coach';
  static const parent = 'ur_parent';
  static const all = [player, coach, parent];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class UserRoleSport {
  const UserRoleSport({this.id, this.sportType});

  factory UserRoleSport.fromJson(Map<String, dynamic> json) =>
      _$UserRoleSportFromJson(json);

  final int? id;
  final String? sportType;

  Map<String, dynamic> toJson() => _$UserRoleSportToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class UserRole {
  const UserRole({this.id, this.role, this.userRoleSports});

  factory UserRole.fromJson(Map<String, dynamic> json) =>
      _$UserRoleFromJson(json);

  final int? id;
  final String? role;
  final List<UserRoleSport>? userRoleSports;

  Map<String, dynamic> toJson() => _$UserRoleToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class UserCountry {
  const UserCountry({this.id, this.name, this.code, this.regionCode});

  factory UserCountry.fromJson(Map<String, dynamic> json) =>
      _$UserCountryFromJson(json);

  final int? id;
  final String? name;
  final String? code;
  final String? regionCode;

  Map<String, dynamic> toJson() => _$UserCountryToJson(this);
}

/// Subset of the backend user model needed so far (more fields are added with
/// the screens that use them). Unknown JSON keys are ignored.
@JsonSerializable(fieldRename: FieldRename.snake)
class AppUser {
  const AppUser({
    this.id,
    this.uid,
    this.uuid,
    this.firstName,
    this.lastName,
    this.mobileNumber,
    this.email,
    this.roles,
    this.userRoles,
    this.children,
    this.isSignedUp,
    this.country,
    this.timezoneIdentifier,
    this.avatarFileAttachmentUrl,
    this.thumbnailAttachmentUrl,
    this.consentForTextMessages,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);

  final int? id;
  final String? uid;
  final String? uuid;
  final String? firstName;
  final String? lastName;
  final String? mobileNumber;
  final String? email;
  final List<String>? roles;
  final List<UserRole>? userRoles;
  final List<AppUser>? children;
  final bool? isSignedUp;
  final UserCountry? country;
  final String? timezoneIdentifier;
  final String? avatarFileAttachmentUrl;
  final String? thumbnailAttachmentUrl;

  /// Whether the user agreed to receive text messages.
  final bool? consentForTextMessages;

  Map<String, dynamic> toJson() => _$AppUserToJson(this);

  String get displayName =>
      [firstName, lastName].whereType<String>().join(' ').trim();

  UserRole? roleOf(String key) {
    for (final role in userRoles ?? const <UserRole>[]) {
      if (role.role == key) return role;
    }
    return null;
  }
}

/// Envelope returned by `users` endpoints.
@JsonSerializable(fieldRename: FieldRename.snake)
class UserDetails {
  const UserDetails({this.user, this.message});

  factory UserDetails.fromJson(Map<String, dynamic> json) =>
      _$UserDetailsFromJson(json);

  final AppUser? user;
  final String? message;

  Map<String, dynamic> toJson() => _$UserDetailsToJson(this);
}

/// `GET validations/duplicate_dname_email_check` (`email_result` true = taken).
@JsonSerializable(fieldRename: FieldRename.snake)
class DuplicateCheck {
  const DuplicateCheck({this.result, this.emailResult, this.displayNameResult});

  factory DuplicateCheck.fromJson(Map<String, dynamic> json) =>
      _$DuplicateCheckFromJson(json);

  final bool? result;
  final bool? emailResult;
  final bool? displayNameResult;

  Map<String, dynamic> toJson() => _$DuplicateCheckToJson(this);
}
