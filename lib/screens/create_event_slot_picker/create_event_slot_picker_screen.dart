import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/match_draft.dart';
import 'package:racketmates/common/create_event/people_kind.dart';
import 'package:racketmates/common/create_event/people_search.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/create_event_slot_picker/create_event_slot_picker_test_ids.dart';

/// Search and choose the player for one spot of one match; choosing closes the
/// picker. A player already standing elsewhere in the match moves here.
class CreateEventSlotPickerScreen extends ConsumerWidget {
  const CreateEventSlotPickerScreen({
    required this.match,
    required this.slot,
    super.key,
  });

  final int match;
  final MatchSlot slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = peopleSearchViewModelProvider(PeopleKind.players);
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    final draft = ref.watch(createEventFlowProvider);
    final current = draft != null && match < draft.matches.length
        ? draft.matches[match].players[slot]
        : null;

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
                CreateEventSlotPickerTestIds.retry,
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
            CreateEventSlotPickerTestIds.empty,
            child: Text(l10n.createPlayersEmpty),
          ),
        );
      }
      return ListView.builder(
        itemCount: state.results.length,
        itemBuilder: (context, index) {
          final user = state.results[index];
          return TestId(
            CreateEventSlotPickerTestIds.person(user.id ?? index),
            child: ListTile(
              title: Text(user.displayName),
              selected: user.id == current?.id,
              trailing: user.id == current?.id ? const Icon(Icons.check) : null,
              onTap: () {
                ref
                    .read(createEventFlowProvider.notifier)
                    .assignPlayer(match, slot, user);
                context.pop();
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
        CreateEventSlotPickerTestIds.root,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TestId(
                    CreateEventSlotPickerTestIds.title,
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.createSlotPickerTitle,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TestId(
                  CreateEventSlotPickerTestIds.search,
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
              Expanded(child: results()),
            ],
          ),
        ),
      ),
    );
  }
}
