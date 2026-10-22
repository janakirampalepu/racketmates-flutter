import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/people_kind.dart';
import 'package:racketmates/common/create_event/people_search.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/l10n/app_localizations.dart';

/// Appium identifiers of one people step (`<prefix>_screen`, `_title`, ...).
class PeopleStepIds {
  const PeopleStepIds(this.prefix);

  final String prefix;

  String get root => '${prefix}_screen';
  String get title => '${prefix}_title';
  String get search => '${prefix}_search';
  String get next => '${prefix}_next_button';
  String get error => '${prefix}_error';
  String get empty => '${prefix}_empty';
  String get retry => '${prefix}_retry';
  String get selected => '${prefix}_selected';

  /// One row per user.
  String person(int id) => '${prefix}_person_$id';
}

/// Search + multi-select of people for the create-event wizard (coaches,
/// players, meetup attendees). At least one must be chosen to continue.
class PeopleStep extends ConsumerStatefulWidget {
  const PeopleStep({
    required this.kind,
    required this.ids,
    required this.title,
    required this.searchHint,
    required this.emptyText,
    required this.requiredError,
    required this.nextLabel,
    required this.onContinue,
    super.key,
  });

  final PeopleKind kind;
  final PeopleStepIds ids;
  final String title;
  final String searchHint;
  final String emptyText;
  final String requiredError;
  final String nextLabel;
  final VoidCallback onContinue;

  @override
  ConsumerState<PeopleStep> createState() => _PeopleStepState();
}

class _PeopleStepState extends ConsumerState<PeopleStep> {
  bool _showError = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ids = widget.ids;
    final draft = ref.watch(createEventFlowProvider);
    final selected = draft == null
        ? const <AppUser>[]
        : widget.kind.selected(draft);
    final provider = peopleSearchViewModelProvider(widget.kind);
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
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
                ids.retry,
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
        return Center(child: TestId(ids.empty, child: Text(widget.emptyText)));
      }
      return ListView.builder(
        itemCount: state.results.length,
        itemBuilder: (context, index) {
          final user = state.results[index];
          return TestId(
            ids.person(user.id ?? index),
            child: CheckboxListTile(
              value: selected.any((u) => u.id == user.id),
              title: Text(user.displayName),
              onChanged: (_) {
                widget.kind.toggle(flow, user);
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
        ids.root,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TestId(
                    ids.title,
                    child: Semantics(
                      header: true,
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TestId(
                  ids.search,
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      labelText: widget.searchHint,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: vm.setQuery,
                  ),
                ),
              ),
              if (selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: TestId(
                    ids.selected,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final u in selected)
                          InputChip(
                            label: Text(u.displayName),
                            onDeleted: () => widget.kind.toggle(flow, u),
                          ),
                      ],
                    ),
                  ),
                ),
              if (_showError)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: TestId(
                    ids.error,
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        widget.requiredError,
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
                  ids.next,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: () {
                      if (selected.isEmpty) {
                        setState(() => _showError = true);
                        return;
                      }
                      widget.onContinue();
                    },
                    child: Text(widget.nextLabel),
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
