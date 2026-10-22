import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/users/user_profile_provider.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';

/// Signed-in landing. PLACEHOLDER: the real home (bottom navigation: Home,
/// Schedule, Chat, Teams) is a later milestone. Sign-out is exposed so the
/// session flow can be exercised end to end.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Profile fetch after sign-in / session restore; home still renders if it fails.
    final name = ref.watch(userProfileProvider).value?.firstName;
    return Scaffold(
      body: TestId(
        HomeTestIds.root,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (name != null && name.isNotEmpty)
                    ? l10n.homeGreeting(name)
                    : l10n.homePlaceholder,
              ),
              const SizedBox(height: 16),
              TestId(
                HomeTestIds.signOutButton,
                child: FilledButton(
                  onPressed: () =>
                      ref.read(sessionControllerProvider.notifier).signOut(),
                  child: Text(l10n.signOutAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
