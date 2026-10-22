import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/create_event_repository.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/screens/create_event_players/create_event_players_state.dart';

const playerSearchDebounce = Duration(milliseconds: 400);

/// Searches players who play the event's sport (native `getListOfEventPlayers`:
/// `users?search=&roles[]=ur_player&sport_types[]=<sport>`).
class CreateEventPlayersViewModel extends Notifier<CreateEventPlayersState> {
  Timer? _debounce;
  int _token = 0;

  @override
  CreateEventPlayersState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(search);
    return const CreateEventPlayersState();
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();
    _debounce = Timer(playerSearchDebounce, search);
  }

  Future<void> search() async {
    final sport = ref.read(createEventFlowProvider)?.sport;
    if (sport == null) return;
    final token = ++_token;
    state = state.copyWith(loading: true, failure: () => null);
    try {
      final users = await ref
          .read(createEventRepositoryProvider)
          .searchPlayers(query: state.query, sportKey: sport.key);
      if (!ref.mounted || token != _token) return;
      state = state.copyWith(results: users, loading: false);
    } on AppFailure catch (failure) {
      if (!ref.mounted || token != _token) return;
      state = state.copyWith(loading: false, failure: () => failure);
    }
  }
}

final createEventPlayersViewModelProvider =
    NotifierProvider.autoDispose<
      CreateEventPlayersViewModel,
      CreateEventPlayersState
    >(CreateEventPlayersViewModel.new);
