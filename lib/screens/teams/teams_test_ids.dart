abstract final class TeamsTestIds {
  static const root = 'teams_screen';
  static const create = 'teams_create_button';
  static const createInEmpty = 'teams_create_button_empty_state';
  static const empty = 'teams_empty';
  static const error = 'teams_error';
  static const retry = 'teams_retry';

  /// `team_tile_<id>`.
  static String tile(int id) => 'team_tile_$id';
  static String archivedBadge(int id) => 'team_tile_${id}_archived';
  static const accessDialog = 'teams_access_dialog';
  static const accessDialogUpgrade = 'teams_access_dialog_upgrade_button';
  static const accessDialogClose = 'teams_access_dialog_close';
}
