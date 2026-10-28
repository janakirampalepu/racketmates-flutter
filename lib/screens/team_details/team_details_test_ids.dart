abstract final class TeamDetailsTestIds {
  static const root = 'team_details_screen';
  static const title = 'team_details_title';
  static const error = 'team_details_error';
  static const retry = 'team_details_retry';
  static const membersError = 'team_details_members_error';
  static const membersEmpty = 'team_details_members_empty';

  /// `team_member_<teamPlayerId>`.
  static String member(int id) => 'team_member_$id';

  static const tabRankings = 'team_tab_rankings';

  // Schedule
  static const scheduleUpcoming = 'team_schedule_upcoming_button';
  static const schedulePast = 'team_schedule_past_button';
  static const scheduleEmpty = 'team_schedule_empty';
  static const scheduleError = 'team_schedule_error';
  static const scheduleRetry = 'team_schedule_retry';
  static const scheduleCreateEvent = 'team_schedule_create_event_button';

  /// `team_schedule_event_<eventId>`.
  static String scheduleEvent(int id) => 'team_schedule_event_$id';

  // Rankings
  static const rankingsOff = 'team_rankings_off';
  static const rankingsEmpty = 'team_rankings_empty';
  static const rankingsError = 'team_rankings_error';
  static const rankingsRetry = 'team_rankings_retry';
  static const rankingsPeriod = 'team_rankings_period';
  static const rankingReset = 'team_rankings_reset_button';
  static const rankingPointsDialog = 'team_ranking_points_dialog';
  static const rankingPointsField = 'team_ranking_points_field';
  static const rankingPointsSave = 'team_ranking_points_save_button';
  static const rankingPointsFailed = 'team_ranking_points_failed';
  static const rankingResetConfirmYes = 'team_ranking_reset_confirm_yes';
  static const rankingResetFailed = 'team_ranking_reset_failed';

  /// `team_rank_sport_<sportKey>`.
  static String rankingSport(String key) => 'team_rank_sport_$key';

  /// `team_rank_add_points_<teamPlayerId>`.
  static String rankingAddPoints(int id) => 'team_rank_add_points_$id';

  /// `team_rank_match_<matchKey|all>`.
  static String rankingMatch(String key) => 'team_rank_match_$key';

  /// `team_rank_row_<teamPlayerId>`.
  static String rankingRow(int id) => 'team_rank_row_$id';

  // Members
  static const showInactive = 'team_members_show_inactive_switch';
  static const addMembers = 'team_members_add_button';
  static const membersSearch = 'team_members_search_field';

  /// `team_members_sport_filter_<sportKey|all>`.
  static String membersSportFilter(String key) =>
      'team_members_sport_filter_$key';
  static const accessDialog = 'team_members_access_dialog';
  static const accessDialogClose = 'team_members_access_dialog_close';
  static const accessDialogUpgrade = 'team_members_access_dialog_upgrade';
  static const changeFailed = 'team_members_change_failed';

  /// `team_member_<id>_actions`.
  static String memberActions(int id) => 'team_member_${id}_actions';

  static const actionEdit = 'team_member_action_edit_roles';
  static const actionDeactivate = 'team_member_action_deactivate';
  static const actionReactivate = 'team_member_action_reactivate';
  static const actionRemove = 'team_member_action_remove';

  static const rolesDialog = 'team_roles_dialog';
  static const rolesCaptain = 'team_roles_captain';
  static const rolesPlayer = 'team_roles_player';
  static const rolesCoach = 'team_roles_coach';
  static const rolesSave = 'team_roles_save_button';
  static const rolesCancel = 'team_roles_cancel_button';
  static const rolesError = 'team_roles_error';
  static const confirmYes = 'team_confirm_yes_button';
  static const confirmNo = 'team_confirm_no_button';
}

abstract final class TeamAddMembersTestIds {
  static const root = 'team_add_members_screen';
  static const title = 'team_add_members_title';
  static const search = 'team_add_members_search';
  static const empty = 'team_add_members_empty';
  static const error = 'team_add_members_error';
  static const retry = 'team_add_members_retry';
  static const save = 'team_add_members_save_button';
  static const failed = 'team_add_members_failed';

  /// `team_add_member_<userId>_<captain|player|coach>`.
  static String role(int userId, String role) =>
      'team_add_member_${userId}_$role';
}

abstract final class TeamHomeActionIds {
  static const settingsButton = 'team_home_settings_button';
  static const createEvent = 'team_home_create_event_button';
  static const archivedBanner = 'team_home_archived_banner';
  static const unarchiveButton = 'team_home_unarchive_button';

  // Dashboard sections shared with Home (`common/widgets/home_sections.dart`).
  static const upcomingSection = 'team_home_upcoming_section';
  static const upcomingSeeAll = 'team_home_upcoming_see_all';
  static const upcomingRetry = 'team_home_upcoming_retry';
  static const upcomingCreateEvent = 'team_home_upcoming_create_event_button';

  /// `team_home_upcoming_event_<eventId>`.
  static String upcomingEvent(int id) => 'team_home_upcoming_event_$id';

  static const pendingSection = 'team_home_pending_section';
  static const pendingRetry = 'team_home_pending_retry';

  /// `team_home_pending_action_<eventId>`.
  static String pendingAction(int id) => 'team_home_pending_action_$id';

  static const activitySection = 'team_home_activity_section';
  static const activityRetry = 'team_home_activity_retry';
  static const activityYear = 'team_home_activity_year';

  // Team-only members preview.
  static const membersSection = 'team_home_members_section';
  static const membersSeeAll = 'team_home_members_see_all';
  static const manageMembers = 'team_home_manage_members_button';

  /// `team_home_member_preview_<teamPlayerId>`.
  static String memberPreview(int id) => 'team_home_member_preview_$id';
}

abstract final class TeamSettingsTestIds {
  static const root = 'team_settings_screen';
  static const title = 'team_settings_title';
  static const actionsMenu = 'team_settings_actions_menu';
  static const name = 'team_settings_name_field';
  static const nameError = 'team_settings_name_error';
  static const typeError = 'team_settings_type_error';
  static const sportError = 'team_settings_sport_error';
  static const ranking = 'team_settings_ranking_switch';
  static const save = 'team_settings_save_button';
  static const failed = 'team_settings_failed';
  static const archive = 'team_settings_archive_button';
  static const unarchive = 'team_settings_unarchive_button';
  static const delete = 'team_settings_delete_button';
  static const actionFailed = 'team_settings_action_failed';
  static const confirmYes = 'team_settings_confirm_yes_button';
  static const confirmNo = 'team_settings_confirm_no_button';
  static const loadError = 'team_settings_load_error';
  static const retry = 'team_settings_retry_button';

  /// `team_settings_type_<tt_casual|tt_competitive>`.
  static String type(String key) => 'team_settings_type_$key';

  /// `team_settings_sport_<st_*>`.
  static String sport(String key) => 'team_settings_sport_$key';
}
