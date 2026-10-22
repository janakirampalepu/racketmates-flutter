import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/welcome/welcome_test_ids.dart';

/// Signed-out landing (native AppLanding + OnboardOptions). The marketing
/// carousel and animated landing are not migrated yet; copy is the ARB
/// fallback until the server-driven Messages provider exists.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: TestId(
        WelcomeTestIds.root,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TestId(
                  WelcomeTestIds.title,
                  child: Text(
                    ref.preMsg(MessageKeys.preProductTitle, l10n.welcomeTitle),
                    style: text.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                TestId(
                  WelcomeTestIds.subtitle,
                  child: Text(
                    ref.preMsg(
                      MessageKeys.preProductSubText,
                      l10n.welcomeSubtitle,
                    ),
                    style: text.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                TestId(
                  WelcomeTestIds.signInButton,
                  child: FilledButton(
                    onPressed: () =>
                        context.push(AppRoutes.phoneEntryFor('signIn')),
                    child: Text(l10n.signInAction),
                  ),
                ),
                const SizedBox(height: 12),
                TestId(
                  WelcomeTestIds.signUpButton,
                  child: OutlinedButton(
                    onPressed: () =>
                        context.push(AppRoutes.phoneEntryFor('signUp')),
                    child: Text(
                      ref.preMsg(
                        MessageKeys.preSignUpButton,
                        l10n.signUpAction,
                      ),
                    ),
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
