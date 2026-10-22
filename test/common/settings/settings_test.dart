import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/auth/models/session_token.dart';
import 'package:racketmates/common/auth/native_session.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/auth/token_store.dart';
import 'package:racketmates/common/config/config_providers.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/notifications/push_models.dart';
import 'package:racketmates/common/notifications/push_platform.dart';
import 'package:racketmates/common/notifications/push_registrar.dart';
import 'package:racketmates/common/settings/logout.dart';
import 'package:racketmates/common/settings/reminder_rules.dart';
import 'package:racketmates/common/settings/settings_api.dart';
import 'package:racketmates/common/settings/settings_models.dart';
import 'package:racketmates/common/settings/settings_repository.dart';

import '../../support/fakes.dart';

class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int status = 200;
  Object body = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ProviderContainer _container({
  FakeSettingsRepository? settings,
  FakePushPlatform? push,
  InMemoryPushTokenStore? store,
  bool signedIn = true,
}) {
  final c = ProviderContainer(
    overrides: [
      environmentConfigProvider.overrideWithValue(testConfig),
      tokenStoreProvider.overrideWithValue(
        InMemoryTokenStore(
          signedIn
              ? const SessionToken(
                  accessToken: 'a',
                  refreshToken: 'r',
                  user: SessionTokenUser(id: 7),
                )
              : null,
        ),
      ),
      authApiProvider.overrideWithValue(FakeAuthApi()),
      nativeSessionSourceProvider.overrideWithValue(FakeNativeSessionSource()),
      settingsRepositoryProvider.overrideWithValue(
        settings ?? FakeSettingsRepository(),
      ),
      pushPlatformProvider.overrideWithValue(push ?? FakePushPlatform()),
      pushTokenStoreProvider.overrideWithValue(
        store ?? InMemoryPushTokenStore(),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('reminder rules', () {
    test('values per unit', () {
      expect(reminderValuesFor(ReminderUnits.minute), [
        5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, //
      ]);
      expect(reminderValuesFor(ReminderUnits.hour), hasLength(23));
      expect(reminderValuesFor(ReminderUnits.hour).first, 1);
      expect(reminderValuesFor(ReminderUnits.day).last, 28);
      expect(reminderValuesFor('nope'), isEmpty);
    });

    test('request body', () {
      expect(buildReminderBody(value: 30, unit: ReminderUnits.minute), {
        'user_reminder_preference': {
          'reminder_unit': 30,
          'reminder_unit_type': 'rut_minute',
        },
      });
    });

    test('an out-of-range value is rejected', () {
      expect(
        () => buildReminderBody(value: 7, unit: ReminderUnits.minute),
        throwsArgumentError,
      );
      expect(
        () => buildReminderBody(value: 29, unit: ReminderUnits.day),
        throwsArgumentError,
      );
    });
  });

  group('routeForNotification', () {
    test('event pages open the event', () {
      for (final page in [
        'nnp_event_details_page',
        'nnp_event_updated_details_page',
        'nnp_update_availability_page',
        'nnp_event_options_preference_page',
      ]) {
        final route = routeForNotification({
          'navigation_page': page,
          'event_id': '55',
        });
        expect(route, isA<OpenEvent>().having((r) => r.eventId, 'id', 55));
      }
    });

    test('an event page without a usable id opens home', () {
      expect(
        routeForNotification({'navigation_page': 'nnp_event_details_page'}),
        isA<OpenHome>(),
      );
      expect(
        routeForNotification({
          'navigation_page': 'nnp_event_details_page',
          'event_id': 'x',
        }),
        isA<OpenHome>(),
      );
    });

    test('team pages', () {
      expect(
        routeForNotification({
          'navigation_page': 'nnp_team_details_page',
          'team_id': '9',
        }),
        isA<OpenTeam>().having((r) => r.teamId, 'id', 9),
      );
      expect(
        routeForNotification({'navigation_page': 'nnp_team_details_page'}),
        isA<OpenTeams>(),
      );
      expect(
        routeForNotification({'navigation_page': 'nnp_team_list_page'}),
        isA<OpenTeams>(),
      );
    });

    test('chat, league and unknown pages', () {
      expect(
        routeForNotification({'sendbird': '{}', 'channel_url': 'c1'}),
        isA<OpenChat>().having((r) => r.channelUrl, 'url', 'c1'),
      );
      expect(routeForNotification({}), isA<OpenHome>());
      expect(
        routeForNotification({'navigation_page': 'nnp_league_page'}),
        isA<OpenHome>(),
      );
    });

    test('PushMessage.fromMap stringifies the payload', () {
      final m = PushMessage.fromMap({
        'id': 'm1',
        'title': 'T',
        'data': {'event_id': 5, 'skip': null},
      });
      expect(m.id, 'm1');
      expect(m.data, {'event_id': '5'});
    });
  });

  group('SettingsRepository contracts', () {
    late _Adapter adapter;
    late SettingsRepositoryImpl repo;

    setUp(() {
      adapter = _Adapter();
      repo = SettingsRepositoryImpl(
        SettingsApi(
          Dio(BaseOptions(baseUrl: 'https://api.example.test'))
            ..httpClientAdapter = adapter,
        ),
      );
    });

    test('reminders are listed, null entries dropped', () async {
      adapter.body = {
        'user_reminder_preferences': [
          {'id': 1, 'reminder_unit': 30, 'reminder_unit_type': 'rut_minute'},
          null,
        ],
      };
      final list = await repo.reminders(7);
      expect(adapter.requests.single.path, 'users/7/user_reminder_preferences');
      expect(list.single.reminderUnit, 30);
      expect(list.single.reminderUnitType, 'rut_minute');
    });

    test('add and remove reminder', () async {
      await repo.addReminder(7, value: 2, unit: ReminderUnits.hour);
      final add = adapter.requests.single;
      expect(add.method, 'POST');
      expect(add.path, 'users/7/user_reminder_preferences');
      expect(add.data, {
        'user_reminder_preference': {
          'reminder_unit': 2,
          'reminder_unit_type': 'rut_hour',
        },
      });
      await repo.removeReminder(7, 12);
      expect(adapter.requests.last.method, 'DELETE');
      expect(
        adapter.requests.last.path,
        'users/7/user_reminder_preferences/12',
      );
    });

    test('text consent is a query parameter', () async {
      await repo.setTextConsent(consent: true);
      final r = adapter.requests.single;
      expect(r.method, 'PUT');
      expect(r.path, 'current_session/update_text_consent');
      expect(r.queryParameters, {'text_consent': true});
    });

    test('Android registers the token form-encoded', () async {
      await repo.registerDeviceToken(
        'fcm-1',
        platform: TargetPlatform.android,
        language: 'en',
      );
      final r = adapter.requests.single;
      expect(r.path, 'current_session/register_device_token');
      expect(r.contentType, contains('x-www-form-urlencoded'));
      expect(r.data, {
        'device_token': 'fcm-1',
        'platform': 'android',
        'preferred_language': 'en',
      });
    });

    test('iOS registers the raw token as JSON', () async {
      await repo.registerDeviceToken(
        'abcdef',
        platform: TargetPlatform.iOS,
        language: 'en',
      );
      final r = adapter.requests.single;
      expect(r.contentType, contains('json'));
      expect(r.data, {
        'device_token': 'abcdef',
        'platform': 'ios',
        'preferred_language': 'en',
      });
    });

    test('revoke sends the token', () async {
      await repo.revokeDeviceToken('t');
      final r = adapter.requests.single;
      expect(r.path, 'current_session/revoke_device_token');
      expect(r.data, {'device_token': 't'});
    });

    test('server errors become failures', () async {
      adapter
        ..status = 422
        ..body = {'error_message': 'bad'};
      await expectLater(
        repo.setTextConsent(consent: false),
        throwsA(isA<AppFailure>()),
      );
    });
  });

  group('PushRegistrar', () {
    Future<ProviderContainer> signedIn({
      FakeSettingsRepository? settings,
      FakePushPlatform? push,
      InMemoryPushTokenStore? store,
    }) async {
      final c = _container(settings: settings, push: push, store: store);
      await c.read(sessionControllerProvider.notifier).restore();
      return c;
    }

    test('registers the token once and remembers it', () async {
      final settings = FakeSettingsRepository();
      final store = InMemoryPushTokenStore();
      final c = await signedIn(
        settings: settings,
        push: FakePushPlatform(available: true),
        store: store,
      );
      final registrar = c.read(pushRegistrarProvider);
      expect(await registrar.start(), isTrue);
      expect(await registrar.start(), isTrue);
      expect(settings.registrations, hasLength(1));
      expect(settings.registrations.single.token, 'device-token-1');
      expect(settings.registrations.single.language, 'en');
      expect(store.value?.token, 'device-token-1');
    });

    test('a changed token is sent again', () async {
      final settings = FakeSettingsRepository();
      final c = await signedIn(
        settings: settings,
        push: FakePushPlatform(available: true),
      );
      final registrar = c.read(pushRegistrarProvider);
      await registrar.register('one');
      await registrar.register('two');
      expect(settings.registrations.map((r) => r.token), ['one', 'two']);
    });

    test('nothing happens without push support or permission', () async {
      final settings = FakeSettingsRepository();
      var c = await signedIn(settings: settings, push: FakePushPlatform());
      expect(await c.read(pushRegistrarProvider).start(), isFalse);

      final denied = FakePushPlatform(
        available: true,
        permissionState: PushPermission.denied,
      );
      c = await signedIn(settings: settings, push: denied);
      expect(await c.read(pushRegistrarProvider).start(), isFalse);
      expect(denied.permissionRequests, 0); // a refusal is not asked again
      expect(settings.registrations, isEmpty);
    });

    test('permission is requested when undecided', () async {
      final push = FakePushPlatform(
        available: true,
        permissionState: PushPermission.notDetermined,
      );
      final c = await signedIn(push: push);
      expect(await c.read(pushRegistrarProvider).start(), isTrue);
      expect(push.permissionRequests, 1);
    });

    test('a failed registration is not remembered', () async {
      final settings = FakeSettingsRepository()
        ..failure = const OfflineFailure();
      final store = InMemoryPushTokenStore();
      final c = await signedIn(
        settings: settings,
        push: FakePushPlatform(available: true),
        store: store,
      );
      expect(await c.read(pushRegistrarProvider).register('t'), isFalse);
      expect(store.value, isNull);
    });

    test('unregister revokes the remembered token and forgets it', () async {
      final settings = FakeSettingsRepository();
      final store = InMemoryPushTokenStore()
        ..value = (token: 'remembered', userId: 7);
      final c = await signedIn(settings: settings, store: store);
      await c.read(pushRegistrarProvider).unregister();
      expect(settings.revoked, ['remembered']);
      expect(store.value, isNull);
    });

    test('unregister survives a failing revoke', () async {
      final settings = FakeSettingsRepository()
        ..failure = const OfflineFailure();
      final store = InMemoryPushTokenStore()..value = (token: 't', userId: 7);
      final c = await signedIn(settings: settings, store: store);
      await c.read(pushRegistrarProvider).unregister();
      expect(store.value, isNull);
    });
  });

  group('logout', () {
    test('the device token is revoked before the session ends', () async {
      final settings = FakeSettingsRepository();
      final store = InMemoryPushTokenStore()..value = (token: 't', userId: 7);
      final c = _container(settings: settings, store: store);
      await c.read(sessionControllerProvider.notifier).restore();
      await c.read(logoutProvider)();
      expect(settings.revoked, ['t']);
      expect(c.read(sessionControllerProvider), isNot(isA<SignedIn>()));
    });
  });
}
