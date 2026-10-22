import 'package:dio/dio.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/users/models/app_user.dart';

/// Multipart field names of the existing `users` sign-up/update contract
/// (native `getSignUpMultipartRequest`). New accounts nest kids under
/// `user[children][i]`; resumed accounts use `user[children_attributes][i]`
/// with `parent_user_id`/`id`/`_destroy`.
List<MapEntry<String, String>> signUpFields(SignUpDraft draft) {
  final out = <MapEntry<String, String>>[];
  void add(String key, String? value) => out.add(MapEntry(key, value ?? ''));

  add('country_code', draft.phone.countryCode);
  add('region_code', draft.phone.regionCode);
  add('verification_code', draft.verificationCode);

  if (draft.resume && draft.userId != null) add('user[id]', '${draft.userId}');
  add('user[first_name]', draft.firstName.trim());
  add('user[last_name]', draft.lastName.trim());
  add('user[mobile_number]', draft.phone.nationalNumber);
  add('user[email]', draft.email.trim().toLowerCase());
  add('user[timezone_identifier]', draft.timezone);

  final childKey = draft.resume ? 'children_attributes' : 'children';
  for (var i = 0; i < draft.kids.length; i++) {
    final kid = draft.kids[i];
    final prefix = 'user[$childKey][$i]';
    if (draft.resume && kid.id != null) add('$prefix[id]', '${kid.id}');
    add('$prefix[first_name]', kid.firstName.trim());
    add('$prefix[last_name]', kid.lastName.trim());
    add('$prefix[mobile_number]', kid.mobileNumber);
    if (draft.resume) add('$prefix[parent_user_id]', '${draft.userId}');
    final rolePrefix = '$prefix[user_roles_attributes][0]';
    if (kid.roleId != null) add('$rolePrefix[id]', '${kid.roleId}');
    add('$rolePrefix[role]', RoleKeys.player);
    _sports(
      out,
      '$rolePrefix[user_role_sports_attributes]',
      selected: kid.sports,
      existing: kid.sportIds,
    );
  }

  var roleIndex = 0;
  for (final role in RoleKeys.all) {
    final id = draft.roleIds[role];
    if (!draft.roles.contains(role) && id == null) continue;
    final prefix = 'user[user_roles_attributes][${roleIndex++}]';
    if (id != null) add('$prefix[id]', '$id');
    add('$prefix[role]', role);
    final selected = switch (role) {
      RoleKeys.player => draft.playerSports,
      RoleKeys.coach => draft.coachSports,
      _ => const <SportKey>{},
    };
    _sports(
      out,
      '$prefix[user_role_sports_attributes]',
      selected: draft.roles.contains(role) ? selected : const {},
      existing: draft.sportIds[role] ?? const {},
    );
  }
  return out;
}

void _sports(
  List<MapEntry<String, String>> out,
  String prefix, {
  required Set<SportKey> selected,
  required Map<SportKey, int> existing,
}) {
  var i = 0;
  for (final sport in SportKey.values) {
    final id = existing[sport];
    final isSelected = selected.contains(sport);
    if (!isSelected && id == null) continue;
    final p = '$prefix[${i++}]';
    if (id != null) out.add(MapEntry('$p[id]', '$id'));
    out.add(MapEntry('$p[sport_type]', sport.key));
    if (!isSelected && id != null) out.add(MapEntry('$p[_destroy]', 'true'));
  }
}

FormData buildSignUpForm(SignUpDraft draft) =>
    FormData.fromMap({for (final e in signUpFields(draft)) e.key: e.value});
