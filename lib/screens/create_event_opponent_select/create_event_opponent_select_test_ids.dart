abstract final class CreateEventOpponentSelectTestIds {
  static const root = 'create_event_opponent_screen';
  static const title = 'create_event_opponent_title';
  static const next = 'create_event_opponent_next_button';
  static const search = 'create_event_opponent_search';
  static const empty = 'create_event_opponent_empty';
  static const error = 'create_event_opponent_error';
  static const retry = 'create_event_opponent_retry';
  static const requiredError = 'create_event_opponent_required';

  /// `create_event_opponent_team_<id>`.
  static String team(int id) => 'create_event_opponent_team_$id';
}
