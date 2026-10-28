import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/teams/teams_repository.dart';
import 'package:racketmates/common/users/models/app_user.dart';

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

/// Members of a team, with or without the deactivated ones, optionally
/// filtered by name search and/or sport (native `TeamActiveParticipantFragment`'s
/// search box and sport filter — both already supported by `members()`,
/// just not previously wired into any screen's filter UI).
final teamRosterProvider = FutureProvider.autoDispose
    .family<
      List<TeamPlayer>,
      ({int teamId, bool inactive, String search, String? sportKey})
    >(
      (ref, args) => ref
          .watch(teamsRepositoryProvider)
          .members(
            args.teamId,
            includeInactive: args.inactive,
            query: args.search,
            sportKey: args.sportKey,
          ),
    );

/// The team's ranking table for a sport, period and match type.
final teamRankingsProvider = FutureProvider.autoDispose
    .family<
      List<TeamPlayer>,
      ({int teamId, String sport, String? period, String? matchType})
    >(
      (ref, args) => ref
          .watch(teamsRepositoryProvider)
          .rankings(
            args.teamId,
            sportKey: args.sport,
            period: args.period,
            matchType: args.matchType,
          ),
    );

/// People who could be added to a team: (team, search text).
final teamCandidatesProvider = FutureProvider.autoDispose
    .family<List<AppUser>, ({int teamId, String query})>(
      (ref, args) => ref
          .watch(teamsRepositoryProvider)
          .searchNonMembers(
            args.teamId,
            query: args.query,
            sportKeys:
                ref.watch(teamDetailsProvider(args.teamId)).value?.sportKeys ??
                const [],
          ),
    );
