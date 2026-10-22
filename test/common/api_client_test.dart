import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/app/config/app_environment.dart';
import 'package:racketmates/app/config/environment_config.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/network/api_client.dart';

class _CaptureAdapter implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const config = EnvironmentConfig(
    environment: AppEnvironment.qa,
    apiBaseUrl: 'https://api-qa.example.test',
    apiVersion: 'application/vnd.test',
    oauthClientId: 'id',
    oauthClientSecret: 'secret',
  );

  test('adds the native header contract (Authorization comes from AuthInterceptor)', () async {
    final adapter = _CaptureAdapter();
    final dio = createDio(
      config,
      appVersion: '1.2.3',
      acceptLanguage: () => 'en-US',
    )..httpClientAdapter = adapter;

    await dio.get<dynamic>('/current_session/session_info');

    final headers = adapter.last!.headers;
    expect(headers['Accept'], 'application/vnd.test');
    expect(headers['app-version'], '1.2.3');
    expect(headers['Accept-Language'], 'en-US');
    expect(headers.containsKey('Authorization'), isFalse);
  });

  group('mapDioException', () {
    DioException bad(int status, Object? data) => DioException(
      requestOptions: RequestOptions(),
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: RequestOptions(),
        statusCode: status,
        data: data,
      ),
    );

    test('401 maps to UnauthorizedFailure', () {
      expect(mapDioException(bad(401, null)), isA<UnauthorizedFailure>());
    });

    test('reads error_message, message and error keys', () {
      expect(extractServerMessage({'error_message': 'a'}), 'a');
      expect(extractServerMessage({'message': 'b'}), 'b');
      expect(extractServerMessage({'error': 'c'}), 'c');
      expect(extractServerMessage('nope'), isNull);
    });

    test('5xx keeps status code and message', () {
      final failure = mapDioException(bad(503, {'message': 'down'}));
      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 503);
      expect(failure.message, 'down');
    });

    test('timeouts and connection errors', () {
      DioException of(DioExceptionType t) =>
          DioException(requestOptions: RequestOptions(), type: t);
      expect(
        mapDioException(of(DioExceptionType.receiveTimeout)),
        isA<TimeoutFailure>(),
      );
      expect(
        mapDioException(of(DioExceptionType.connectionError)),
        isA<OfflineFailure>(),
      );
    });
  });
}
