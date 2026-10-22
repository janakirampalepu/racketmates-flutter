import 'package:racketmates/common/auth/phone_verification_repository.dart';
import 'package:racketmates/common/users/models/app_user.dart';

/// Sports offered during sign-up (native `getSportsKeys()`); [key] is the
/// backend `sport_type` value.
enum SportKey {
  badminton('st_badminton'),
  padel('st_padel'),
  pickleball('st_pickleball'),
  tennis('st_tennis');

  const SportKey(this.key);

  final String key;

  static SportKey? fromKey(String? key) {
    for (final sport in values) {
      if (sport.key == key) return sport;
    }
    return null;
  }
}

/// A child account added by a parent (max [SignUpDraft.maxKids]). Every kid is
/// a player (`ur_player`) with at least one sport.
class KidDraft {
  const KidDraft({
    this.id,
    this.firstName = '',
    this.lastName = '',
    this.mobileNumber = '',
    this.sports = const {},
    this.roleId,
    this.sportIds = const {},
  });

  final int? id;
  final String firstName;
  final String lastName;

  /// National digits; optional.
  final String mobileNumber;
  final Set<SportKey> sports;

  /// Resume only: ids of the kid's existing role and sports.
  final int? roleId;
  final Map<SportKey, int> sportIds;

  KidDraft copyWith({
    String? firstName,
    String? lastName,
    String? mobileNumber,
    Set<SportKey>? sports,
  }) => KidDraft(
    id: id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    mobileNumber: mobileNumber ?? this.mobileNumber,
    sports: sports ?? this.sports,
    roleId: roleId,
    sportIds: sportIds,
  );
}

/// Everything collected across the sign-up screens; sent in one request at the
/// end (native `SignUpViewModel.createUserAccount`).
class SignUpDraft {
  const SignUpDraft({
    required this.phone,
    required this.verificationCode,
    this.resume = false,
    this.userId,
    this.timezone = 'UTC',
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.roles = const {},
    this.playerSports = const {},
    this.coachSports = const {},
    this.kids = const [],
    this.roleIds = const {},
    this.sportIds = const {},
  });

  static const maxKids = 2;

  final PhoneNumberParts phone;
  final String verificationCode;

  /// An account exists but sign-up was left unfinished (native `isPlayerExist`).
  final bool resume;
  final int? userId;
  final String timezone;
  final String firstName;
  final String lastName;
  final String email;

  /// Selected role keys (`RoleKeys`).
  final Set<String> roles;
  final Set<SportKey> playerSports;
  final Set<SportKey> coachSports;
  final List<KidDraft> kids;

  /// Resume only: existing role ids by role key, and existing sport ids by
  /// role key then sport (so deselected sports can be destroyed).
  final Map<String, int> roleIds;
  final Map<String, Map<SportKey, int>> sportIds;

  bool get hasPlayer => roles.contains(RoleKeys.player);
  bool get hasCoach => roles.contains(RoleKeys.coach);
  bool get hasParent => roles.contains(RoleKeys.parent);
  bool get hasOnlyParent => hasParent && !hasPlayer && !hasCoach;

  /// Native display name: first initial (upper case) + last name without
  /// whitespace; checked with the duplicate-email endpoint.
  String get displayName {
    final first = firstName.trim();
    final last = lastName.replaceAll(RegExp(r'\s'), '');
    if (first.isEmpty) return last;
    return first[0].toUpperCase() + last;
  }

  SignUpDraft copyWith({
    String? timezone,
    String? firstName,
    String? lastName,
    String? email,
    Set<String>? roles,
    Set<SportKey>? playerSports,
    Set<SportKey>? coachSports,
    List<KidDraft>? kids,
    Map<String, int>? roleIds,
    Map<String, Map<SportKey, int>>? sportIds,
  }) => SignUpDraft(
    phone: phone,
    verificationCode: verificationCode,
    resume: resume,
    userId: userId,
    timezone: timezone ?? this.timezone,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    email: email ?? this.email,
    roles: roles ?? this.roles,
    playerSports: playerSports ?? this.playerSports,
    coachSports: coachSports ?? this.coachSports,
    kids: kids ?? this.kids,
    roleIds: roleIds ?? this.roleIds,
    sportIds: sportIds ?? this.sportIds,
  );
}
