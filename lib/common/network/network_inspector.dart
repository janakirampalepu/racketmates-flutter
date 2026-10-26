import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:dio/dio.dart';

/// Whether the in-app network inspector (native `Chucker`, shipped there for
/// every non-production build) is enabled for this run. Only set from
/// `app/bootstrap.dart` for a non-production environment.
bool _enabled = false;

bool get networkInspectorEnabled => _enabled;

/// Called once from `bootstrap()` for every non-production environment.
void enableNetworkInspector() {
  if (_enabled) return;
  _enabled = true;
  // Lets it run in an actual release build of a non-production environment
  // too (Chucker defaults to debug-only otherwise), the same as native's own
  // non-production Chucker builds.
  ChuckerFlutter.showOnRelease = true;
}

/// Adds [dio] to the inspector, when one is enabled.
///
/// `chucker_flutter` has no header/body redaction of its own, so this relies
/// entirely on interceptor order: the caller (`_baseDio` in
/// `common/auth/auth_providers.dart`) attaches this right after the header
/// interceptor in `createDio` and *before* `AuthInterceptor` adds the bearer
/// token — native's own rule (`common/network`) is that tokens are never
/// logged, and ordering is how that's kept true here.
void attachNetworkInspector(Dio dio) {
  if (!_enabled) return;
  dio.interceptors.add(ChuckerDioInterceptor());
}
