import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/config/environment_config.dart';

/// Validated runtime configuration; overridden in `bootstrap()`.
final environmentConfigProvider = Provider<EnvironmentConfig>(
  (ref) => throw UnimplementedError('Override in bootstrap()'),
);

/// App version name sent as the `app-version` header and `app_version` query;
/// overridden in `bootstrap()` from the platform package info.
final appVersionProvider = Provider<String>(
  (ref) => throw UnimplementedError('Override in bootstrap()'),
);
