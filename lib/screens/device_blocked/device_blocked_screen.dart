import 'package:flutter/material.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/device_blocked/device_blocked_test_ids.dart';

/// Shown instead of the app on a rooted or jailbroken device (native
/// `RootedActivity`). There is no way past it: the router keeps the user here.
class DeviceBlockedScreen extends StatelessWidget {
  const DeviceBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: TestId(
          DeviceBlockedTestIds.root,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.gpp_maybe_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      TestId(
                        DeviceBlockedTestIds.title,
                        child: Semantics(
                          header: true,
                          child: Text(
                            l10n.deviceBlockedTitle,
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TestId(
                        DeviceBlockedTestIds.message,
                        child: Text(l10n.deviceBlockedMessage),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
