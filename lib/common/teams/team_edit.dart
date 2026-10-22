import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/teams/create_team_flow.dart';
import 'package:racketmates/common/teams/team_models.dart';

/// Permission keys of the team settings (native `LatestUserPermissions`).
abstract final class TeamSettingsPermissions {
  static const settings = 'team.settings';
  static const archive = 'team.archive';
  static const unarchive = 'team.unarchive';
  static const destroy = 'team.destroy';
  static const createEvent = 'team.events.create';
}

/// What the settings screen edits.
class TeamEdit {
  const TeamEdit({
    required this.name,
    required this.teamType,
    required this.sports,
    required this.enablePlayerRanking,
  });

  factory TeamEdit.of(Team team) => TeamEdit(
    name: team.name ?? '',
    teamType: team.teamType,
    sports: [for (final key in team.sportKeys) ?SportKey.fromKey(key)],
    enablePlayerRanking: team.enablePlayerRanking ?? false,
  );

  final String name;
  final String? teamType;
  final List<SportKey> sports;
  final bool enablePlayerRanking;

  TeamEdit copyWith({
    String? name,
    String? Function()? teamType,
    List<SportKey>? sports,
    bool? enablePlayerRanking,
  }) => TeamEdit(
    name: name ?? this.name,
    teamType: teamType != null ? teamType() : this.teamType,
    sports: sports ?? this.sports,
    enablePlayerRanking: enablePlayerRanking ?? this.enablePlayerRanking,
  );
}

/// The same rules as creating a team: a name, a type and a sport.
List<TeamDetailsError> validateTeamEdit(TeamEdit edit) => [
  if (edit.name.trim().isEmpty) TeamDetailsError.nameRequired,
  if (edit.teamType == null) TeamDetailsError.typeRequired,
  if (edit.sports.isEmpty) TeamDetailsError.sportRequired,
];

/// Body of `PUT teams/{id}` (native `TeamViewModel.updateTeam`): the sports
/// still ticked keep their id, new ones are added by key, and a sport that
/// was unticked is sent with `_destroy`.
Map<String, dynamic> buildUpdateTeamBody(Team team, TeamEdit edit) {
  if (validateTeamEdit(edit).isNotEmpty) {
    throw StateError('incomplete team');
  }
  final chosen = {for (final s in edit.sports) s.key};
  return {
    'team': {
      'id': team.id,
      'name': edit.name.trim(),
      'team_type': edit.teamType,
      'enable_player_ranking': edit.enablePlayerRanking,
      'team_sports_attributes': [
        for (final existing in team.teamSports ?? const <TeamSport>[])
          if (existing.sportType != null)
            if (chosen.contains(existing.sportType))
              {'id': existing.id, 'sport_type': existing.sportType}
            else
              {
                'id': existing.id,
                'sport_type': existing.sportType,
                '_destroy': true,
              },
        for (final sport in edit.sports)
          if (!(team.teamSports ?? const <TeamSport>[]).any(
            (t) => t.sportType == sport.key,
          ))
            {'sport_type': sport.key},
      ],
    },
  };
}

/// Whether [edit] changes anything about [team].
bool teamEditChanged(Team team, TeamEdit edit) {
  final before = TeamEdit.of(team);
  return before.name.trim() != edit.name.trim() ||
      before.teamType != edit.teamType ||
      before.enablePlayerRanking != edit.enablePlayerRanking ||
      before.sports.toSet().difference(edit.sports.toSet()).isNotEmpty ||
      edit.sports.toSet().difference(before.sports.toSet()).isNotEmpty;
}
