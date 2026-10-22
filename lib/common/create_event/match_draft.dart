import 'package:racketmates/common/users/models/app_user.dart';

/// Backend keys of matches and round robins (native `ReferenceDataConstants`
/// / `AppConstants`).
abstract final class MatchKeys {
  static const singles = 'mt_singles';
  static const doubles = 'mt_doubles';
  static const undecided = 'mt_undecided';

  static const gameSingles = 'egt_singles';
  static const gameDoubles = 'egt_doubles';
  static const gameBoth = 'egt_both';

  static const partnersRotating = 'ept_rotating';
  static const partnersFixed = 'ept_fixed';

  static const formatClassic = 'est_classic';
  static const formatKingOfTheCourt = 'est_king_of_the_court';
  static const formatManual = 'est_manual';

  static const sideTop = 'ecs_top';
  static const sideBottom = 'ecs_bottom';
  static const positionCenter = 'epp_center';
  static const positionLeft = 'epp_left';
  static const positionRight = 'epp_right';

  static const assignNow = 'at_court_addition';
  static const assignLater = 'at_assign_later';
}

/// One place a player can stand in a match: a side and a position on it.
class MatchSlot {
  const MatchSlot(this.side, this.position);

  final String side;
  final String position;

  @override
  bool operator ==(Object other) =>
      other is MatchSlot && other.side == side && other.position == position;

  @override
  int get hashCode => Object.hash(side, position);
}

/// Slots of a match: singles has one player per side (centre), doubles a
/// left and a right player per side, an undecided match none yet.
List<MatchSlot> slotsFor(String matchType) => switch (matchType) {
  MatchKeys.singles => const [
    MatchSlot(MatchKeys.sideTop, MatchKeys.positionCenter),
    MatchSlot(MatchKeys.sideBottom, MatchKeys.positionCenter),
  ],
  MatchKeys.doubles => const [
    MatchSlot(MatchKeys.sideTop, MatchKeys.positionLeft),
    MatchSlot(MatchKeys.sideTop, MatchKeys.positionRight),
    MatchSlot(MatchKeys.sideBottom, MatchKeys.positionLeft),
    MatchSlot(MatchKeys.sideBottom, MatchKeys.positionRight),
  ],
  _ => const [],
};

/// A match of a competitive or casual game, in play order.
class MatchDraft {
  const MatchDraft({
    this.matchType = MatchKeys.undecided,
    this.players = const {},
  });

  final String matchType;

  /// Players assigned to slots ("assign players now").
  final Map<MatchSlot, AppUser> players;

  List<MatchSlot> get slots => slotsFor(matchType);

  /// Singles take 2 players, anything else 4 (native `setRSVPandPlayerLimit`
  /// counts an undecided match as doubles).
  int get playerCount => matchType == MatchKeys.singles ? 2 : 4;

  bool get allSlotsFilled => filled(multiTeam: false);

  /// Every spot has a player. Against another team only the user's own side
  /// (the top) is filled here; the opponent team assigns its own players.
  bool filled({required bool multiTeam}) {
    final own = [
      for (final s in slots)
        if (!multiTeam || s.side == MatchKeys.sideTop) s,
    ];
    return own.isNotEmpty && own.every(players.containsKey);
  }

  /// Changing the match type clears the players (native
  /// `updateSelectedMatchType`).
  MatchDraft withType(String type) =>
      type == matchType ? this : MatchDraft(matchType: type);

  /// Puts [user] in [slot]; a player already standing elsewhere in this match
  /// moves.
  MatchDraft withPlayer(MatchSlot slot, AppUser user) => MatchDraft(
    matchType: matchType,
    players: {
      for (final e in players.entries)
        if (e.key != slot && e.value.id != user.id) e.key: e.value,
      slot: user,
    },
  );

  MatchDraft withoutPlayer(MatchSlot slot) => MatchDraft(
    matchType: matchType,
    players: {
      for (final e in players.entries)
        if (e.key != slot) e.key: e.value,
    },
  );
}
