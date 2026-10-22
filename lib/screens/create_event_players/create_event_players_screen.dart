import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/create_event_players/create_event_players_test_ids.dart';
import 'package:racketmates/screens/create_event_players/create_event_players_view_model.dart';

/// Pick the invited players (at least one).
class CreateEventPlayersScreen extends ConsumerStatefulWidget {
  const CreateEventPlayersScreen({super.key});

  @override
  ConsumerState<CreateEventPlayersScreen> createState() =>
      _CreateEventPlayersScreenState();
}

class _CreateEventPlayersScreenState
    extends ConsumerState<CreateEventPlayersScreen> {
  bool _showError = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(createEventFlowProvider);
    final invitees = draft?.invitees ?? const <AppUser>[];
    final state = ref.watch(createEventPlayersViewModelProvider);
    final vm = ref.read(createEventPlayersViewModelProvider.notifier);
    final flow = ref.read(createEventFlowProvider.notifier);

    Widget results() {
      if (state.loading && state.results.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (state.failure != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.createPlayersLoadError),
              TestId(
                CreateEventPlayersTestIds.retry,
                child: TextButton(
                  onPressed: vm.search,
                  child: Text(l10n.retryAction),
                ),
              ),
            ],
          ),
        );
      }
      if (state.isEmpty) {
        return Center(
          child: TestId(
            CreateEventPlayersTestIds.empty,
            child: Text(l10n.createPlayersEmpty),
          ),
        );
      }
      return ListView.builder(
        itemCount: state.results.length,
        itemBuilder: (context, index) {
          final user = state.results[index];
          final selected = invitees.any((u) => u.id == user.id);
          return TestId(
            CreateEventPlayersTestIds.player(user.id ?? index),
            child: CheckboxListTile(
              value: selected,
              title: Text(user.displayName),
              onChanged: (_) {
                flow.toggleInvitee(user);
                setState(() => _showError = false);
              },
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: TestId(
        CreateEventPlayersTestIds.root,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TestId(
                    CreateEventPlayersTestIds.title,
                    child: Semantics(
                      header: true,
                      child: Text(
                        ref.msg(
                          MessageKeys.createPlayersTitle,
                          l10n.createPlayersTitle,
                        ),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TestId(
                  CreateEventPlayersTestIds.search,
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      labelText: l10n.createPlayersSearchHint,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: vm.setQuery,
                  ),
                ),
              ),
              if (invitees.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: TestId(
                    CreateEventPlayersTestIds.selected,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final u in invitees)
                          InputChip(
                            label: Text(u.displayName),
                            onDeleted: () => flow.toggleInvitee(u),
                          ),
                      ],
                    ),
                  ),
                ),
              if (_showError)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: TestId(
                    CreateEventPlayersTestIds.error,
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        l10n.createPlayersRequired,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(child: results()),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: TestId(
                  CreateEventPlayersTestIds.next,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: () {
                      if (invitees.isEmpty) {
                        setState(() => _showError = true);
                        return;
                      }
                      context.push(AppRoutes.createEventWhenWhere);
                    },
                    child: Text(
                      ref.msg(MessageKeys.buttonNext, l10n.nextAction),
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
