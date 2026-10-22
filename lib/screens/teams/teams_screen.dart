import 'package:flutter/material.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/l10n/app_localizations.dart';

/// PLACEHOLDER tab: teams are milestone 6.
class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  static const testId = 'teams_screen';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTeams)),
      body: TestId(testId, child: Center(child: Text(l10n.comingSoonMessage))),
    );
  }
}
