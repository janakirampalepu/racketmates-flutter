import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/chat/chat_repository.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final results = ref.watch(newChatSearchProvider(_query));
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: TestId(
          NewChatTestIds.title,
          child: Semantics(header: true, child: Text(l10n.chatNewTitle)),
        ),
      ),
      body: TestId(
        NewChatTestIds.root,
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TestId(
                    NewChatTestIds.search,
                    child: TextField(
                      controller: _search,
                      onChanged: _onChanged,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        labelText: l10n.chatNewSearchHint,
                        border: const OutlineInputBorder(),
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
                              onPressed: () =>
                                  ref.invalidate(newChatSearchProvider(_query)),
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
                              child: Text(l10n.chatNewEmpty),
                            ),
                          )
                        : ListView.builder(
                            itemCount: players.length,
                            itemBuilder: (context, i) {
                              final p = players[i];
                              return TestId(
                                NewChatTestIds.player(p.id ?? i),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.person),
                                  ),
                                  title: Text(_name(p)),
                                  onTap: _starting ? null : () => _start(p),
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
    );
  }
}
