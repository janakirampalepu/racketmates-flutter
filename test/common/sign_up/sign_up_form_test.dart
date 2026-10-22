import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/auth/phone_verification_repository.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/sign_up/sign_up_form.dart';
import 'package:racketmates/common/sign_up/sign_up_steps.dart';
import 'package:racketmates/common/users/models/app_user.dart';

const _phone = PhoneNumberParts(
  nationalNumber: '5551234567',
  countryCode: '1',
  regionCode: 'US',
);

SignUpDraft _draft({
  bool resume = false,
  Set<String> roles = const {RoleKeys.player},
  Set<SportKey> player = const {SportKey.tennis},
  Set<SportKey> coach = const {},
  List<KidDraft> kids = const [],
  Map<String, int> roleIds = const {},
  Map<String, Map<SportKey, int>> sportIds = const {},
}) => SignUpDraft(
  phone: _phone,
  verificationCode: 'vc',
  resume: resume,
  userId: resume ? 7 : null,
  timezone: 'America/New_York',
  firstName: ' Sam ',
  lastName: 'Lee Jr',
  email: ' Sam@Example.com ',
  roles: roles,
  playerSports: player,
  coachSports: coach,
  kids: kids,
  roleIds: roleIds,
  sportIds: sportIds,
);

Map<String, String> _fields(SignUpDraft d) => {
  for (final e in signUpFields(d)) e.key: e.value,
};

void main() {
  test('new player account uses the native multipart keys', () {
    expect(_fields(_draft()), {
      'country_code': '1',
      'region_code': 'US',
      'verification_code': 'vc',
      'user[first_name]': 'Sam',
      'user[last_name]': 'Lee Jr',
      'user[mobile_number]': '5551234567',
      'user[email]': 'sam@example.com',
      'user[timezone_identifier]': 'America/New_York',
      'user[user_roles_attributes][0][role]': 'ur_player',
      'user[user_roles_attributes][0][user_role_sports_attributes][0][sport_type]':
          'st_tennis',
    });
  });

  test('roles are written in player, coach, parent order with their own sports', () {
    final f = _fields(
      _draft(
        roles: {RoleKeys.parent, RoleKeys.coach, RoleKeys.player},
        player: {SportKey.padel, SportKey.badminton},
        coach: {SportKey.tennis},
        kids: [
          const KidDraft(
            firstName: 'Kid',
            lastName: 'Lee',
            mobileNumber: '5559998888',
            sports: {SportKey.pickleball},
          ),
        ],
      ),
    );
    const r = 'user[user_roles_attributes]';
    expect(f['$r[0][role]'], 'ur_player');
    expect(
      f['$r[0][user_role_sports_attributes][0][sport_type]'],
      'st_badminton',
    );
    expect(f['$r[0][user_role_sports_attributes][1][sport_type]'], 'st_padel');
    expect(f['$r[1][role]'], 'ur_coach');
    expect(f['$r[1][user_role_sports_attributes][0][sport_type]'], 'st_tennis');
    expect(f['$r[2][role]'], 'ur_parent');
    expect(
      f.keys.where((k) => k.startsWith('$r[2][user_role_sports')),
      isEmpty,
    );
    // kid: nested under children[0], always a player
    expect(f['user[children][0][first_name]'], 'Kid');
    expect(f['user[children][0][mobile_number]'], '5559998888');
    expect(f['user[children][0][user_roles_attributes][0][role]'], 'ur_player');
    expect(
      f['user[children][0][user_roles_attributes][0][user_role_sports_attributes][0][sport_type]'],
      'st_pickleball',
    );
    expect(f.containsKey('user[children][0][parent_user_id]'), isFalse);
  });

  test(
    'resume sends ids, destroys deselected sports and uses children_attributes',
    () {
      final f = _fields(
        _draft(
          resume: true,
          roles: {RoleKeys.player, RoleKeys.parent},
          player: {SportKey.tennis},
          roleIds: {RoleKeys.player: 11, RoleKeys.parent: 12},
          sportIds: {
            RoleKeys.player: {SportKey.tennis: 21, SportKey.padel: 22},
          },
          kids: [
            const KidDraft(
              id: 31,
              firstName: 'Kid',
              lastName: 'Lee',
              sports: {SportKey.tennis},
              roleId: 41,
              sportIds: {SportKey.tennis: 51},
            ),
          ],
        ),
      );
      expect(f['user[id]'], '7');
      const p = 'user[user_roles_attributes][0]';
      expect(f['$p[id]'], '11');
      const sp = '$p[user_role_sports_attributes]';
      expect(f['$sp[0][id]'], '22'); // padel: existing but deselected
      expect(f['$sp[0][sport_type]'], 'st_padel');
      expect(f['$sp[0][_destroy]'], 'true');
      expect(f['$sp[1][id]'], '21');
      expect(f.containsKey('$sp[1][_destroy]'), isFalse);
      expect(f['user[user_roles_attributes][1][id]'], '12');
      const k = 'user[children_attributes][0]';
      expect(f['$k[id]'], '31');
      expect(f['$k[parent_user_id]'], '7');
      expect(f['$k[user_roles_attributes][0][id]'], '41');
      expect(
        f['$k[user_roles_attributes][0][user_role_sports_attributes][0][id]'],
        '51',
      );
    },
  );

  test('display name is first initial + last name without spaces', () {
    expect(_draft().displayName, 'SLeeJr');
    expect(
      const SignUpDraft(
        phone: _phone,
        verificationCode: '',
        firstName: '',
        lastName: 'A B',
      ).displayName,
      'AB',
    );
  });

  group('next step rules', () {
    SignUpDraft d(Set<String> roles, {List<KidDraft> kids = const []}) =>
        _draft(roles: roles, kids: kids);
    const kid = KidDraft(firstName: 'K');

    test('after roles', () {
      expect(stepAfterRoles(d({RoleKeys.player})), SignUpStep.playerSports);
      expect(
        stepAfterRoles(d({RoleKeys.player, RoleKeys.coach})),
        SignUpStep.playerSports,
      );
      expect(stepAfterRoles(d({RoleKeys.coach})), SignUpStep.coachSports);
      expect(stepAfterRoles(d({RoleKeys.parent})), SignUpStep.kidForm);
      expect(
        stepAfterRoles(d({RoleKeys.parent}, kids: [kid])),
        SignUpStep.kidsList,
      );
    });

    test('after player sports', () {
      expect(
        stepAfterPlayerSports(d({RoleKeys.player})),
        SignUpStep.createAccount,
      );
      expect(
        stepAfterPlayerSports(d({RoleKeys.player, RoleKeys.coach})),
        SignUpStep.coachSports,
      );
      expect(
        stepAfterPlayerSports(d({RoleKeys.player, RoleKeys.parent})),
        SignUpStep.kidForm,
      );
    });

    test('after coach sports', () {
      expect(
        stepAfterCoachSports(d({RoleKeys.coach})),
        SignUpStep.createAccount,
      );
      expect(
        stepAfterCoachSports(d({RoleKeys.coach, RoleKeys.parent}, kids: [kid])),
        SignUpStep.kidsList,
      );
    });
  });
}
