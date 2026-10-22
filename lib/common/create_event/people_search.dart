import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/create_event_repository.dart';
import 'package:racketmates/common/create_event/people_kind.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/users/models/app_user.dart';

class PeopleSearchState {
  const PeopleSearchState({
    this.query = '',
    this.results = const [],
    this.loading = true,
    this.failure,
  });

  final String query;
  final List<AppUser> results;
  final bool loading;
  final AppFailure? failure;

  bool get isEmpty => !loading && failure == null && results.isEmpty;

  PeopleSearchState copyWith({
    String? query,
    List<AppUser>? results,
    bool? loading,
    AppFailure? Function()? failure,
  }) => PeopleSearchState(
    query: query ?? this.query,
    results: results ?? this.results,
    loading: loading ?? this.loading,
    failure: failure != null ? failure() : this.failure,
  );
}

const playerSearchDebounce = Duration(milliseconds: 400);

/// Searches users for a people step (native `getListOfEventPlayers`:
/// `users?search=&roles[]=<role>&sport_types[]=<sport>`), shared by the coach
/// and player/attendee screens.
class PeopleSearchViewModel extends Notifier<PeopleSearchState> {
  PeopleSearchViewModel(this.kind);

  final PeopleKind kind;
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
    final draft = ref.read(createEventFlowProvider);
    if (draft == null) return;
    final token = ++_token;
    state = state.copyWith(loading: true, failure: () => null);
    try {
      final users = await ref
          .read(createEventRepositoryProvider)
          .searchUsers(
            query: state.query,
            role: kind.roleFor(draft),
            sportKey: kind.sportFor(draft),
          );
      if (!ref.mounted || token != _token) return;
      state = state.copyWith(results: users, loading: false);
    } on AppFailure catch (failure) {
      if (!ref.mounted || token != _token) return;
      state = state.copyWith(loading: false, failure: () => failure);
    }
  }
}

final peopleSearchViewModelProvider = NotifierProvider.autoDispose
    .family<PeopleSearchViewModel, PeopleSearchState, PeopleKind>(
      PeopleSearchViewModel.new,
    );
