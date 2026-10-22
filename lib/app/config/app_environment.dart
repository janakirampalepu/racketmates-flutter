/// Deployment environments. Mirrors the native build types / xcconfigs.
///
/// iOS has an extra `Feature1` configuration whose bundle ID is the
/// `.staging` one; it maps to [staging] here until product decides otherwise.
enum AppEnvironment {
  production(
    'production',
    'Racketmates',
    defaultApiBaseUrl: 'https://api.racketmatesapp.com',
    sslPinning: true,
  ),
  hotfix(
    'hotfix',
    'RM (Hotfix)',
    defaultApiBaseUrl: 'https://api-hotfix.racketmatesapp.com',
    sslPinning: true,
  ),
  qa(
    'qa',
    'RM (QA)',
    defaultApiBaseUrl: 'https://api-qa.racketmatesapp.com',
    sslPinning: true,
  ),
  regression(
    'regression',
    'RM (Regression)',
    defaultApiBaseUrl: 'https://api-regression.racketmatesapp.com',
    sslPinning: true,
  ),
  // Staging/dev hosts are not verified from the native repos: they must be
  // supplied through --dart-define-from-file (API_BASE_URL). The native
  // Feature1 host (api-feature1) serves the same Sectigo chain, so staging is
  // pinned; if the staging host moves to another CA, update the pin set first.
  staging('staging', 'RM (Staging)', sslPinning: true),
  dev('dev', 'RM (Dev)'),
  local('local', 'RM (Local)', defaultApiBaseUrl: 'http://localhost:3000');

  const AppEnvironment(
    this.id,
    this.displayName, {
    this.defaultApiBaseUrl,
    this.sslPinning = false,
  });

  final String id;
  final String displayName;
  final String? defaultApiBaseUrl;

  /// Whether API traffic is pinned to the CA public keys in `ssl_pinning.dart`.
  /// Hosted environments are pinned; dev (host unverified) and local
  /// (plain http) are not. Never pin by leaf certificate: leaf renewals would
  /// then require an app release.
  final bool sslPinning;
}
