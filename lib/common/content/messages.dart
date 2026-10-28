/// Server-driven UI copy (`resources/messages`, `resources/pre_login_messages`).
///
/// The backend returns a nested JSON tree of snake_case keys
/// (`home_page.upcoming_events_title`, `events.create.nav_title`, ...). Instead
/// of mirroring hundreds of fields, strings are read by path with a local
/// fallback (the ARB text) so a missing key never shows an empty label.
class Messages {
  const Messages(this._tree);

  static const empty = Messages({});

  final Map<String, dynamic> _tree;

  bool get isEmpty => _tree.isEmpty;

  /// The string at [path] (dot-separated), or null when absent / not a string.
  String? lookup(String path) {
    Object? node = _tree;
    for (final part in path.split('.')) {
      if (node is Map<String, dynamic> && node.containsKey(part)) {
        node = node[part];
      } else {
        return null;
      }
    }
    return node is String && node.trim().isNotEmpty ? node : null;
  }

  /// Server text for [path], else [fallback].
  String text(String path, String fallback) => lookup(path) ?? fallback;

  /// Replaces `{name}`-style placeholders in the server text.
  String format(String path, String fallback, Map<String, String> values) {
    var out = text(path, fallback);
    values.forEach((k, v) => out = out.replaceAll('{$k}', v));
    return out;
  }
}

/// Paths of the strings the app reads so far (native `LocalizedStrings` /
/// `LocalizedPreLoginStrings` field names, in their JSON form).
abstract final class MessageKeys {
  // resources/messages
  static const homeTitle = 'home_page.nav_title';
  static const homeUpcomingTitle = 'home_page.upcoming_events_title';
  static const homeUpcomingEmpty = 'home_page.upcoming_events_no_events_title';
  static const homeSeeAll = 'home_page.upcoming_events_see_all_link';
  static const homePendingTitle = 'home_page.pending_actions_title';
  static const homePendingEmpty = 'home_page.pending_actions_no_actions_title';
  static const homeActivityTitle = 'home_page.activity_title';
  static const homeActivityEmpty = 'home_page.activity_no_events_title';
  static const homeActivityEvents = 'home_page.activity_events_label';
  static const homeActivityWins = 'home_page.activity_wins_label';
  static const homeActivityLosses = 'home_page.activity_losses_label';
  static const homeUpdatesTitle = 'home_page.latest_updates_title';
  static const homeUpdatesEmpty = 'home_page.latest_updates_no_updates_title';

  // settings.share_with_friends_strings
  static const shareTitle = 'settings.share_with_friends_strings.title';
  static const shareText = 'settings.share_with_friends_strings.sub_text';
  static const shareAction = 'settings.share_with_friends_strings.share_button';
  static const shareCopy =
      'settings.share_with_friends_strings.copy_link_button';
  static const shareCopied =
      'settings.share_with_friends_strings.copied_link_message';
  static const shareMessage =
      'settings.share_with_friends_strings.share_message_text';

  // settings.subscription
  static const subProTitle = 'settings.subscription.pro_text';
  static const subUpgrade = 'settings.subscription.upgrade_now_button';
  static const subRestore = 'settings.subscription.restore_purchase_link';
  static const subRedeem = 'settings.subscription.redeem_code_link';
  static const subTerms = 'settings.subscription.terms_of_service_link';
  static const subPrivacy = 'settings.subscription.privacy_link';
  static const subPaymentAndroid =
      'settings.subscription.payment_sub_text_android';
  static const subBenefit1Title =
      'settings.subscription.carousel_item_teams_title';
  static const subBenefit1Text =
      'settings.subscription.carousel_item_teams_sub_text';
  static const subBenefit2Title =
      'settings.subscription.carousel_item_premium_title';
  static const subBenefit2Text =
      'settings.subscription.carousel_item_premium_sub_text';
  static const subBenefit3Title =
      'settings.subscription.carousel_item_support_title';
  static const subBenefit3Text =
      'settings.subscription.carousel_item_support_sub_text';

  static const scheduleTitle = 'schedule.nav_title';
  static const scheduleUpcomingTab = 'schedule.events_title';
  static const schedulePastTab = 'schedule.past_events_title';
  static const scheduleNoUpcoming = 'schedule.no_upcoming_events_title';
  static const scheduleNoPast = 'schedule.no_past_events_title';

  static const teamArchivedCreateEvent =
      'events.create.team_archived_create_event_error';

  static const teamCreateNavTitle = 'teams.create.nav_title';
  static const teamCreateNameLabel = 'teams.create.name_label';
  static const teamCreateNameHint = 'teams.create.name_hint';
  static const teamCreateNameRequiredError = 'teams.create.name_required_error';
  static const teamCreateTypeLabel = 'teams.create.type_label';
  static const teamCreateTypeRequiredError = 'teams.create.type_required_error';
  static const teamCreateSportsLabel = 'teams.create.sports_label';
  static const teamCreateSportRequiredError =
      'teams.create.sport_required_error';
  static const teamCreateRankingLabel = 'teams.create.ranking_label';
  static const teamCreateRankingSubText = 'teams.create.ranking_sub_text';

