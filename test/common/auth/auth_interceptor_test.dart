import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/auth/auth_interceptor.dart';
import 'package:racketmates/common/auth/token_refresher.dart';
import 'package:racketmates/common/auth/token_store.dart';

import '../../support/fakes.dart';

/// Returns 401 for the old access token and 200 for any other.
class _ServerAdapter implements HttpClientAdapter {
  _ServerAdapter({required this.validToken});

  final String validToken;
  final List<String?> seenAuth = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final auth = options.headers['Authorization'] as String?;
    seenAuth.add(auth);
    final ok = auth == 'Bearer $validToken';
    return ResponseBody.fromString('{}', ok ? 200 : 401);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late InMemoryTokenStore store;
  late int expired;
  final now = DateTime.fromMillisecondsSinceEpoch(5000 * 1000, isUtc: true);

  Dio build(FakeAuthApi api, _ServerAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        store: store,
        refresher: TokenRefresher(api: api, store: store, config: testConfig),
        onSessionExpired: () => expired++,
        now: () => now,
      ),
    );
    return dio;
  }

  setUp(() {
    expired = 0;
    store = InMemoryTokenStore(token(createdAt: 4000)); // valid until 11200
  });

  test('adds the bearer token', () async {
    final adapter = _ServerAdapter(validToken: 'access-1');
    await build(FakeAuthApi(), adapter).get<dynamic>('/x');
    expect(adapter.seenAuth, ['Bearer access-1']);
  });

  test('401 refreshes once and retries with the new token', () async {
    final adapter = _ServerAdapter(validToken: 'access-2');
    final api = FakeAuthApi(tokenResults: [token(access: 'access-2')]);
    final response = await build(api, adapter).get<dynamic>('/x');
    expect(response.statusCode, 200);
    expect(adapter.seenAuth, ['Bearer access-1', 'Bearer access-2']);
    expect(api.tokenCalls, 1);
    expect(expired, 0);
  });

  test('parallel 401s trigger a single refresh', () async {
    final adapter = _ServerAdapter(validToken: 'access-2');
    final api = FakeAuthApi(tokenResults: [token(access: 'access-2')]);
    final dio = build(api, adapter);
    final results = await Future.wait([
      dio.get<dynamic>('/a'),
      dio.get<dynamic>('/b'),
      dio.get<dynamic>('/c'),
    ]);
    expect(results.every((r) => r.statusCode == 200), isTrue);
    expect(api.tokenCalls, 1);
  });

  test(
    'refresh rejected: session expired callback and the 401 surfaces',
    () async {
      final adapter = _ServerAdapter(validToken: 'never');
      final api = FakeAuthApi(tokenResults: [httpError(400)]);
      await expectLater(
        build(api, adapter).get<dynamic>('/x'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            401,
          ),
        ),
      );
      expect(expired, 1);
    },
  );

  test('a retried request that fails again is not retried forever', () async {
    final adapter = _ServerAdapter(validToken: 'never');
    final api = FakeAuthApi(tokenResults: [token(access: 'access-2')]);
    await expectLater(
      build(api, adapter).get<dynamic>('/x'),
      throwsA(isA<DioException>()),
    );
    expect(api.tokenCalls, 1);
    expect(adapter.seenAuth, hasLength(2));
  });

  test('transient refresh failure surfaces the 401 without logout', () async {
    final adapter = _ServerAdapter(validToken: 'never');
    final api = FakeAuthApi(tokenResults: [connectionError()]);
    await expectLater(
      build(api, adapter).get<dynamic>('/x'),
      throwsA(isA<DioException>()),
    );
    expect(expired, 0);
  });

  test('expired token is refreshed before the request is sent', () async {
    // created_at + expires_in = 1100, before "now" (5000)
    store = InMemoryTokenStore(token(createdAt: 1000, expiresIn: 100));
    final adapter = _ServerAdapter(validToken: 'access-2');
    final api = FakeAuthApi(tokenResults: [token(access: 'access-2')]);
    await build(api, adapter).get<dynamic>('/x');
    expect(adapter.seenAuth, ['Bearer access-2']);
  });
}
