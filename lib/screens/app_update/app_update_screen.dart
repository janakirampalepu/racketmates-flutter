import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/startup/pending_upgrade.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/app_update/app_update_test_ids.dart';
import 'package:racketmates/screens/app_update/store_launcher.dart';
import 'package:racketmates/screens/splash/repositories/startup_repository.dart';

/// Forced (`mandatory`) or optional upgrade prompt. A mandatory upgrade has no
/// way out (the router keeps the user here); an optional one can be dismissed
/// and is not shown again for the same `new_version_number`.
class AppUpdateScreen extends ConsumerWidget {
  const AppUpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final upgrade = ref.watch(pendingUpgradeProvider);
    final mandatory = upgrade?.isMandatory ?? false;
    return PopScope(
      canPop: !mandatory,
      child: Scaffold(
        body: TestId(
          AppUpdateTestIds.root,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.appUpdateTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  if ((upgrade?.notes ?? '').isNotEmpty)
                    TestId(
                      AppUpdateTestIds.notes,
                      child: Text(upgrade!.notes!, textAlign: TextAlign.center),
                    ),
                  const SizedBox(height: 24),
                  TestId(
                    AppUpdateTestIds.updateButton,
                    child: FilledButton(
                      onPressed: () =>
                          ref.read(storeLauncherProvider).openStorePage(),
                      child: Text(l10n.appUpdateAction),
                    ),
                  ),
                  if (!mandatory)
                    TestId(
                      AppUpdateTestIds.laterButton,
                      child: TextButton(
                        onPressed: () => _later(context, ref),
                        child: Text(l10n.appUpdateLaterAction),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _later(BuildContext context, WidgetRef ref) async {
    final version = ref.read(pendingUpgradeProvider)?.newVersionNumber;
    if (version != null) {
      await ref.read(startupRepositoryProvider).setLastPromptedVersion(version);
    }
    ref.read(pendingUpgradeProvider.notifier).set(null);
    if (!context.mounted) return;
    context.go(
      ref.read(sessionControllerProvider) is SignedIn
          ? AppRoutes.home
          : AppRoutes.welcome,
    );
  }
}