  static const teamSettingsNavTitle = 'teams.settings.nav_title';
  static const teamSettingsArchiveButton = 'teams.settings.archive_team_button';
  static const teamSettingsUnarchiveButton =
      'teams.settings.unarchive_team_button';
  static const teamSettingsDeleteButton = 'teams.settings.delete_team_button';

  static const buttonNext = 'global.buttons.next';
  static const buttonSave = 'global.buttons.save';
  static const buttonCancel = 'global.buttons.cancel';
  static const buttonContinue = 'global.buttons.continue';
  static const errorGeneral = 'global.errors.generic_server_error_general';

  static const createEventTitle = 'events.create.nav_title';
  static const createTypeTitle = 'events.create.event_type_selection_title';
  static const createSportTitle = 'events.create.sport_selection_title';
  static const createSettingsTitle = 'events.create.settings_title';
  static const createDeadlineTitle =
      'events.create.settings_response_deadline_option_title';
  static const createDetailsTitle = 'events.create.event_details_title';
  static const createVenueLabel = 'events.create.event_details_venue_label';
  static const createStartsAtLabel =
      'events.create.event_details_starts_at_label';
  static const createDurationLabel =
      'events.create.event_details_duration_label';
  static const createNotesLabel = 'events.create.event_details_notes_label';
  static const createVenueRequired = 'events.create.venue_required_error';
  static const createStartRequired =
      'events.create.start_date_time_required_error';
  static const createEventTypeRequired =
      'events.create.event_type_required_error';
  static const createPoolTitle = 'events.create.player_pool_settings_title';
  static const createMaxPlayersLabel =
      'events.create.player_pool_settings_max_count_label';
  static const createRsvpLimitLabel =
      'events.create.player_pool_settings_rsvp_limit_label';
  static const createAcceptanceLabel =
      'events.create.player_pool_settings_acceptance_type_label';
  static const createPlayersTitle = 'events.create.players_list_title';
  static const createSelectVenueButton = 'events.create.select_venue_button';
  static const createMatchesTitle = 'events.create.matches_title';
  static const createAddMatchButton = 'events.create.add_another_match_button';
  static const createScoringTitle =
      'events.create.settings_scoring_format_title';
  static const createScoringHint =
      'events.create.settings_scoring_format_sub_text';
  static const createScoreGamesToWin =
      'events.create.settings_scoring_format_min_games_to_win';
  static const createScoreMinimumPoints =
      'events.create.settings_scoring_format_min_points_to_win';
  static const createdTitle = 'events.created.title';
  static const createdGoToSchedule = 'events.created.go_to_schedule_button';
  static const createdSeeDetails = 'events.created.see_event_details_button';

  // resources/pre_login_messages
  static const preProductTitle = 'introduction.product_title';
  static const preProductSubText = 'introduction.product_sub_text';
  static const preSignUpButton = 'introduction.sign_up_button';
  static const preAlreadyMember = 'signup.already_member_text';
  static const preSignInLink = 'signup.sign_in_link';
  static const preSignUpTitle = 'signup.title';
  static const preSignInTitle = 'signup.sign_in_title';
  static const prePhoneRequired = 'signup.phone_number_required_error';
  static const prePhoneInvalid = 'signup.phone_number_invalid_error';
  static const preCodeTitle = 'signup.code_verification_title';
  static const preCodeInvalid = 'signup.code_invalid_error';
  static const preResendCode = 'signup.resend_code_button';
  static const preFirstNameRequired = 'signup.first_name_required_error';
  static const preLastNameRequired = 'signup.last_name_required_error';
  static const preEmailInvalid = 'signup.email_invalid_error';
  static const preEmailTaken = 'signup.duplicate_email_error';
  static const preRoleTitle = 'signup.role_selection_title';
  static const prePlayerTitle = 'signup.role_player_title';
  static const prePlayerSub = 'signup.role_player_sub_text';
  static const preCoachTitle = 'signup.role_coach_title';
  static const preCoachSub = 'signup.role_coach_sub_text';
  static const preParentTitle = 'signup.role_parent_title';
  static const preParentSub = 'signup.role_parent_sub_text';
  static const prePlayerSportTitle = 'signup.player_sport_selection_title';
  static const preCoachSportTitle = 'signup.coach_sport_selection_title';
  static const preSportRequiredTitle = 'signup.sport_required_error_title';
  static const preRoleRequiredTitle = 'signup.role_required_error_title';
  static const preCreatedTitle = 'signup.created_account_title';
}
