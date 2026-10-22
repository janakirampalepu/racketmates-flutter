abstract final class CreateTeamTestIds {
  static const root = 'create_team_screen';
  static const title = 'create_team_title';
  static const name = 'create_team_name_field';
  static const nameError = 'create_team_name_error';
  static const typeError = 'create_team_type_error';
  static const sportError = 'create_team_sport_error';
  static const ranking = 'create_team_ranking_switch';
  static const selfPlayer = 'create_team_self_player_switch';
  static const selfCoach = 'create_team_self_coach_switch';
  static const next = 'create_team_next_button';

  /// `create_team_type_<tt_casual|tt_competitive>`.
  static String type(String key) => 'create_team_type_$key';

  /// `create_team_sport_<st_*>`.
  static String sport(String key) => 'create_team_sport_$key';
}
