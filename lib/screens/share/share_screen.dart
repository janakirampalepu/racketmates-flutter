import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/share/share_service.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/profile/profile_test_ids.dart';

/// Invite friends (native `ShareWithFriendsFragment`): share the app link
/// through the system share sheet, or copy it.
class ShareScreen extends ConsumerWidget {
  const ShareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final title = ref.msg(MessageKeys.shareTitle, l10n.shareTitle);
    final text = ref.msg(MessageKeys.shareText, l10n.shareText);
    final message = ref.msg(MessageKeys.shareMessage, l10n.shareMessage);
    final copied = ref.msg(MessageKeys.shareCopied, l10n.shareCopied);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: TestId(
          ShareTestIds.title,
          child: Semantics(header: true, child: Text(l10n.settingsShare)),
        ),
      ),
      body: TestId(
        ShareTestIds.root,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.group_add_outlined, size: 72),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            TestId(
              ShareTestIds.share,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.ios_share),
                label: Text(ref.msg(MessageKeys.shareAction, l10n.shareAction)),
                onPressed: () => ref
                    .read(shareServiceProvider)
                    .shareText('$message $appDownloadUrl'),
              ),
            ),
            const SizedBox(height: 12),
            TestId(
              ShareTestIds.copy,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.copy),
                label: Text(ref.msg(MessageKeys.shareCopy, l10n.shareCopy)),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(
                    const ClipboardData(text: appDownloadUrl),
                  );
                  messenger.showSnackBar(SnackBar(content: Text(copied)));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
