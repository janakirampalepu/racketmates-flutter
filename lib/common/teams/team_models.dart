import 'package:json_annotation/json_annotation.dart';
import 'package:racketmates/common/users/models/app_user.dart';

part 'team_models.g.dart';

/// Team types (native `ReferenceDataConstants`).
abstract final class TeamTypes {
  static const casual = 'tt_casual';
  static const competitive = 'tt_competitive';
}

@JsonSerializable(fieldRename: FieldRename.snake)
class TeamSport {
  const TeamSport({this.id, this.sportType});

  factory TeamSport.fromJson(Map<String, dynamic> json) =>
      _$TeamSportFromJson(json);

  final int? id;
  final String? sportType;

  Map<String, dynamic> toJson() => _$TeamSportToJson(this);
}

/// A member of a team and the roles held there.
@JsonSerializable(fieldRename: FieldRename.snake)
class TeamPlayer {
  const TeamPlayer({
    this.id,
    this.userId,
    this.status,
    this.isCaptain,
    this.isCoach,
    this.isPlayer,
    this.user,
  });

  factory TeamPlayer.fromJson(Map<String, dynamic> json) =>
      _$TeamPlayerFromJson(json);

  final int? id;
  final int? userId;
  final String? status;
  final bool? isCaptain;
  final bool? isCoach;
  final bool? isPlayer;
  final AppUser? user;

  Map<String, dynamic> toJson() => _$TeamPlayerToJson(this);
}

/// Subset of the backend team the screens use. Unknown keys are ignored.
@JsonSerializable(fieldRename: FieldRename.snake)
class Team {
  const Team({
    this.id,
    this.name,
    this.teamType,
    this.archived,
    this.captainName,
    this.teamPlayersCount,
    this.memberCount,
    this.leagueName,
    this.teamSports,
    this.enablePlayerRanking,
    this.scheduleEventsCount,
    this.futureEventsCount,
    this.teamPlayers,
  });

  factory Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);

  final int? id;
  final String? name;
  final String? teamType;
  final bool? archived;
  final String? captainName;
  final int? teamPlayersCount;
  final int? memberCount;
  final String? leagueName;
  final List<TeamSport>? teamSports;
  final bool? enablePlayerRanking;
  final int? scheduleEventsCount;
  final int? futureEventsCount;
  final List<TeamPlayer>? teamPlayers;

  Map<String, dynamic> toJson() => _$TeamToJson(this);

  /// Members shown on the list: the count the server sends.
  int? get members => memberCount ?? teamPlayersCount;

  List<String> get sportKeys => [
    for (final s in teamSports ?? const <TeamSport>[])
      if (s.sportType != null) s.sportType!,
  ];
}

@JsonSerializable(fieldRename: FieldRename.snake)
class TeamsMeta {
  const TeamsMeta({this.total, this.archivedCount});

  factory TeamsMeta.fromJson(Map<String, dynamic> json) =>
      _$TeamsMetaFromJson(json);

  final int? total;
  final int? archivedCount;

  Map<String, dynamic> toJson() => _$TeamsMetaToJson(this);
}

/// `GET teams`.
@JsonSerializable(fieldRename: FieldRename.snake)
class TeamsListResponse {
  const TeamsListResponse({this.teams, this.meta});

  factory TeamsListResponse.fromJson(Map<String, dynamic> json) =>
      _$TeamsListResponseFromJson(json);

  final List<Team?>? teams;
  final TeamsMeta? meta;

  Map<String, dynamic> toJson() => _$TeamsListResponseToJson(this);
}

/// `GET teams/{id}` and `POST teams`.
@JsonSerializable(fieldRename: FieldRename.snake)
class TeamResponse {
  const TeamResponse({this.team, this.isCaptain, this.isCoach, this.isPlayer});

  factory TeamResponse.fromJson(Map<String, dynamic> json) =>
      _$TeamResponseFromJson(json);

  final Team? team;
  final bool? isCaptain;
  final bool? isCoach;
  final bool? isPlayer;

  Map<String, dynamic> toJson() => _$TeamResponseToJson(this);
}

/// `GET teams/{id}/team_players`.
@JsonSerializable(fieldRename: FieldRename.snake)
class TeamMembersResponse {
  const TeamMembersResponse({this.teamPlayers});

  factory TeamMembersResponse.fromJson(Map<String, dynamic> json) =>
      _$TeamMembersResponseFromJson(json);

  final List<TeamPlayer?>? teamPlayers;

  Map<String, dynamic> toJson() => _$TeamMembersResponseToJson(this);
}
