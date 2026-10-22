import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/splash/splash_test_ids.dart';
import 'package:racketmates/screens/splash/splash_view_model.dart';
import 'package:racketmates/screens/splash/usecases/decide_startup_destination.dart';

/// Startup screen: runs the cold-start sequence and forwards to the result.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(splashViewModelProvider, (_, next) {
      next.whenData((destination) {
        context.go(switch (destination) {
          StartupDestination.appUpdate => AppRoutes.appUpdate,
          StartupDestination.home => AppRoutes.home,
          StartupDestination.welcome => AppRoutes.welcome,
        });
      });
    });
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: TestId(
        SplashTestIds.root,
        child: Center(
          child: TestId(
            SplashTestIds.progress,
            child: Semantics(
              label: l10n.loadingLabel,
              child: const CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );
  }
}
