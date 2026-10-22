abstract final class CreateEventMatchesTestIds {
  static const root = 'create_event_matches_screen';
  static const title = 'create_event_matches_title';
  static const next = 'create_event_matches_next_button';
  static const addMatch = 'create_event_add_match_button';

  /// Round robin setup.
  static const courtCountPrefix = 'create_event_rr_court_count';

  /// `create_event_match_<index>`, 0-based, in play order.
  static String match(int index) => 'create_event_match_$index';

  /// `create_event_match_<index>_type_<mt_singles|mt_doubles|mt_undecided>`.
  static String matchType(int index, String type) =>
      'create_event_match_${index}_type_$type';

  static String removeMatch(int index) => 'create_event_match_${index}_remove';

  /// `create_event_rr_game_<egt_singles|egt_doubles|egt_both>`.
  static String gameType(String key) => 'create_event_rr_game_$key';

  /// `create_event_rr_partners_<ept_rotating|ept_fixed>`.
  static String partners(String key) => 'create_event_rr_partners_$key';
}
