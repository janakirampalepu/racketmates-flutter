import 'package:alice/alice.dart';
import 'package:alice_dio/alice_dio_adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

/// Whether the in-app network inspector (native `Chucker`, shipped there for
/// every non-production build) is enabled for this run. Only set from
/// `app/bootstrap.dart` for a non-production environment.
bool get networkInspectorEnabled => _alice != null;

Alice? _alice;

/// The enabled inspector, or `null` outside a non-production environment.
/// Exposed so a floating button can call `showInspector()`/
/// `showOverlayBubble()` without every caller re-deriving it.
Alice? get networkInspector => _alice;

/// Its navigator key, handed to `GoRouter` so the inspector can push its own
/// full-screen call-list page on top of the app.
GlobalKey<NavigatorState>? get networkInspectorNavigatorKey =>
    _alice?.getNavigatorKey();

final _dioAdapter = AliceDioAdapter();

/// Called once from `bootstrap()` for every non-production environment.
void enableNetworkInspector() {
  if (_alice != null) return;
  final alice = Alice(
    configuration: AliceConfiguration(
      // A floating, draggable bubble (native has no such affordance, but a
      // persistent on-screen entry point is more discoverable during QA
      // than a shake gesture, which a running simulator cannot perform).
      showOverlayBubble: true,
      // The shake gesture is what native's own Chucker relied on; the
      // floating bubble replaces it instead of adding a second trigger.
      showInspectorOnShake: false,
      // Belt-and-suspenders: the call site (`_baseDio` in
      // `common/auth/auth_providers.dart`) already attaches this
      // interceptor *before* `AuthInterceptor` adds the bearer token, so
      // the token is never captured in the first place; Alice's own
      // redaction (unlike chucker_flutter, which has none) covers it too
      // in case that ordering ever changes.
      redactedHeaders: const {'authorization'},
    ),
  );
  alice.addAdapter(_dioAdapter);
  _alice = alice;
}

/// Adds [dio] to the inspector, when one is enabled.
void attachNetworkInspector(Dio dio) {
  if (_alice == null) return;
  dio.interceptors.add(_dioAdapter);
}
