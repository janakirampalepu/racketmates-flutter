import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/auth/models/app_metadata.dart';
import 'package:racketmates/common/content/content_api.dart';
import 'package:racketmates/common/content/content_cache.dart';
import 'package:racketmates/common/content/content_controller.dart';
import 'package:racketmates/common/content/content_repository.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/content/reference_data.dart';
import 'package:racketmates/common/errors/app_failure.dart';

import '../../support/fakes.dart';

const _messages = {
  'home_page': {'upcoming_events_title': 'Coming up', 'blank': '  '},
  'global': {
    'buttons': {'next': 'Continue →'},
  },
  'events': {'count': 5},
};

final _reference = [
  {
    'id': 3,
    'data_type': 'event_type',
    'key': 'et_casual',
    'localized_label': 'Casual game',
  },
  {
    'id': 1,
    'data_type': 'event_type',
    'key': 'et_practice_drill',
    'localized_label': 'Practice drill',
    'localized_sub_text': 'Work on skills',
  },
  {
    'id': 2,
    'data_type': 'attendance_deadline_unit_type',
    'key': 'adut_hour',
    'localized_label': 'hours',
  },
];

ProviderContainer _container(
  FakeContentRepository repo,
  InMemoryContentCache cache,
) {
  final c = ProviderContainer(
    overrides: contentOverrides(repository: repo, cache: cache),
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Messages', () {
    const m = Messages(_messages);

    test('reads nested strings by dot path', () {
      expect(m.lookup('home_page.upcoming_events_title'), 'Coming up');
      expect(m.lookup('global.buttons.next'), 'Continue →');
    });

    test('missing, blank and non-string values fall back', () {
      expect(m.lookup('nope.nothing'), isNull);
      expect(m.lookup('home_page.blank'), isNull);
      expect(m.lookup('events.count'), isNull);
      expect(m.lookup('home_page'), isNull);
      expect(m.text('home_page.missing', 'Fallback'), 'Fallback');
      expect(Messages.empty.text('a.b', 'Local'), 'Local');
    });

    test('format replaces placeholders in server text or fallback', () {
      const f = Messages({
        'a': {'b': 'Hi {name}, {n} new'},
      });
      expect(f.format('a.b', 'x', {'name': 'Sam', 'n': '3'}), 'Hi Sam, 3 new');
      expect(f.format('a.c', 'Hello {name}', {'name': 'Sam'}), 'Hello Sam');
    });
  });

  group('ReferenceData', () {
    final data = ReferenceData.fromResponse(
      ReferenceDataResponse.fromJson({
        'reference_data': [..._reference, null],
      }),
    );

    test('labels and sub texts by key', () {
      expect(data.label('et_casual'), 'Casual game');
      expect(data.subText('et_practice_drill'), 'Work on skills');
      expect(data.label('unknown'), isNull);
      expect(data.label(null), isNull);
    });

    test('lists per data type; event types ordered by id', () {
      expect(data.ofType(ReferenceTypes.eventType).map((i) => i.key), [
        'et_practice_drill',
        'et_casual',
      ]);
      expect(
        data.ofType(ReferenceTypes.attendanceDeadlineUnitType),
        hasLength(1),
      );
      expect(data.ofType('nothing'), isEmpty);
    });

    test('round-trips through the cache JSON', () {
      final again = ReferenceData.fromResponse(
        ReferenceDataResponse.fromJson({'reference_data': data.toJsonList()}),
      );
      expect(again.label('et_casual'), 'Casual game');
    });
  });

  group('ContentController', () {
    test(
      'first run with nothing cached fetches everything and caches it',
      () async {
        final repo = FakeContentRepository(
          messagesTree: _messages,
          preLoginTree: {
            'introduction': {'product_title': 'Welcome!'},
          },
          reference: _reference,
        );
        final cache = InMemoryContentCache();
        final c = _container(repo, cache);
        await c.read(contentControllerProvider.notifier).loadCache();
        expect(c.read(messagesProvider).isEmpty, isTrue); // nothing cached yet

        await c
            .read(contentControllerProvider.notifier)
            .onMetadata(
              const AppMetadata(
                resourceStringsLatestVersion: 5,
                referenceDataLastUpdated: 9,
              ),
            );
        expect(
          c.read(messagesProvider).lookup('home_page.upcoming_events_title'),
          'Coming up',
        );
        expect(
          c.read(preLoginMessagesProvider).lookup('introduction.product_title'),
          'Welcome!',
        );
        expect(c.read(referenceDataProvider).label('et_casual'), 'Casual game');
        expect(cache.snapshot.messagesVersion, 5);
        expect(cache.snapshot.referenceVersion, 9);
      },
    );

    test('a new app session starts from the cache, then skips fetching when versions match', () async {
      final cache = InMemoryContentCache()
        ..snapshot = ContentSnapshot(
          messages: Map<String, dynamic>.from(_messages),
          preLoginMessages: {'a': 'b'},
          referenceData: _reference,
          messagesVersion: 5,
          referenceVersion: 9,
          language: WidgetsLanguage.current,
        );
      final repo = FakeContentRepository();
      final c = _container(repo, cache);
      final controller = c.read(contentControllerProvider.notifier);
      await controller.loadCache();
      expect(
        c.read(messagesProvider).lookup('global.buttons.next'),
        'Continue →',
      );
      expect(c.read(referenceDataProvider).label('et_casual'), 'Casual game');

      await controller.onMetadata(
        const AppMetadata(
          resourceStringsLatestVersion: 5,
          referenceDataLastUpdated: 9,
        ),
      );
      expect(repo.messagesCalls + repo.preLoginCalls + repo.referenceCalls, 0);
    });

    test('a changed version refetches only that part', () async {
      final cache = InMemoryContentCache()
        ..snapshot = ContentSnapshot(
          messages: Map<String, dynamic>.from(_messages),
          preLoginMessages: {'a': 'b'},
          referenceData: _reference,
          messagesVersion: 5,
          referenceVersion: 9,
          language: WidgetsLanguage.current,
        );
      final repo = FakeContentRepository(
        messagesTree: {'x': 'y'},
        reference: _reference,
      );
      final c = _container(repo, cache);
      final controller = c.read(contentControllerProvider.notifier);
      await controller.loadCache();
      await controller.onMetadata(
        const AppMetadata(
          resourceStringsLatestVersion: 6,
          referenceDataLastUpdated: 9,
        ),
      );
      expect(repo.messagesCalls, 1);
      expect(
        repo.preLoginCalls,
        1,
      ); // pre-login copy refreshes with the strings
      expect(repo.referenceCalls, 0);
      expect(cache.snapshot.messagesVersion, 6);
    });

    test('a different device language refetches everything', () async {
      final cache = InMemoryContentCache()
        ..snapshot = ContentSnapshot(
          messages: Map<String, dynamic>.from(_messages),
          preLoginMessages: {'a': 'b'},
          referenceData: _reference,
          messagesVersion: 5,
          referenceVersion: 9,
          language: 'xx-YY',
        );
      final repo = FakeContentRepository(reference: _reference);
      final c = _container(repo, cache);
      await c
          .read(contentControllerProvider.notifier)
          .onMetadata(
            const AppMetadata(
              resourceStringsLatestVersion: 5,
              referenceDataLastUpdated: 9,
            ),
          );
      expect(
        [repo.messagesCalls, repo.preLoginCalls, repo.referenceCalls],
        [1, 1, 1],
      );
    });

    test('offline: cached copies stay; failures never throw; metadata null only fills gaps', () async {
      final cache = InMemoryContentCache()
        ..snapshot = ContentSnapshot(
          messages: Map<String, dynamic>.from(_messages),
          preLoginMessages: {'a': 'b'},
          referenceData: _reference,
          language: WidgetsLanguage.current,
        );
      final repo = FakeContentRepository(failing: true);
      final c = _container(repo, cache);
      final controller = c.read(contentControllerProvider.notifier);
      await controller.loadCache();
      await controller.onMetadata(null);
      expect(
        repo.messagesCalls + repo.preLoginCalls + repo.referenceCalls,
        0,
      ); // nothing missing

      await controller.refresh(); // forced, but the network is down
      expect(
        c.read(messagesProvider).lookup('global.buttons.next'),
        'Continue →',
      );
    });
  });

  group('ContentRepositoryImpl', () {
    test(
      'sends the OAuth client in the query and returns the raw tree',
      () async {
        final adapter = _CaptureAdapter({
          'resources/messages': _messages,
          'resources/pre_login_messages': {
            'signup': {'title': 'Join'},
          },
          'reference_data': {'reference_data': _reference},
        });
        final repo = ContentRepositoryImpl(
          api: ContentApi(
            Dio(BaseOptions(baseUrl: 'https://api.example.test'))
              ..httpClientAdapter = adapter,
          ),
          clientId: 'cid',
          clientSecret: 'secret',
        );
        expect((await repo.messages())['home_page'], isNotNull);
        expect((await repo.preLoginMessages())['signup'], {'title': 'Join'});
        expect((await repo.referenceData()).referenceData, hasLength(3));
        for (final r in adapter.requests) {
          expect(r.uri.queryParameters['client_id'], 'cid');
          expect(r.uri.queryParameters['client_secret'], 'secret');
        }
      },
    );

    test('network errors become AppFailures', () async {
      final repo = ContentRepositoryImpl(
        api: ContentApi(
          Dio(BaseOptions(baseUrl: 'https://api.example.test'))
            ..httpClientAdapter = _CaptureAdapter({}, status: 503),
        ),
        clientId: 'a',
        clientSecret: 'b',
      );
      await expectLater(repo.messages(), throwsA(isA<ServerFailure>()));
    });
  });
}

/// Language tag the controller compares against (test binding default).
abstract final class WidgetsLanguage {
  static String get current => TestWidgetsFlutterBinding.ensureInitialized()
      .platformDispatcher
      .locale
      .toLanguageTag();
}

class _CaptureAdapter implements HttpClientAdapter {
  _CaptureAdapter(this.bodies, {this.status = 200});

  final Map<String, Object> bodies;
  final int status;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(bodies[options.path] ?? <String, dynamic>{}),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
