import 'package:racketmates/common/session/access.dart';
import 'package:racketmates/common/teams/team_models.dart';

/// Permission keys of what a captain can do with members (native
/// `LatestUserPermissions`).
abstract final class TeamPermissions {
  static const addMembers = 'team.team_players.create';
  static const updateMember = 'team.team_players.update';
  static const deactivateMember = 'team.team_players.inactivate';
  static const reactivateMember = 'team.team_players.reactivate';
  static const removeMember = 'team.team_players.destroy';
}

/// How a member action is offered, from the team's permission for it. An
/// action the team sends no permission for is not offered (the backend
/// decides anyway; this only keeps buttons off screens that cannot use them).
AccessDecision memberAccess(
  Team team,
  String key, {
  required bool subscribed,
}) => team.permission(key) == null
    ? AccessDecision.hidden
    : decideAccess(team.permission(key), subscribed: subscribed);

/// Active captains of [members].
List<TeamPlayer> activeCaptains(List<TeamPlayer> members) => [
  for (final m in members)
    if ((m.isCaptain ?? false) && !m.isInactive) m,
];

/// A team must keep a captain: the only active captain can neither lose the
/// role, be deactivated nor be removed (native `TeamActiveParticipantFragment`).
bool isOnlyCaptain(List<TeamPlayer> members, TeamPlayer member) {
  final captains = activeCaptains(members);
  return captains.length == 1 && captains.single.id == member.id;
}

/// Whether [captain], [coach] and [player] are an allowed set of roles for
/// [member]: at least one role, and the only captain stays captain.
bool rolesAllowed(
  List<TeamPlayer> members,
  TeamPlayer member, {
  required bool captain,
  required bool coach,
  required bool player,
}) {
  if (!captain && !coach && !player) return false;
  if (!captain && isOnlyCaptain(members, member)) return false;
  return true;
}

/// Ranking movement since the previous period: positive = moved up.
int? rankChange(TeamPlayer member) {
  final now = member.currentRank;
  final before = member.previousRank;
  return now == null || before == null ? null : before - now;
}
