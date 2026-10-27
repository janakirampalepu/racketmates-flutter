// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeamSport _$TeamSportFromJson(Map<String, dynamic> json) => TeamSport(
  id: (json['id'] as num?)?.toInt(),
  sportType: json['sport_type'] as String?,
);

Map<String, dynamic> _$TeamSportToJson(TeamSport instance) => <String, dynamic>{
  'id': instance.id,
  'sport_type': instance.sportType,
};

TeamPlayer _$TeamPlayerFromJson(Map<String, dynamic> json) => TeamPlayer(
  id: (json['id'] as num?)?.toInt(),
  userId: (json['user_id'] as num?)?.toInt(),
  status: json['status'] as String?,
  isCaptain: json['is_captain'] as bool?,
  isCoach: json['is_coach'] as bool?,
  isPlayer: json['is_player'] as bool?,
  user: json['user'] == null
      ? null
      : AppUser.fromJson(json['user'] as Map<String, dynamic>),
  inactivatedAt: json['inactivated_at'] as String?,
  currentRank: (json['current_rank'] as num?)?.toInt(),
  previousRank: (json['previous_rank'] as num?)?.toInt(),
  wins: (json['wins'] as num?)?.toInt(),
  losses: (json['losses'] as num?)?.toInt(),
  totalPoints: (json['total_points'] as num?)?.toInt(),
);

Map<String, dynamic> _$TeamPlayerToJson(TeamPlayer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'status': instance.status,
      'is_captain': instance.isCaptain,
      'is_coach': instance.isCoach,
      'is_player': instance.isPlayer,
      'user': instance.user,
      'inactivated_at': instance.inactivatedAt,
      'current_rank': instance.currentRank,
      'previous_rank': instance.previousRank,
      'wins': instance.wins,
      'losses': instance.losses,
      'total_points': instance.totalPoints,
    };

Team _$TeamFromJson(Map<String, dynamic> json) => Team(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  teamType: json['team_type'] as String?,
  archived: json['archived'] as bool?,
  captainName: json['captain_name'] as String?,
  teamPlayersCount: (json['team_players_count'] as num?)?.toInt(),
  memberCount: (json['member_count'] as num?)?.toInt(),
  leagueName: json['league_name'] as String?,
  teamSports: (json['team_sports'] as List<dynamic>?)
      ?.map((e) => TeamSport.fromJson(e as Map<String, dynamic>))
      .toList(),
  enablePlayerRanking: json['enable_player_ranking'] as bool?,
  scheduleEventsCount: (json['schedule_events_count'] as num?)?.toInt(),
  futureEventsCount: (json['future_events_count'] as num?)?.toInt(),
  teamPlayers: (json['team_players'] as List<dynamic>?)
      ?.map((e) => TeamPlayer.fromJson(e as Map<String, dynamic>))
      .toList(),
  userPermissions: (json['user_permissions'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, AccessInfo.fromJson(e as Map<String, dynamic>)),
  ),
  chatRoomTypesForFiltering:
      (json['chat_room_types_for_filtering'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
);

Map<String, dynamic> _$TeamToJson(Team instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'team_type': instance.teamType,
  'archived': instance.archived,
  'captain_name': instance.captainName,
  'team_players_count': instance.teamPlayersCount,
  'member_count': instance.memberCount,
  'league_name': instance.leagueName,
  'team_sports': instance.teamSports,
  'enable_player_ranking': instance.enablePlayerRanking,
  'schedule_events_count': instance.scheduleEventsCount,
  'future_events_count': instance.futureEventsCount,
  'team_players': instance.teamPlayers,
  'chat_room_types_for_filtering': instance.chatRoomTypesForFiltering,
  'user_permissions': instance.userPermissions,
};

TeamsMeta _$TeamsMetaFromJson(Map<String, dynamic> json) => TeamsMeta(
  total: (json['total'] as num?)?.toInt(),
  archivedCount: (json['archived_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$TeamsMetaToJson(TeamsMeta instance) => <String, dynamic>{
  'total': instance.total,
  'archived_count': instance.archivedCount,
};

TeamsListResponse _$TeamsListResponseFromJson(Map<String, dynamic> json) =>
    TeamsListResponse(
      teams: (json['teams'] as List<dynamic>?)
          ?.map(
            (e) => e == null ? null : Team.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      meta: json['meta'] == null
          ? null
          : TeamsMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TeamsListResponseToJson(TeamsListResponse instance) =>
    <String, dynamic>{'teams': instance.teams, 'meta': instance.meta};

TeamResponse _$TeamResponseFromJson(Map<String, dynamic> json) => TeamResponse(
  team: json['team'] == null
      ? null
      : Team.fromJson(json['team'] as Map<String, dynamic>),
  isCaptain: json['is_captain'] as bool?,
  isCoach: json['is_coach'] as bool?,
  isPlayer: json['is_player'] as bool?,
);

Map<String, dynamic> _$TeamResponseToJson(TeamResponse instance) =>
    <String, dynamic>{
      'team': instance.team,
      'is_captain': instance.isCaptain,
      'is_coach': instance.isCoach,
      'is_player': instance.isPlayer,
    };

TeamMembersResponse _$TeamMembersResponseFromJson(Map<String, dynamic> json) =>
    TeamMembersResponse(
      teamPlayers: (json['team_players'] as List<dynamic>?)
          ?.map(
            (e) => e == null
                ? null
                : TeamPlayer.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$TeamMembersResponseToJson(
  TeamMembersResponse instance,
) => <String, dynamic>{'team_players': instance.teamPlayers};
