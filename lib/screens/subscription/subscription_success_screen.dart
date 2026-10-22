import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/subscription/subscription_test_ids.dart';

/// Shown once a purchase is linked (native `SubscriptionSuccessActivity`).
class SubscriptionSuccessScreen extends StatelessWidget {
  const SubscriptionSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: TestId(
          SubscriptionTestIds.successRoot,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, size: 72),
                const SizedBox(height: 16),
                Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(
                    l10n.subscriptionSuccessTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Text(l10n.subscriptionSuccessText, textAlign: TextAlign.center),
                const SizedBox(height: 32),
                TestId(
                  SubscriptionTestIds.successContinue,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => context.go(AppRoutes.home),
                    child: Text(l10n.subscriptionSuccessContinue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
