import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/teams/teams_repository.dart';

/// The signed-in user's active teams.
final myTeamsProvider = FutureProvider.autoDispose<List<Team>>(
  (ref) => ref
      .watch(teamsRepositoryProvider)
      .myTeams(userIds: ref.watch(selectedUserIdsProvider)),
);

/// Teams the user captains that play [sport] (null = any sport).
final captainTeamsProvider = FutureProvider.autoDispose
    .family<List<Team>, String?>(
      (ref, sport) => ref
          .watch(teamsRepositoryProvider)
          .captainTeams(
            userIds: ref.watch(selectedUserIdsProvider),
            sportKey: sport,
          ),
    );

final teamDetailsProvider = FutureProvider.autoDispose.family<Team, int>(
  (ref, id) => ref.watch(teamsRepositoryProvider).details(id),
);

final teamMembersProvider = FutureProvider.autoDispose
    .family<List<TeamPlayer>, int>(
      (ref, id) => ref.watch(teamsRepositoryProvider).members(id),
    );

/// Teams to play against: (sport, the user's team to leave out, search text).
final opponentTeamsProvider = FutureProvider.autoDispose
    .family<List<Team>, ({String? sport, int exclude, String query})>(
      (ref, args) => ref
          .watch(teamsRepositoryProvider)
          .opponentTeams(
            excludeTeamId: args.exclude,
            sportKey: args.sport,
            query: args.query,
          ),
    );
