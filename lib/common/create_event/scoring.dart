import 'package:racketmates/common/sign_up/sign_up_draft.dart';

/// Scoring format and deciding-set keys (native `AppConstants`,
/// `ReferenceDataConstants`, `SharePrefKeys`).
abstract final class ScoringKeys {
  static const singleSet = 'sf_single_set';
  static const singleGame = 'sf_single_game';
  static const bestOf3Sets = 'sf_best_of_3_sets';
  static const bestOf5Sets = 'sf_best_of_5_sets';
  static const bestOf3Games = 'sf_best_of_3_games';
  static const fast4Tennis = 'sf_fast4_tennis';
  static const reachPoints = 'sf_reach_points';
  static const totalPoints = 'sf_total_points';
  static const timeBased = 'sf_time_based';

  static const regularSet = 'dst_regular_set';
  static const tieBreak = 'dst_tie_break';
  static const decideLater = 'dst_decide_later';
  static const decidingSetTypes = [regularSet, tieBreak, decideLater];
}

/// How the minimum score of a format is edited.
enum ScoreInput {
  /// Not editable (best-of formats).
  none,

  /// A number, 1 and up (points or games to win).
  number,

  /// Minutes in steps of five (time based rounds).
  minutes,
}

const timeBasedMinMinutes = 5;
const timeBasedMaxMinutes = 120;
const timeBasedStepMinutes = 5;
const timeBasedDefaultMinutes = 15;

ScoreInput scoreInputFor(String format) => switch (format) {
  ScoringKeys.singleSet ||
  ScoringKeys.singleGame ||
  ScoringKeys.reachPoints ||
  ScoringKeys.totalPoints => ScoreInput.number,
  ScoringKeys.timeBased => ScoreInput.minutes,
  _ => ScoreInput.none,
};

/// Only tennis and padel can end on a tie-break set (native
/// `canAllowTieBreakSets`).
bool canChooseDecidingSet(SportKey? sport) =>
    sport == SportKey.tennis || sport == SportKey.padel;

/// Minimum score a format starts with: the server's `minimum_scores` entry,
/// or the native fixed defaults for points and time based formats.
int defaultMinimumScore(String format, Map<String, num?> minimums) =>
    switch (format) {
      ScoringKeys.reachPoints => 10,
      ScoringKeys.totalPoints => 20,
      ScoringKeys.timeBased => timeBasedDefaultMinutes,
      _ => minimums[format]?.toInt() ?? 0,
    };

/// The scoring chosen for a game (`scoring_format`, `deciding_set_type`,
/// `minimum_score_to_win`).
class ScoringChoice {
  const ScoringChoice({
    required this.format,
    required this.minimumScore,
    this.decidingSetType = ScoringKeys.decideLater,
  });

  final String format;
  final int minimumScore;
  final String decidingSetType;

  ScoringChoice copyWith({int? minimumScore, String? decidingSetType}) =>
      ScoringChoice(
        format: format,
        minimumScore: minimumScore ?? this.minimumScore,
        decidingSetType: decidingSetType ?? this.decidingSetType,
      );
}
