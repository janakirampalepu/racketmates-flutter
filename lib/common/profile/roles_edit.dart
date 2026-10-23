import 'package:dio/dio.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/sign_up/sign_up_form.dart';
import 'package:racketmates/common/users/models/app_user.dart';

/// The sports a user has for [role], from the profile.
Set<SportKey> sportsOfRole(AppUser user, String role) => {
  for (final s in user.roleOf(role)?.userRoleSports ?? const <UserRoleSport>[])
    ?SportKey.fromKey(s.sportType),
};

/// A role needs at least one sport (native `isNoSportSelected`).
bool sportsValid(Set<SportKey> selected) => selected.isNotEmpty;

/// Body of `PUT users/{id}/user_roles/{roleId}` and `POST users/{id}/user_roles`
/// (native `getUserRoleSportsResuest`): sports kept or added, and `_destroy`
/// for sports the user had and no longer has.
Map<String, dynamic> buildRoleSportsBody(
  AppUser user,
  String role,
  Set<SportKey> selected,
) {
  if (!sportsValid(selected)) throw StateError('a role needs a sport');
  final existing = {
    for (final s
        in user.roleOf(role)?.userRoleSports ?? const <UserRoleSport>[])
      if (SportKey.fromKey(s.sportType) != null)
        SportKey.fromKey(s.sportType)!: s.id,
  };
  return {
    'user_role': {
      'role': role,
      'user_role_sports_attributes': [
        for (final sport in SportKey.values)
          if (selected.contains(sport) || existing[sport] != null)
            {
              'id': ?existing[sport],
              'sport_type': sport.key,
              if (!selected.contains(sport)) '_destroy': true,
            },
      ],
    },
  };
}

/// What the kid form collects.
class KidInput {
  const KidInput({
    required this.firstName,
    required this.lastName,
    this.mobileNumber = '',
    this.sports = const {},
  });

  factory KidInput.of(AppUser kid) => KidInput(
    firstName: kid.firstName ?? '',
    lastName: kid.lastName ?? '',
    mobileNumber: kid.mobileNumber ?? '',
    sports: sportsOfRole(kid, RoleKeys.player),
  );

  final String firstName;
  final String lastName;

  /// National digits, optional.
  final String mobileNumber;
  final Set<SportKey> sports;
}

enum KidError { firstNameMissing, lastNameMissing, sportMissing }

List<KidError> validateKid(KidInput kid) => [
  if (kid.firstName.trim().isEmpty) KidError.firstNameMissing,
  if (kid.lastName.trim().isEmpty) KidError.lastNameMissing,
  if (kid.sports.isEmpty) KidError.sportMissing,
];

/// Multipart fields to add or update a kid (native `getKidMultipartRequest`):
/// the names, the optional mobile number without spaces, the parent, and the
/// kid's player role with its sports. [existing] is the kid being updated,
/// whose role and sport ids are kept so removed sports are destroyed.
List<MapEntry<String, String>> kidFields(
  KidInput kid, {
  required int parentId,
  AppUser? existing,
}) {
  if (validateKid(kid).isNotEmpty) throw StateError('incomplete kid');
  final out = <MapEntry<String, String>>[
    MapEntry('user[first_name]', kid.firstName.trim()),
    MapEntry('user[last_name]', kid.lastName.trim()),
    MapEntry('user[mobile_number]', kid.mobileNumber.replaceAll(' ', '')),
    MapEntry('user[parent_user_id]', '$parentId'),
  ];
  const role = 'user[user_roles_attributes][0]';
  final roleId = existing?.roleOf(RoleKeys.player)?.id;
  if (roleId != null) out.add(MapEntry('$role[id]', '$roleId'));
  out.add(const MapEntry('$role[role]', RoleKeys.player));
  appendSportFields(
    out,
    '$role[user_role_sports_attributes]',
    selected: kid.sports,
    existing: {
      for (final s
          in existing?.roleOf(RoleKeys.player)?.userRoleSports ??
              const <UserRoleSport>[])
        if (SportKey.fromKey(s.sportType) != null && s.id != null)
          SportKey.fromKey(s.sportType)!: s.id!,
    },
  );
  return out;
}

FormData kidForm(KidInput kid, {required int parentId, AppUser? existing}) =>
    FormData.fromMap({
      for (final e in kidFields(kid, parentId: parentId, existing: existing))
        e.key: e.value,
    });

/// Most kids a parent can have (native limit of two).
const maxKids = 2;

/// Body of `PUT users/{id}/change_mobile_number` (native `FormSmsCode` with
/// number, country and region only): digits only.
Map<String, dynamic> changeMobileBody({
  required String nationalNumber,
  required String countryCode,
  required String regionCode,
}) => {
  'mobile_number': nationalNumber.replaceAll(RegExp(r'\D'), ''),
  'country_code': countryCode.replaceAll(RegExp(r'\D'), ''),
  'region_code': regionCode,
};
