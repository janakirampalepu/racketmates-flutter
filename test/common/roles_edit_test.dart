import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/profile/roles_edit.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/common/users/user_api.dart';
import 'package:racketmates/common/users/user_repository.dart';

class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int status = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({
        'user': {'id': 7},
      }),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _user = AppUser(
  id: 7,
  userRoles: [
    UserRole(
      id: 3,
      role: 'ur_player',
      userRoleSports: [
        UserRoleSport(id: 9, sportType: 'st_tennis'),
        UserRoleSport(id: 10, sportType: 'st_padel'),
      ],
    ),
  ],
);

const _kid = AppUser(
  id: 21,
  firstName: 'Kai',
  lastName: 'Lee',
  mobileNumber: '5559998888',
  userRoles: [
    UserRole(
      id: 51,
      role: 'ur_player',
      userRoleSports: [UserRoleSport(id: 61, sportType: 'st_tennis')],
    ),
  ],
);

Map<String, String> _fields(List<MapEntry<String, String>> f) => {
  for (final e in f) e.key: e.value,
};

void main() {
  group('role sports', () {
    test('the sports a role has', () {
      expect(sportsOfRole(_user, RoleKeys.player), {
        SportKey.tennis,
        SportKey.padel,
      });
      expect(sportsOfRole(_user, RoleKeys.coach), isEmpty);
    });

    test('a role needs a sport', () {
      expect(sportsValid({}), isFalse);
      expect(sportsValid({SportKey.tennis}), isTrue);
      expect(
        () => buildRoleSportsBody(_user, RoleKeys.player, {}),
        throwsStateError,
      );
    });

    test(
      'kept sports keep their id, removed ones are destroyed, new ones added',
      () {
        final body = buildRoleSportsBody(_user, RoleKeys.player, {
          SportKey.tennis,
          SportKey.pickleball,
        });
        expect(body, {
          'user_role': {
            'role': 'ur_player',
            'user_role_sports_attributes': [
              {'id': 10, 'sport_type': 'st_padel', '_destroy': true},
              {'sport_type': 'st_pickleball'},
              {'id': 9, 'sport_type': 'st_tennis'},
            ],
          },
        });
      },
    );

    test('a role the user lacks is just its sports', () {
      expect(buildRoleSportsBody(_user, RoleKeys.coach, {SportKey.padel}), {
        'user_role': {
          'role': 'ur_coach',
          'user_role_sports_attributes': [
            {'sport_type': 'st_padel'},
          ],
        },
      });
    });
  });

  group('kids', () {
    test('a kid needs names and a sport', () {
      expect(validateKid(const KidInput(firstName: ' ', lastName: '')), [
        KidError.firstNameMissing,
        KidError.lastNameMissing,
        KidError.sportMissing,
      ]);
      expect(
        validateKid(
          const KidInput(
            firstName: 'A',
            lastName: 'B',
            sports: {SportKey.tennis},
          ),
        ),
        isEmpty,
      );
      expect(
        () =>
            kidFields(const KidInput(firstName: '', lastName: ''), parentId: 7),
        throwsStateError,
      );
    });

    test('a new kid: names, parent, player role and sports', () {
      final fields = _fields(
        kidFields(
          const KidInput(
            firstName: ' Kai ',
            lastName: 'Lee',
            mobileNumber: '555 123',
            sports: {SportKey.tennis},
          ),
          parentId: 7,
        ),
      );
      expect(fields, {
        'user[first_name]': 'Kai',
        'user[last_name]': 'Lee',
        'user[mobile_number]': '555123',
        'user[parent_user_id]': '7',
        'user[user_roles_attributes][0][role]': 'ur_player',
        'user[user_roles_attributes][0][user_role_sports_attributes][0][sport_type]':
            'st_tennis',
      });
    });

    test(
      'an edited kid keeps role and sport ids and destroys a removed sport',
      () {
        final input = KidInput(
          firstName: 'Kai',
          lastName: 'Lee',
          mobileNumber: '5559998888',
          sports: const {SportKey.padel},
        );
        final fields = _fields(kidFields(input, parentId: 7, existing: _kid));
        const role = 'user[user_roles_attributes][0]';
        expect(fields['$role[id]'], '51');
        expect(
          fields['$role[user_role_sports_attributes][0][sport_type]'],
          'st_padel',
        );
        expect(fields['$role[user_role_sports_attributes][1][id]'], '61');
        expect(
          fields['$role[user_role_sports_attributes][1][sport_type]'],
          'st_tennis',
        );
        expect(
          fields['$role[user_role_sports_attributes][1][_destroy]'],
          'true',
        );
      },
    );

    test('the form is multipart fields', () {
      final form = kidForm(
        const KidInput(
          firstName: 'Kai',
          lastName: 'Lee',
          sports: {SportKey.tennis},
        ),
        parentId: 7,
      );
      expect(form.fields.map((e) => e.key), contains('user[parent_user_id]'));
    });

    test('the kid form starts from the kid', () {
      final input = KidInput.of(_kid);
      expect(input.firstName, 'Kai');
      expect(input.sports, {SportKey.tennis});
    });
  });

  test('the new number is sent as digits', () {
    expect(
      changeMobileBody(
        nationalNumber: '(555) 123-4567',
        countryCode: '+1',
        regionCode: 'US',
      ),
      {'mobile_number': '5551234567', 'country_code': '1', 'region_code': 'US'},
    );
  });

  group('user calls', () {
    late _Adapter adapter;
    late UserRepositoryImpl repo;

    setUp(() {
      adapter = _Adapter();
      repo = UserRepositoryImpl(
        UserApi(
          Dio(BaseOptions(baseUrl: 'https://api.example.test'))
            ..httpClientAdapter = adapter,
        ),
      );
    });

    test('sports of an existing role are a PUT, a new role a POST', () async {
      await repo.updateRole(7, 3, {'user_role': <String, dynamic>{}});
      await repo.addRole(7, {'user_role': <String, dynamic>{}});
      expect(adapter.requests[0].method, 'PUT');
      expect(adapter.requests[0].path, 'users/7/user_roles/3');
      expect(adapter.requests[1].method, 'POST');
      expect(adapter.requests[1].path, 'users/7/user_roles');
    });

    test('a kid is a multipart POST to users, removed with a DELETE', () async {
      await repo.createKid(
        kidForm(
          const KidInput(
            firstName: 'K',
            lastName: 'L',
            sports: {SportKey.tennis},
          ),
          parentId: 7,
        ),
      );
      await repo.deleteUser(21);
      final post = adapter.requests[0];
      expect(post.method, 'POST');
      expect(post.path, 'users');
      expect(post.queryParameters, isEmpty); // not a sign-up
      expect(post.contentType, contains('multipart'));
      expect(adapter.requests[1].method, 'DELETE');
      expect(adapter.requests[1].path, 'users/21');
    });

    test('the mobile number change is a PUT', () async {
      await repo.changeMobileNumber(7, {'mobile_number': '5551230000'});
      final r = adapter.requests.single;
      expect(r.method, 'PUT');
      expect(r.path, 'users/7/change_mobile_number');
      expect(r.data, {'mobile_number': '5551230000'});
    });

    test('server errors become failures', () async {
      adapter.status = 422;
      await expectLater(repo.deleteUser(1), throwsA(isA<AppFailure>()));
    });
  });
}
