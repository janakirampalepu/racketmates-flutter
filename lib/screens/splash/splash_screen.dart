import 'package:flutter/material.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/splash/splash_test_ids.dart';

/// Placeholder startup screen. Startup gates (root check, downtime, forced
/// update, session restore) are implemented in the startup milestone.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
