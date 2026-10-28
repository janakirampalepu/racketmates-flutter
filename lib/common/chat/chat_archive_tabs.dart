import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/l10n/app_localizations.dart';

/// Active/Archived switch (native `displayActiveChatList`/
/// `displayArchiveChatList`), shown once there's at least one archived
/// channel — the host screen only builds this once that's confirmed true
/// (see `ChatUi.hasArchivedChannels`). Shared by the global Chat tab and the
/// team-scoped chat tab, since native shows the same toggle in both.
class ChatArchiveTabs extends ConsumerWidget {
  const ChatArchiveTabs({
    required this.archived,
    required this.onChanged,
    required this.activeTabId,
    required this.archivedTabId,
    super.key,
  });

  final bool archived;
  final ValueChanged<bool> onChanged;
  final String activeTabId;
  final String archivedTabId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;

    Widget tab(String id, String label, bool value) {
      final selected = archived == value;
      return Expanded(
        child: TestId(
          id,
          child: InkWell(
            onTap: () => onChanged(value),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? n.imagePrimeryColor : n.ndotsColor,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? n.imagePrimeryColor : n.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab(
          activeTabId,
          ref.msg(MessageKeys.chatActiveListTabTitle, l10n.chatActiveTab),
          false,
        ),
        tab(
          archivedTabId,
          ref.msg(MessageKeys.chatArchivedListTabTitle, l10n.chatArchivedTab),
          true,
        ),
      ],
    );
  }
}
