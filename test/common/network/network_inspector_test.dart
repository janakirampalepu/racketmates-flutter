import 'package:alice_dio/alice_dio_adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/network/network_inspector.dart';

// `_alice` is set once and never reset by production code (there is only
// ever one `bootstrap()` call per process); each test file runs in its own
// process, so order within this file is what matters.

void main() {
  // `Alice`'s constructor touches `GlobalKey.currentState`, which needs a
  // binding; plain `test()` (not `testWidgets()`) does not create one.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('disabled by default: attaching does not touch the Dio instance', () {
    expect(networkInspectorEnabled, isFalse);
    expect(networkInspector, isNull);
    expect(networkInspectorNavigatorKey, isNull);
    final dio = Dio();
    attachNetworkInspector(dio);
    expect(dio.interceptors.whereType<AliceDioAdapter>(), isEmpty);
  });

  test('enabling is idempotent and gives the inspector a navigator key', () {
    enableNetworkInspector();
    expect(networkInspectorEnabled, isTrue);
    final inspector = networkInspector;
    final key = networkInspectorNavigatorKey;
    expect(inspector, isNotNull);
    expect(key, isNotNull);
    enableNetworkInspector(); // second call is a no-op, not an error
    expect(networkInspector, same(inspector));
    expect(networkInspectorNavigatorKey, same(key));
  });

  test('once enabled, attaching adds exactly one interceptor', () {
    enableNetworkInspector();
    final dio = Dio();
    attachNetworkInspector(dio);
    expect(dio.interceptors.whereType<AliceDioAdapter>(), hasLength(1));
  });
}
