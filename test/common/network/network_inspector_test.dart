import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/network/network_inspector.dart';

// `_enabled` is set once and never reset by production code (there is only
// ever one `bootstrap()` call per process); these tests reset it via a
// second import-independent trick is unnecessary because each test file runs
// in its own process, so order within this file is what matters.

void main() {
  test('disabled by default: attaching does not touch the Dio instance', () {
    expect(networkInspectorEnabled, isFalse);
    final dio = Dio();
    attachNetworkInspector(dio);
    expect(dio.interceptors.whereType<ChuckerDioInterceptor>(), isEmpty);
  });

  test('enabling is idempotent and also allows release-mode builds', () {
    ChuckerFlutter.showOnRelease = false;
    enableNetworkInspector();
    expect(networkInspectorEnabled, isTrue);
    expect(ChuckerFlutter.showOnRelease, isTrue);
    enableNetworkInspector(); // second call is a no-op, not an error
    expect(networkInspectorEnabled, isTrue);
  });

  test('once enabled, attaching adds exactly one interceptor', () {
    enableNetworkInspector();
    final dio = Dio();
    attachNetworkInspector(dio);
    expect(dio.interceptors.whereType<ChuckerDioInterceptor>(), hasLength(1));
  });
}
