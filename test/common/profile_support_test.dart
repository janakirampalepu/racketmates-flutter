import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/profile/profile_edit.dart';
import 'package:racketmates/common/support/support_api.dart';
import 'package:racketmates/common/support/support_repository.dart';
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
        'user': {'id': 7, 'first_name': 'Sam'},
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

class _Device implements DeviceDetailsSource {
  @override
  Future<DeviceDetails> read() async => const DeviceDetails(
    manufacturer: 'Google',
    model: 'Pixel 9',
    platform: 'android',
    platformVersion: '35 (15)',
  );
}

const _user = AppUser(
  id: 7,
  firstName: 'Sam',
  lastName: 'Lee',
  email: 'Sam@Example.com',
  mobileNumber: '5551234567',
  roles: ['ur_player'],
  country: UserCountry(code: 'US', regionCode: 'US'),
  userRoles: [
    UserRole(
      id: 3,
      role: 'ur_player',
      userRoleSports: [UserRoleSport(id: 9, sportType: 'st_tennis')],
    ),
  ],
);

void main() {
  group('profile rules', () {
    test('starts from the user', () {
      final edit = ProfileEdit.of(_user);
      expect(edit.firstName, 'Sam');
      expect(edit.normalizedEmail, 'sam@example.com');
      expect(profileChanged(_user, edit), isFalse);
    });

    test('names are required, the email only has to be valid', () {
      expect(
        validateProfile(
          const ProfileEdit(firstName: ' ', lastName: '', email: 'nope'),
        ),
        [
          ProfileError.firstNameMissing,
          ProfileError.lastNameMissing,
          ProfileError.emailInvalid,
        ],
      );
      expect(
        validateProfile(
          const ProfileEdit(firstName: 'A', lastName: 'B', email: ''),
        ),
        isEmpty,
      );
    });

    test('changes are noticed, case and spaces in the email are not', () {
      final base = ProfileEdit.of(_user);
      expect(profileChanged(_user, base.copyWith(firstName: 'Sammy')), isTrue);
      expect(
        profileChanged(_user, base.copyWith(email: ' sam@example.com ')),
        isFalse,
      );
      expect(
        profileChanged(_user, base.copyWith(email: 'x@example.com')),
        isTrue,
      );
    });

    test('the update body carries the edit, the phone and the roles', () {
      final body = buildProfileUpdateBody(
        _user,
        const ProfileEdit(
          firstName: 'Samuel',
          lastName: 'Lee',
          email: ' New@Example.com ',
        ),
      );
      expect(body, {
        'user': {
          'first_name': 'Samuel',
          'last_name': 'Lee',
          'email': 'new@example.com',
          'mobile_number': '5551234567',
          'user_roles_attributes': [
            {
              'id': 3,
              'role': 'ur_player',
              'user_role_sports_attributes': [
                {'id': 9, 'sport_type': 'st_tennis'},
              ],
            },
          ],
        },
        'roles': ['ur_player'],
        'region_code': 'US',
        'country_code': 'US',
      });
    });

    test('an invalid profile is not turned into a body', () {
      expect(
        () => buildProfileUpdateBody(
          _user,
          const ProfileEdit(firstName: '', lastName: 'x', email: ''),
        ),
        throwsStateError,
      );
    });
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

    test('the profile is a JSON PUT', () async {
      final details = await repo.updateProfile(7, {
        'user': {'first_name': 'S'},
      });
      final r = adapter.requests.single;
      expect(r.method, 'PUT');
      expect(r.path, 'users/7');
      expect(r.contentType, contains('json'));
      expect(r.data, {
        'user': {'first_name': 'S'},
      });
      expect(details.user?.id, 7);
    });

    test('removing the photo is a DELETE', () async {
      await repo.removeAvatar(7);
      expect(adapter.requests.single.method, 'DELETE');
      expect(adapter.requests.single.path, 'users/7/destroy_profile_image');
    });

    test('server errors become failures', () async {
      adapter.status = 422;
      await expectLater(repo.removeAvatar(7), throwsA(isA<AppFailure>()));
    });
  });

  group('support request', () {
    late _Adapter adapter;
    late SupportRepositoryImpl repo;

    setUp(() {
      adapter = _Adapter();
      repo = SupportRepositoryImpl(
        SupportApi(
          Dio(BaseOptions(baseUrl: 'https://api.example.test'))
            ..httpClientAdapter = adapter,
        ),
        device: _Device(),
        appVersion: '26.6.2',
        timezone: () async => 'America/New_York',
        locale: () => 'en-US',
      );
    });

    test('a message goes with the device facts', () async {
      await repo.sendFeedback(
        email: 'sam@example.com',
        subject: 'Help',
        feedback: 'It broke',
        mobileNumber: '5551234567',
      );
      final r = adapter.requests.single;
      expect(r.method, 'POST');
      expect(r.path, 'current_session/user_feedbacks');
      expect(r.data, {
        'user_feedback': {
          'email': 'sam@example.com',
          'subject': 'Help',
          'feedback': 'It broke',
          'mobile_number': '5551234567',
          'device_manufacturer': 'Google',
          'device_model': 'Pixel 9',
          'device_platform': 'android',
          'device_platform_version': '35 (15)',
          'device_timezone': 'America/New_York',
          'device_locale': 'en-US',
          'app_version': '26.6.2',
        },
      });
    });

    test('server errors become failures', () async {
      adapter.status = 500;
      await expectLater(
        repo.sendFeedback(email: 'a@b.co', subject: 's', feedback: 'f'),
        throwsA(isA<AppFailure>()),
      );
    });

    test('a deletion request uses the native subject and text', () {
      expect(DeleteAccountRequest.subject, 'Delete My Account');
      expect(
        DeleteAccountRequest.feedback,
        'Please delete my account at the earliest',
      );
    });
  });
}
