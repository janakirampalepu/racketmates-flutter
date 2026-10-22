import 'package:racketmates/app/config/app_environment.dart';

class ConfigurationException implements Exception {
  ConfigurationException(this.problems);

  final List<String> problems;

  @override
  String toString() => 'Invalid app configuration: ${problems.join('; ')}';
}

/// Typed, validated runtime configuration. Kept separate from brand
/// configuration. Values arrive through `--dart-define-from-file=env/<env>.json`
/// (never committed). Anything bundled in the app is NOT confidential.
class EnvironmentConfig {
  const EnvironmentConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.apiVersion,
    required this.oauthClientId,
    required this.oauthClientSecret,
    this.sendbirdAppId = '',
  });

  /// Reads compile-time defines. Call [validate] before use.
  factory EnvironmentConfig.fromDefines(AppEnvironment environment) {
    const baseUrl = String.fromEnvironment('API_BASE_URL');
    return EnvironmentConfig(
      environment: environment,
      apiBaseUrl: baseUrl.isNotEmpty
          ? baseUrl
          : (environment.defaultApiBaseUrl ?? ''),
      // Value of the `Accept` header (API versioning), per-environment.
      apiVersion: const String.fromEnvironment('API_VERSION'),
      oauthClientId: const String.fromEnvironment('OAUTH_CLIENT_ID'),
      oauthClientSecret: const String.fromEnvironment('OAUTH_CLIENT_SECRET'),
      sendbirdAppId: const String.fromEnvironment('SENDBIRD_APP_ID'),
    );
  }

  final AppEnvironment environment;
  final String apiBaseUrl;
  final String apiVersion;
  final String oauthClientId;
  final String oauthClientSecret;
  final String sendbirdAppId;

  /// Returns the list of problems; empty when the configuration is usable.
  List<String> problems() {
    final result = <String>[];
    final uri = Uri.tryParse(apiBaseUrl);
    if (apiBaseUrl.isEmpty ||
        uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty) {
      result.add('API_BASE_URL is missing or not an absolute URL');
    } else if (environment == AppEnvironment.production &&
        uri.scheme != 'https') {
      result.add('production API_BASE_URL must use https');
    }
    if (apiVersion.isEmpty) result.add('API_VERSION is missing');
    if (oauthClientId.isEmpty) result.add('OAUTH_CLIENT_ID is missing');
    if (oauthClientSecret.isEmpty) result.add('OAUTH_CLIENT_SECRET is missing');
    return result;
  }

  /// Throws [ConfigurationException] when the configuration is unusable.
  void validate() {
    final found = problems();
    if (found.isNotEmpty) throw ConfigurationException(found);
  }
}
