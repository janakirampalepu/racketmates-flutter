import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/chat/chat_repository.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/chat_new/new_chat_test_ids.dart';

/// Players matching a search, never the user themself.
final newChatSearchProvider = FutureProvider.autoDispose
    .family<List<AppUser>, String>((ref, query) {
      final session = ref.read(sessionControllerProvider);
      final userId = session is SignedIn ? session.token.user?.id : null;
      return ref
          .read(chatRepositoryProvider)
          .searchPlayers(query, excludeUserId: userId ?? 0);
    });

/// Start a one-to-one chat (native `Create1on1ChannelPicker`): search a player,
/// tap them, and the conversation opens (the room is created on first use).
class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _starting = false;
  bool _failed = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  Future<void> _start(AppUser player) async {
    final session = ref.read(sessionControllerProvider);
    final ownUid = session is SignedIn ? session.token.user?.uid : null;
    final otherUid = player.uid;
    if (_starting || ownUid == null || otherUid == null) return;
    setState(() {
      _starting = true;
      _failed = false;
    });
    try {
      final url = await ref
          .read(chatRepositoryProvider)
          .directChatRoom(ownUid: ownUid, otherUid: otherUid);
      if (!mounted) return;
      context.pushReplacement(AppRoutes.chatChannelFor(url));
    } on AppFailure {
      if (mounted) {
        setState(() {
          _starting = false;
          _failed = true;
        });
      }
    }
  }

  String _name(AppUser u) =>
      [u.firstName, u.lastName].whereType<String>().join(' ').trim();

  /// Native `User.getInitials()` / `RacketmatesUserInitialsView`: first
  /// letter of the first name plus the first letter of the last name.
  String _initials(AppUser u) {
    final first = (u.firstName ?? '').trim();
    final last = (u.lastName ?? '').trim();
    final initials =
        '${first.isNotEmpty ? first[0] : ''}'
        '${last.isNotEmpty ? last[0] : ''}';
    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final results = ref.watch(newChatSearchProvider(_query));
    return Scaffold(
      backgroundColor: n.backgroundSolidPrimary,
      body: SafeArea(
        child: TestId(
          NewChatTestIds.root,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Native (`AddParticipantViewController` + `PlayerListView`):
                  // a large bold title on the left and a plain "X" close
                  // button on the right — not a back-arrow AppBar.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TestId(
                            NewChatTestIds.title,
                            child: Semantics(
                              header: true,
                              child: Text(
                                ref.msg(
                                  MessageKeys.chatNew1To1ChatTitle,
                                  l10n.chatNewTitle,
                                ),
                                style: TextStyle(
                                  color: n.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        TestId(
                          NewChatTestIds.close,
                          child: IconButton(
                            onPressed: () => context.pop(),
                            tooltip: l10n.closeAction,
                            icon: Icon(Icons.close, color: n.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: TestId(
                      NewChatTestIds.search,
                      child: TextField(
                        controller: _search,
                        onChanged: _onChanged,
                        textInputAction: TextInputAction.search,
                        style: TextStyle(color: n.textPrimary),
                        decoration: InputDecoration(
                          isDense: true,
                          prefixIcon: Icon(
                            Icons.search,
                            color: n.textSecondary,
                            size: 20,
                          ),
                          hintText: ref.msg(
                            MessageKeys.globalHintSearchByNameOrPhone,
                            l10n.chatNewSearchHint,
                          ),
                          hintStyle: TextStyle(color: n.textSecondary),
                          filled: true,
                          fillColor: n.backgroundSolidPrimary,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: n.borderSolidPrimary),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: n.borderSolidPrimary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: n.imagePrimeryColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_failed)
                    TestId(
                      NewChatTestIds.failed,
                      child: Semantics(
                        liveRegion: true,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            l10n.chatNewCreateFailed,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: results.when(
                      loading: () => Center(
                        child: TestId(
                          NewChatTestIds.loading,
                          child: Semantics(
                            label: l10n.chatConnecting,
                            child: const CircularProgressIndicator(),
                          ),
                        ),
                      ),
                      error: (_, _) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TestId(
                              NewChatTestIds.error,
                              child: Text(l10n.chatNewError),
                            ),
                            TestId(
                              NewChatTestIds.retry,
                              child: TextButton(
                                onPressed: () => ref.invalidate(
                                  newChatSearchProvider(_query),
                                ),
                                child: Text(l10n.retryAction),
                              ),
                            ),
                          ],
                        ),
                      ),
                      data: (players) => players.isEmpty
                          ? Center(
                              child: TestId(
                                NewChatTestIds.empty,
                                child: Text(
                                  ref.msg(
                                    MessageKeys.chatNoPersonsError,
                                    l10n.chatNewEmpty,
                                  ),
                                  style: TextStyle(color: n.textSecondary),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              itemCount: players.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final p = players[i];
                                final name = _name(p);
                                final avatarUrl =
                                    p.avatarFileAttachmentUrl ??
                                    p.thumbnailAttachmentUrl;
                                return TestId(
                                  NewChatTestIds.player(p.id ?? i),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: _starting ? null : () => _start(p),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: n.borderSolidPrimary,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor: n.avatarBgColor,
                                            backgroundImage:
                                                avatarUrl != null &&
                                                    avatarUrl.isNotEmpty
                                                ? NetworkImage(avatarUrl)
                                                : null,
                                            child:
                                                avatarUrl == null ||
                                                    avatarUrl.isEmpty
                                                ? Text(
                                                    _initials(p),
                                                    style: TextStyle(
                                                      color:
                                                          n.imagePrimeryColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: n.textPrimary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          // Native's `eye_image` button
                                          // (`ic_player_info` on Android):
                                          // opens a profile preview rather
                                          // than acting differently from the
                                          // row itself — kept as the same
                                          // "start chat" action here, a
                                          // deliberate simplification.
                                          IconButton(
                                            onPressed: _starting
                                                ? null
                                                : () => _start(p),
                                            tooltip: l10n.chatNewViewProfile,
                                            icon: Icon(
                                              Icons.visibility_outlined,
                                              color: n.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
              if (_starting)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black26,
                    child: Center(
                      child: TestId(
                        NewChatTestIds.starting,
                        child: Semantics(
                          label: l10n.chatNewStarting,
                          child: const CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
