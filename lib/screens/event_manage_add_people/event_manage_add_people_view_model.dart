import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/create_event/create_event_repository.dart';
import 'package:racketmates/common/create_event/people_search.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/teams/teams_repository.dart';
import 'package:racketmates/screens/event_details/event_details_view_model.dart';

typedef AddPeopleKey = ({int eventId, bool coaches});

/// Finds people to add to an event: members of the team for a team event,
/// otherwise everyone with the right role who plays the sport (native
/// `getListOfEventPlayers`), minus the people already in the event.
class AddPeopleSearchViewModel extends Notifier<PeopleSearchState> {
  AddPeopleSearchViewModel(this.args);

  final AddPeopleKey args;
  Timer? _debounce;
  int _token = 0;

  @override
  PeopleSearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    // Watching the event loads it (a deep link opens this screen cold) and
    // restarts the search once it is there.
    final event = ref.watch(
      eventDetailsViewModelProvider(args.eventId).select((s) => s.event),
    );
    if (event.hasError) {
      return PeopleSearchState(loading: false, failure: const UnknownFailure());
    }
    if (event.hasValue) Future.microtask(search);
    return const PeopleSearchState();
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();
    _debounce = Timer(playerSearchDebounce, search);
  }

  Future<void> search() async {
    final event = ref
        .read(eventDetailsViewModelProvider(args.eventId))
        .event
        .value;
    if (event == null) return;
    final token = ++_token;
    state = state.copyWith(loading: true, failure: () => null);
    final meetup = event.eventType == 'et_casual_meeting';
    final role = args.coaches ? 'ur_coach' : (meetup ? null : 'ur_player');
    final sport = meetup ? null : event.sportType;
    final teamId = event.isTeamEvent ? event.originatorId : null;
    try {
      final found = teamId != null
          ? [
              for (final m
                  in await ref
                      .read(teamsRepositoryProvider)
                      .members(
                        teamId,
                        query: state.query,
                        role: role,
                        sportKey: sport,
                      ))
                ?m.user,
            ]
          : await ref
                .read(createEventRepositoryProvider)
                .searchUsers(query: state.query, role: role, sportKey: sport);
      final inEvent = {
        for (final p in event.eventParticipants ?? const []) p.userId,
      };
      if (!ref.mounted || token != _token) return;
      state = state.copyWith(
        results: [
          for (final u in found)
            if (!inEvent.contains(u.id)) u,
        ],
        loading: false,
      );
    } on AppFailure catch (failure) {
      if (!ref.mounted || token != _token) return;
      state = state.copyWith(loading: false, failure: () => failure);
    }
  }
}

final addPeopleSearchProvider = NotifierProvider.autoDispose
    .family<AddPeopleSearchViewModel, PeopleSearchState, AddPeopleKey>(
      AddPeopleSearchViewModel.new,
    );
