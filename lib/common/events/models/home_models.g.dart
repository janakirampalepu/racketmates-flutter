// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PendingActionsResponse _$PendingActionsResponseFromJson(
  Map<String, dynamic> json,
) => PendingActionsResponse(
  pendingActions: (json['pending_actions'] as List<dynamic>?)
      ?.map((e) => PendingAction.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PendingActionsResponseToJson(
  PendingActionsResponse instance,
) => <String, dynamic>{'pending_actions': instance.pendingActions};

PendingAction _$PendingActionFromJson(Map<String, dynamic> json) =>
    PendingAction(
      eventDate: json['event_date'] as String?,
      eventId: (json['event_id'] as num?)?.toInt(),
      eventParticipantUser: json['event_participant_user'] == null
          ? null
          : AppUser.fromJson(
              json['event_participant_user'] as Map<String, dynamic>,
            ),
      eventType: json['event_type'] as String?,
      sportType: json['sport_type'] as String?,
    );

Map<String, dynamic> _$PendingActionToJson(PendingAction instance) =>
    <String, dynamic>{
      'event_date': instance.eventDate,
      'event_id': instance.eventId,
      'event_participant_user': instance.eventParticipantUser,
      'event_type': instance.eventType,
      'sport_type': instance.sportType,
    };

StatsSummaryResponse _$StatsSummaryResponseFromJson(
  Map<String, dynamic> json,
) => StatsSummaryResponse(
  homePageStats: (json['home_page_stats'] as List<dynamic>?)
      ?.map((e) => HomePageStats.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$StatsSummaryResponseToJson(
  StatsSummaryResponse instance,
) => <String, dynamic>{'home_page_stats': instance.homePageStats};

HomePageStats _$HomePageStatsFromJson(Map<String, dynamic> json) =>
    HomePageStats(
      user: json['user'] == null
          ? null
          : AppUser.fromJson(json['user'] as Map<String, dynamic>),
      gamesHours: (json['games_hours'] as num?)?.toInt(),
      lessonHours: (json['lesson_hours'] as num?)?.toInt(),
      losses: (json['losses'] as num?)?.toInt(),
      wins: (json['wins'] as num?)?.toInt(),
      meetingHours: (json['meeting_hours'] as num?)?.toInt(),
      totalHours: (json['total_hours'] as num?)?.toInt(),
      practiceHours: (json['practice_hours'] as num?)?.toInt(),
      totalEvents: (json['total_events'] as num?)?.toInt(),
      year: (json['year'] as num?)?.toInt(),
      weeklyAverageValue: json['weekly_average_value'] as String?,
    );

Map<String, dynamic> _$HomePageStatsToJson(HomePageStats instance) =>
    <String, dynamic>{
      'user': instance.user,
      'games_hours': instance.gamesHours,
      'lesson_hours': instance.lessonHours,
      'losses': instance.losses,
      'wins': instance.wins,
      'meeting_hours': instance.meetingHours,
      'total_hours': instance.totalHours,
      'practice_hours': instance.practiceHours,
      'total_events': instance.totalEvents,
      'year': instance.year,
      'weekly_average_value': instance.weeklyAverageValue,
    };

PlayerCardsResponse _$PlayerCardsResponseFromJson(Map<String, dynamic> json) =>
    PlayerCardsResponse(
      playerCards: (json['player_cards'] as List<dynamic>?)
          ?.map((e) => PlayerCard.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PlayerCardsResponseToJson(
  PlayerCardsResponse instance,
) => <String, dynamic>{'player_cards': instance.playerCards};

PlayerCard _$PlayerCardFromJson(Map<String, dynamic> json) => PlayerCard(
  id: (json['id'] as num?)?.toInt(),
  message: json['message'] as String?,
  title: json['title'] as String?,
  eventId: (json['event_id'] as num?)?.toInt(),
  teamId: (json['team_id'] as num?)?.toInt(),
  playOutcome: json['play_outcome'] as String?,
  createdAt: json['created_at'] as String?,
  sportType: json['sport_type'] as String?,
  users: (json['users'] as List<dynamic>?)
      ?.map((e) => AppUser.fromJson(e as Map<String, dynamic>))
      .toList(),
  playerCardType: json['player_card_type'] == null
      ? null
      : PlayerCardType.fromJson(
          json['player_card_type'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$PlayerCardToJson(PlayerCard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'message': instance.message,
      'title': instance.title,
      'event_id': instance.eventId,
      'team_id': instance.teamId,
      'play_outcome': instance.playOutcome,
      'created_at': instance.createdAt,
      'sport_type': instance.sportType,
      'users': instance.users,
      'player_card_type': instance.playerCardType,
    };

PlayerCardType _$PlayerCardTypeFromJson(Map<String, dynamic> json) =>
    PlayerCardType(
      id: (json['id'] as num?)?.toInt(),
      cardType: json['card_type'] as String?,
      indicateSeen: json['indicate_seen'] as bool?,
    );

Map<String, dynamic> _$PlayerCardTypeToJson(PlayerCardType instance) =>
    <String, dynamic>{
      'id': instance.id,
      'card_type': instance.cardType,
      'indicate_seen': instance.indicateSeen,
    };
