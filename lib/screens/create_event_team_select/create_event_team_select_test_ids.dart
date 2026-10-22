abstract final class CreateEventTeamSelectTestIds {
  static const root = 'create_event_team_select_screen';
  static const title = 'create_event_team_select_title';
  static const next = 'create_event_team_select_next_button';
  static const empty = 'create_event_team_select_empty';
  static const error = 'create_event_team_select_error';
  static const retry = 'create_event_team_select_retry';
  static const requiredError = 'create_event_team_select_required';

  /// `create_event_team_<id>`.
  static String team(int id) => 'create_event_team_$id';
}
