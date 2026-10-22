// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_match_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchCourt _$MatchCourtFromJson(Map<String, dynamic> json) => MatchCourt(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
);

Map<String, dynamic> _$MatchCourtToJson(MatchCourt instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

EventScore _$EventScoreFromJson(Map<String, dynamic> json) => EventScore(
  id: (json['id'] as num?)?.toInt(),
  eventMatchSideId: (json['event_match_side_id'] as num?)?.toInt(),
  set: json['set'] as String?,
  score: json['score'] as String?,
  playOutcome: json['play_outcome'] as String?,
  setTieBreaker: json['set_tie_breaker'] as bool?,
  matchTieBreaker: json['match_tie_breaker'] as bool?,
);

Map<String, dynamic> _$EventScoreToJson(EventScore instance) =>
    <String, dynamic>{
      'id': instance.id,
      'event_match_side_id': instance.eventMatchSideId,
      'set': instance.set,
      'score': instance.score,
      'play_outcome': instance.playOutcome,
      'set_tie_breaker': instance.setTieBreaker,
      'match_tie_breaker': instance.matchTieBreaker,
    };

MatchPlayer _$MatchPlayerFromJson(Map<String, dynamic> json) => MatchPlayer(
  id: (json['id'] as num?)?.toInt(),
  userId: (json['user_id'] as num?)?.toInt(),
  position: json['position'] as String?,
  user: json['user'] == null
      ? null
      : AppUser.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MatchPlayerToJson(MatchPlayer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'position': instance.position,
      'user': instance.user,
    };

EventMatchSide _$EventMatchSideFromJson(Map<String, dynamic> json) =>
    EventMatchSide(
      id: (json['id'] as num?)?.toInt(),
      teamId: (json['team_id'] as num?)?.toInt(),
      teamName: json['team_name'] as String?,
      side: json['side'] as String?,
      playOutcome: json['play_outcome'] as String?,
      eventParticipants: (json['event_participants'] as List<dynamic>?)
          ?.map((e) => MatchPlayer.fromJson(e as Map<String, dynamic>))
          .toList(),
      eventScores: (json['event_scores'] as List<dynamic>?)
          ?.map((e) => EventScore.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$EventMatchSideToJson(EventMatchSide instance) =>
    <String, dynamic>{
      'id': instance.id,
      'team_id': instance.teamId,
      'team_name': instance.teamName,
      'side': instance.side,
      'play_outcome': instance.playOutcome,
      'event_participants': instance.eventParticipants,
      'event_scores': instance.eventScores,
    };

EventMatch _$EventMatchFromJson(Map<String, dynamic> json) => EventMatch(
  id: (json['id'] as num?)?.toInt(),
  matchType: json['match_type'] as String?,
  status: json['status'] as String?,
  order: (json['order'] as num?)?.toInt(),
  placeCourt: json['place_court'] == null
      ? null
      : MatchCourt.fromJson(json['place_court'] as Map<String, dynamic>),
  eventMatchSides: (json['event_match_sides'] as List<dynamic>?)
      ?.map((e) => EventMatchSide.fromJson(e as Map<String, dynamic>))
      .toList(),
  scoringFormat: json['scoring_format'] as String?,
  decidingSetType: json['deciding_set_type'] as String?,
  minimumScoreToWin: (json['minimum_score_to_win'] as num?)?.toInt(),
  unfinished: json['unfinished'] as bool?,
);

Map<String, dynamic> _$EventMatchToJson(EventMatch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'match_type': instance.matchType,
      'status': instance.status,
      'order': instance.order,
      'place_court': instance.placeCourt,
      'event_match_sides': instance.eventMatchSides,
      'scoring_format': instance.scoringFormat,
      'deciding_set_type': instance.decidingSetType,
      'minimum_score_to_win': instance.minimumScoreToWin,
      'unfinished': instance.unfinished,
    };
