import 'package:flutter/material.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/sign_up/sign_up_test_ids.dart';

/// PLACEHOLDER for the sign-up details flow (name/email, role selection,
/// sports, kids, profile picture, congratulations): the next milestone step.
/// [resume] = the account exists and sign-up was left unfinished.
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({required this.resume, super.key});

  final bool resume;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: TestId(
        SignUpTestIds.root,
        child: Center(child: Text(l10n.signUpPlaceholder)),
      ),
    );
  }
}
