abstract final class TeamDetailsTestIds {
  static const root = 'team_details_screen';
  static const title = 'team_details_title';
  static const error = 'team_details_error';
  static const retry = 'team_details_retry';
  static const membersError = 'team_details_members_error';
  static const membersEmpty = 'team_details_members_empty';

  /// `team_member_<teamPlayerId>`.
  static String member(int id) => 'team_member_$id';
}
