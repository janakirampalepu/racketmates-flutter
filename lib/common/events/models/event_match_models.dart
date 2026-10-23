import 'package:json_annotation/json_annotation.dart';
import 'package:racketmates/common/users/models/app_user.dart';

part 'event_match_models.g.dart';

/// A court of a match (`place_court`).
@JsonSerializable(fieldRename: FieldRename.snake)
class MatchCourt {
  const MatchCourt({this.id, this.name});

  factory MatchCourt.fromJson(Map<String, dynamic> json) =>
      _$MatchCourtFromJson(json);

  final int? id;
  final String? name;

  Map<String, dynamic> toJson() => _$MatchCourtToJson(this);
}

/// One side's score of one set (`event_scores`). [set] is "1".."6"; the
/// tie-break flags mark a set tie-break and the deciding match tie-break.
@JsonSerializable(fieldRename: FieldRename.snake)
class EventScore {
  const EventScore({
    this.id,
    this.eventMatchSideId,
    this.set,
    this.score,
    this.playOutcome,
    this.setTieBreaker,
    this.matchTieBreaker,
  });

  factory EventScore.fromJson(Map<String, dynamic> json) =>
      _$EventScoreFromJson(json);

  final int? id;
  final int? eventMatchSideId;
  final String? set;
  final String? score;
  final String? playOutcome;
  final bool? setTieBreaker;
  final bool? matchTieBreaker;

  Map<String, dynamic> toJson() => _$EventScoreToJson(this);

  /// A regular set score (neither kind of tie-break).
  bool get isRegularSet =>
      !(setTieBreaker ?? false) && !(matchTieBreaker ?? false);
}

/// A player standing in a match.
@JsonSerializable(fieldRename: FieldRename.snake)
class MatchPlayer {
  const MatchPlayer({this.id, this.userId, this.position, this.user});

  factory MatchPlayer.fromJson(Map<String, dynamic> json) =>
      _$MatchPlayerFromJson(json);

  final int? id;
  final int? userId;
  final String? position;
  final AppUser? user;

  Map<String, dynamic> toJson() => _$MatchPlayerToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class EventMatchSide {
  const EventMatchSide({
    this.id,
    this.teamId,
    this.teamName,
    this.side,
    this.playOutcome,
    this.eventParticipants,
    this.eventScores,
  });

  factory EventMatchSide.fromJson(Map<String, dynamic> json) =>
      _$EventMatchSideFromJson(json);

  final int? id;
  final int? teamId;
  final String? teamName;

  /// `ecs_top` or `ecs_bottom`.
  final String? side;
  final String? playOutcome;
  final List<MatchPlayer>? eventParticipants;
  final List<EventScore>? eventScores;

  Map<String, dynamic> toJson() => _$EventMatchSideToJson(this);

  bool get isTop => side == 'ecs_top';

  /// "Alex Kim, Pat Lee", or the team name when no player is set yet.
  String get label {
    final names = [
      for (final p in eventParticipants ?? const <MatchPlayer>[])
        if ((p.user?.displayName ?? '').isNotEmpty) p.user!.displayName,
    ];
    return names.isNotEmpty ? names.join(', ') : (teamName ?? '');
  }

  /// Score of the set tie-break of [set], if entered.
  String? tieBreakOfSet(String set) {
    for (final s in eventScores ?? const <EventScore>[]) {
      if ((s.setTieBreaker ?? false) &&
          s.set == set &&
          (s.score ?? '').isNotEmpty) {
        return s.score;
      }
    }
    return null;
  }

  /// Score of the match tie-break, if entered.
  String? get matchTieBreakScore {
    for (final s in eventScores ?? const <EventScore>[]) {
      if ((s.matchTieBreaker ?? false) && (s.score ?? '').isNotEmpty) {
        return s.score;
      }
    }
    return null;
  }

  /// Score of regular [set] ("1", "2", ...), if entered.
  String? scoreOfSet(String set) {
    for (final s in eventScores ?? const <EventScore>[]) {
      if (s.isRegularSet && s.set == set) return s.score;
    }
    return null;
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class EventMatch {
  const EventMatch({
    this.id,
    this.matchType,
    this.status,
    this.order,
    this.placeCourt,
    this.eventMatchSides,
    this.scoringFormat,
    this.decidingSetType,
    this.minimumScoreToWin,
    this.unfinished,
  });

  factory EventMatch.fromJson(Map<String, dynamic> json) =>
      _$EventMatchFromJson(json);

  final int? id;
  final String? matchType;
  final String? status;
  final int? order;
  final MatchCourt? placeCourt;
  final List<EventMatchSide>? eventMatchSides;
  final String? scoringFormat;
  final String? decidingSetType;
  final int? minimumScoreToWin;
  final bool? unfinished;

  Map<String, dynamic> toJson() => _$EventMatchToJson(this);

  EventMatchSide? get top => _side(top: true);
  EventMatchSide? get bottom => _side(top: false);

  EventMatchSide? _side({required bool top}) {
    for (final s in eventMatchSides ?? const <EventMatchSide>[]) {
      if (s.isTop == top) return s;
    }
    return null;
  }
}
