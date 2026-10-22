abstract final class CreateEventTeamDynamicsTestIds {
  static const root = 'create_event_dynamics_screen';
  static const title = 'create_event_dynamics_title';
  static const next = 'create_event_dynamics_next_button';
  static const name = 'create_event_dynamics_name_field';
  static const nameError = 'create_event_dynamics_name_error';

  /// `create_event_dynamics_<ott_within_team|ott_specific_team|ott_unknown_team_with_name>`.
  static String option(String key) => 'create_event_dynamics_$key';
}
