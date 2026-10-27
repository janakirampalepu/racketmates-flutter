import 'package:json_annotation/json_annotation.dart';
import 'package:racketmates/common/users/models/app_user.dart';

part 'home_models.g.dart';

/// Player-card type of the home "latest updates" section.
const playerCardEventResultUpdate = 'pct_player_event_result_update';

/// `GET current_session/pending_actions`.
@JsonSerializable(fieldRename: FieldRename.snake)
class PendingActionsResponse {
  const PendingActionsResponse({this.pendingActions});

  factory PendingActionsResponse.fromJson(Map<String, dynamic> json) =>
      _$PendingActionsResponseFromJson(json);

  final List<PendingAction>? pendingActions;

  Map<String, dynamic> toJson() => _$PendingActionsResponseToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class PendingAction {
  const PendingAction({
    this.eventDate,
    this.eventId,
    this.eventParticipantUser,
    this.eventType,
    this.primarySwipeAction,
    this.sportType,
  });

  factory PendingAction.fromJson(Map<String, dynamic> json) =>
      _$PendingActionFromJson(json);

  final String? eventDate;
  final int? eventId;
  final AppUser? eventParticipantUser;
  final String? eventType;

  /// The card's primary action (native iOS `EventViewAction`, e.g.
  /// `user_action_submit_scores`, `user_action_confirm_scores`,
  /// `event_view_action_accept`, `event_view_action_join_waitlist`); `null`/
  /// unrecognized values show the card with no action button.
  final String? primarySwipeAction;
  final String? sportType;

  Map<String, dynamic> toJson() => _$PendingActionToJson(this);
}

/// `GET current_session/stats_summary`.
@JsonSerializable(fieldRename: FieldRename.snake)
class StatsSummaryResponse {
  const StatsSummaryResponse({this.homePageStats});

  factory StatsSummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$StatsSummaryResponseFromJson(json);

  final List<HomePageStats>? homePageStats;

  Map<String, dynamic> toJson() => _$StatsSummaryResponseToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class HomePageStats {
  const HomePageStats({
    this.user,
    this.gamesHours,
    this.lessonHours,
    this.losses,
    this.wins,
    this.meetingHours,
    this.totalHours,
    this.practiceHours,
    this.totalEvents,
    this.year,
    this.weeklyAverageValue,
  });

  factory HomePageStats.fromJson(Map<String, dynamic> json) =>
      _$HomePageStatsFromJson(json);

  final AppUser? user;
  final int? gamesHours;
  final int? lessonHours;
  final int? losses;
  final int? wins;
  final int? meetingHours;
  final int? totalHours;
  final int? practiceHours;
  final int? totalEvents;
  final int? year;
  final String? weeklyAverageValue;

  Map<String, dynamic> toJson() => _$HomePageStatsToJson(this);
}

/// `GET current_session/player_cards`.
@JsonSerializable(fieldRename: FieldRename.snake)
class PlayerCardsResponse {
  const PlayerCardsResponse({this.playerCards});

  factory PlayerCardsResponse.fromJson(Map<String, dynamic> json) =>
      _$PlayerCardsResponseFromJson(json);

  final List<PlayerCard>? playerCards;

  Map<String, dynamic> toJson() => _$PlayerCardsResponseToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class PlayerCard {
  const PlayerCard({
    this.id,
    this.message,
    this.title,
    this.eventId,
    this.teamId,
    this.playOutcome,
    this.createdAt,
    this.sportType,
    this.users,
    this.playerCardType,
  });

  factory PlayerCard.fromJson(Map<String, dynamic> json) =>
      _$PlayerCardFromJson(json);

  final int? id;
  final String? message;
  final String? title;
  final int? eventId;
  final int? teamId;
  final String? playOutcome;
  final String? createdAt;
  final String? sportType;
  final List<AppUser>? users;
  final PlayerCardType? playerCardType;

  Map<String, dynamic> toJson() => _$PlayerCardToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class PlayerCardType {
  const PlayerCardType({this.id, this.cardType, this.indicateSeen});

  factory PlayerCardType.fromJson(Map<String, dynamic> json) =>
      _$PlayerCardTypeFromJson(json);

  final int? id;
  final String? cardType;

  /// Native `indicate_seen`: the card shows an unseen marker when true.
  final bool? indicateSeen;

  Map<String, dynamic> toJson() => _$PlayerCardTypeToJson(this);
}
