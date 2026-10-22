import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/app/config/app_environment.dart';
import 'package:racketmates/app/config/environment_config.dart';

EnvironmentConfig _config({
  AppEnvironment environment = AppEnvironment.qa,
  String apiBaseUrl = 'https://api-qa.example.test',
  String apiVersion = 'application/vnd.test',
  String clientId = 'id',
  String clientSecret = 'secret',
}) => EnvironmentConfig(
  environment: environment,
  apiBaseUrl: apiBaseUrl,
  apiVersion: apiVersion,
  oauthClientId: clientId,
  oauthClientSecret: clientSecret,
);

void main() {
  group('EnvironmentConfig', () {
    test('valid configuration has no problems', () {
      expect(_config().problems(), isEmpty);
      expect(() => _config().validate(), returnsNormally);
    });

    test('reports every missing value', () {
      final problems = _config(
        apiBaseUrl: '',
        apiVersion: '',
        clientId: '',
        clientSecret: '',
      ).problems();
      expect(problems, hasLength(4));
    });

    test('production requires https', () {
      final problems = _config(
        environment: AppEnvironment.production,
        apiBaseUrl: 'http://api.example.test',
      ).problems();
      expect(problems, contains('production API_BASE_URL must use https'));
    });

    test('validate throws ConfigurationException', () {
      expect(
        () => _config(apiVersion: '').validate(),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('dev and local are the only unpinned environments', () {
      final unpinned = AppEnvironment.values.where((e) => !e.sslPinning);
      expect(unpinned, [AppEnvironment.dev, AppEnvironment.local]);
    });
  });
}
