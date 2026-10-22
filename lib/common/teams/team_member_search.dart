import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/create_event/create_event_repository.dart';
import 'package:racketmates/common/create_event/people_search.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/teams/create_team_flow.dart';

/// Searches people to invite to the new team (native `InviteTeamMemFragment`:
/// `users?search=&sport_types[]=<team sports>`), any role.
class TeamMemberSearchViewModel extends Notifier<PeopleSearchState> {
  Timer? _debounce;
  int _token = 0;

  @override
  PeopleSearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(search);
    return const PeopleSearchState();
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();
    _debounce = Timer(playerSearchDebounce, search);
  }

  Future<void> search() async {
    final token = ++_token;
    state = state.copyWith(loading: true, failure: () => null);
    try {
      final users = await ref
          .read(createEventRepositoryProvider)
          .searchUsers(
            query: state.query,
            sportKeys: [
              for (final s in ref.read(createTeamFlowProvider).sports) s.key,
            ],
          );
      if (!ref.mounted || token != _token) return;
      state = state.copyWith(results: users, loading: false);
    } on AppFailure catch (failure) {
      if (!ref.mounted || token != _token) return;
      state = state.copyWith(loading: false, failure: () => failure);
    }
  }
}

final teamMemberSearchProvider =
    NotifierProvider.autoDispose<TeamMemberSearchViewModel, PeopleSearchState>(
      TeamMemberSearchViewModel.new,
    );
