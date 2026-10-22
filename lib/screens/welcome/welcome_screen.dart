import 'package:flutter/material.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/welcome/welcome_test_ids.dart';

/// Signed-out landing. PLACEHOLDER: the real welcome/onboarding, sign-up and
/// OTP sign-in screens are the next milestone.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: TestId(
        WelcomeTestIds.root,
        child: Center(child: Text(l10n.welcomePlaceholder)),
      ),
    );
  }
}
