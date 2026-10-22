import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/startup/pending_upgrade.dart';
import 'package:racketmates/screens/app_update/app_update_screen.dart';
import 'package:racketmates/screens/home/home_screen.dart';
import 'package:racketmates/screens/splash/splash_screen.dart';
import 'package:racketmates/screens/welcome/welcome_screen.dart';

/// Pure redirect rules (unit-testable). Order matters:
/// 1. mandatory upgrade locks everything to the update screen;
/// 2. while the session is being restored only the splash may show;
/// 3. signed-out users cannot open protected routes; signed-in users skip welcome.
String? computeRedirect({
  required String location,
  required SessionState session,
  required bool mandatoryUpgrade,
}) {
  if (mandatoryUpgrade) {
    return location == AppRoutes.appUpdate ? null : AppRoutes.appUpdate;
  }
  if (session is SessionRestoring) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }
  if (session is SignedOut && AppRoutes.protected.contains(location)) {
    return AppRoutes.welcome;
  }
  if (session is SignedIn && location == AppRoutes.welcome) {
    return AppRoutes.home;
  }
  return null;
}

class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// Central route table. Notification and universal-link routes are added here
/// by their milestones; unknown locations fall back to the splash, which
/// resolves to home (signed in) or welcome (signed out).
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref
    ..listen(sessionControllerProvider, (_, _) => refresh.ping())
    ..listen(pendingUpgradeProvider, (_, _) => refresh.ping())
    ..onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => computeRedirect(
      location: state.uri.path,
      session: ref.read(sessionControllerProvider),
      mandatoryUpgrade: ref.read(pendingUpgradeProvider)?.isMandatory ?? false,
    ),
    errorBuilder: (context, state) => const SplashScreen(),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.appUpdate,
        builder: (context, state) => const AppUpdateScreen(),
      ),
    ],
  );
});
