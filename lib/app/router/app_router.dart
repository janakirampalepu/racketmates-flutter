import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/screens/splash/splash_screen.dart';

abstract final class AppRoutes {
  static const splash = '/';
}

/// Central route table. Auth/startup redirects (root check, downtime, forced
/// update, session restore) and notification/universal-link routes are added
/// here as those milestones land.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
    ],
  );
});
