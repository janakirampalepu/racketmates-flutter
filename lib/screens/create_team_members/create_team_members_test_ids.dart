abstract final class CreateTeamMembersTestIds {
  static const root = 'create_team_members_screen';
  static const title = 'create_team_members_title';
  static const search = 'create_team_members_search';
  static const empty = 'create_team_members_empty';
  static const retry = 'create_team_members_retry';
  static const create = 'create_team_members_create_button';
  static const error = 'create_team_members_error';

  /// `create_team_member_<userId>_<captain|player|coach>`.
  static String role(int userId, String role) =>
      'create_team_member_${userId}_$role';
}
