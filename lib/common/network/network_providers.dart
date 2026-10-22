import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// HTTP adapter for the Racketmates API Dio. Overridden in `bootstrap()` with
/// the TLS-pinned adapter for pinned environments; an unpinned default (system
/// trust store) is used for dev/local and tests.
final apiHttpClientAdapterProvider = Provider<HttpClientAdapter>(
  (ref) => HttpClientAdapter(),
);
