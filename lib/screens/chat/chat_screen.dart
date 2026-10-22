import 'package:flutter/material.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/l10n/app_localizations.dart';

/// PLACEHOLDER tab: chat (Sendbird) is milestone 8.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  static const testId = 'chat_screen';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navChat)),
      body: TestId(testId, child: Center(child: Text(l10n.comingSoonMessage))),
    );
  }
}
