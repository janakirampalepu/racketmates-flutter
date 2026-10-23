abstract final class EventManagePairsTestIds {
  static const root = 'event_manage_pairs_screen';
  static const title = 'event_manage_pairs_title';
  static const noPairs = 'event_manage_pairs_none';
  static const unpairedNone = 'event_manage_pairs_unpaired_none';
  static const pair = 'event_manage_pairs_pair_button';
  static const next = 'event_manage_pairs_continue_button';
  static const error = 'event_manage_pairs_error';
  static const waitingOk = 'event_manage_pairs_waiting_ok_button';

  /// `event_manage_pairs_filter_<key>`: `all`, `mt_doubles`, `mt_undecided`.
  static String filter(String key) => 'event_manage_pairs_filter_$key';

  /// `event_manage_pair_<index>` and its remove button (new pairs only).
  static String existing(int index) => 'event_manage_pair_$index';
  static String added(int index) => 'event_manage_pair_added_$index';
  static String removeAdded(int index) =>
      'event_manage_pair_added_${index}_remove';

  /// `event_manage_pairs_player_<userId>`.
  static String player(int id) => 'event_manage_pairs_player_$id';
}
