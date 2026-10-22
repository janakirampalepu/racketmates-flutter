// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loadingLabel => 'Loading';

  @override
  String get welcomePlaceholder => 'Welcome';

  @override
  String get homePlaceholder => 'Home';

  @override
  String get signOutAction => 'Sign out';

  @override
  String get appUpdateTitle => 'A new version is available';

  @override
  String get appUpdateAction => 'Update';

  @override
  String get appUpdateLaterAction => 'Later';

  @override
  String get welcomeTitle => 'Welcome to Racketmates';

  @override
  String get welcomeSubtitle =>
      'Organize games, teams and events in one place.';

  @override
  String get signInAction => 'Sign in';

  @override
  String get signUpAction => 'Sign up';

  @override
  String get phoneEntrySignInTitle => 'Sign in';

  @override
  String get phoneEntrySignUpTitle => 'Sign up';

  @override
  String get phoneEntryDescription =>
      'Enter your mobile number and we will text you a verification code.';

  @override
  String get mobileNumberLabel => 'Mobile number';

  @override
  String get countryLabel => 'Country';

  @override
  String get continueAction => 'Continue';

  @override
  String get phoneRequiredError => 'Enter your mobile number.';

  @override
  String get phoneInvalidError => 'Enter a valid mobile number.';

  @override
  String get genericErrorMessage => 'Something went wrong. Please try again.';

  @override
  String get networkErrorMessage => 'Check your connection and try again.';

  @override
  String get backAction => 'Back';

  @override
  String get closeAction => 'Close';

  @override
  String get searchHint => 'Search';

  @override
  String get countryPickerTitle => 'Select country';

  @override
  String get otpTitle => 'Enter verification code';

  @override
  String otpDescription(String number) {
    return 'We sent a 6-digit code to $number.';
  }

  @override
  String get otpChangeNumber => 'Change';

  @override
  String get otpInvalidCodeError => 'That code is not valid. Try again.';

  @override
  String get otpResendAction => 'Resend code';

  @override
  String otpResendIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get otpCodeLabel => 'Verification code';

  @override
  String get notRegisteredTitle => 'Number not registered';

  @override
  String get notRegisteredMessage =>
      'This number is not registered yet. Continue to create an account instead.';

  @override
  String get alreadyRegisteredTitle => 'Number already registered';

  @override
  String get alreadyRegisteredMessage =>
      'This number already has an account. Continue to sign in instead.';

  @override
  String get signUpPlaceholder => 'Sign-up is not available in this build yet.';

  @override
  String get nextAction => 'Next';

  @override
  String get saveAction => 'Save';

  @override
  String get skipForNowAction => 'I\'ll do this later';

  @override
  String get removeAction => 'Remove';

  @override
  String get editAction => 'Edit';

  @override
  String get signUpDetailsTitle => 'Tell us about you';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get emailLabel => 'Email (optional)';

  @override
  String get firstNameRequiredError => 'Enter your first name.';

  @override
  String get lastNameRequiredError => 'Enter your last name.';

  @override
  String get emailInvalidError => 'Enter a valid email address.';

  @override
  String get emailTakenError => 'This email is already in use.';

  @override
  String get roleSelectionTitle => 'How will you use Racketmates?';

  @override
  String get rolePlayer => 'Player';

  @override
  String get roleCoach => 'Coach';

  @override
  String get roleParent => 'Parent';

  @override
  String get roleRequiredError => 'Select at least one role.';

  @override
  String get sportsPlayerTitle => 'Which sports do you play?';

  @override
  String get sportsCoachTitle => 'Which sports do you coach?';

  @override
  String get sportBadminton => 'Badminton';

  @override
  String get sportPadel => 'Padel';

  @override
  String get sportPickleball => 'Pickleball';

  @override
  String get sportTennis => 'Tennis';

  @override
  String get sportRequiredError => 'Select at least one sport.';

  @override
  String get kidsTitle => 'Your kids';

  @override
  String get addKidAction => 'Add a kid';

  @override
  String get kidsMaxReached => 'You can add up to 2 kids.';

  @override
  String get kidFormTitle => 'Add a kid';

  @override
  String get kidMobileLabel => 'Kid\'s mobile number (optional)';

  @override
  String get kidMobileInvalidError => 'Enter a valid mobile number.';

  @override
  String get kidMobileTakenError => 'This number is already registered.';

  @override
  String get creatingAccountMessage => 'Creating your account...';

  @override
  String get profilePictureTitle => 'Add a profile picture';

  @override
  String get profilePictureHint => 'Help others recognize you.';

  @override
  String get takePhotoAction => 'Take a photo';

  @override
  String get chooseFromGalleryAction => 'Choose from gallery';

  @override
  String get uploadPhotoAction => 'Upload photo';

  @override
  String get congratulationsTitle => 'You\'re all set!';

  @override
  String congratulationsGreeting(String name) {
    return 'Welcome, $name.';
  }

  @override
  String get goToHomeAction => 'Take me to home';

  @override
  String get addFirstEventAction => 'Add my first event';

  @override
  String get profilePictureUploadError =>
      'Could not upload the photo. Try again.';

  @override
  String homeGreeting(String name) {
    return 'Hi, $name';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navSchedule => 'Schedule';

  @override
  String get navChat => 'Chat';

  @override
  String get chatNewTitle => 'New chat';

  @override
  String get chatNewSearchHint => 'Search players';

  @override
  String get chatNewEmpty => 'No players found.';

  @override
  String get chatNewError => 'Players could not be loaded.';

  @override
  String get chatNewCreateFailed =>
      'The chat could not be started. Please try again.';

  @override
  String get chatNewStarting => 'Starting the chat';

  @override
  String get chatNewAction => 'Start a new chat';

  @override
  String get eventChatAction => 'Chat';

  @override
  String get eventChatChoose => 'Which chat room do you want to open?';

  @override
  String get eventChatPlayers => 'Players chat room';

  @override
  String get eventChatCaptains => 'Captains chat room';

  @override
  String get eventChatFailed =>
      'The chat room could not be opened. Please try again.';

  @override
  String get eventChatOpening => 'Opening the chat room';

  @override
  String get chatConnecting => 'Connecting to chat';

  @override
  String get chatFailed =>
      'Chat could not connect. Check your connection and try again.';

  @override
  String get chatUnavailable => 'Chat is not available on this build.';

  @override
  String navChatUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread messages',
      one: '1 unread message',
    );
    return '$_temp0';
  }

  @override
  String get navTeams => 'Teams';

  @override
  String get homePendingActions => 'Pending actions';

  @override
  String get homeUpcoming => 'Upcoming';

  @override
  String get homeLatestUpdates => 'Latest updates';

  @override
  String get homeActivity => 'Activity';

  @override
  String get homePast => 'Recent games';

  @override
  String get seeAllAction => 'See all';

  @override
  String get retryAction => 'Try again';

  @override
  String get emptyPendingActions => 'Nothing needs your attention.';

  @override
  String get emptyUpcoming => 'No upcoming events.';

  @override
  String get emptyLatestUpdates => 'No updates yet.';

  @override
  String get emptyActivity => 'No activity yet.';

  @override
  String get emptyPast => 'No past events.';

  @override
  String get sectionLoadError => 'Could not load this section.';

  @override
  String get statWins => 'Wins';

  @override
  String get statLosses => 'Losses';

  @override
  String get statEvents => 'Events';

  @override
  String get statHours => 'Hours';

  @override
  String get scheduleTitle => 'Schedule';

  @override
  String get tabUpcoming => 'Upcoming';

  @override
  String get tabPast => 'Past';

  @override
  String get scheduleEmptyUpcoming => 'You have no upcoming events.';

  @override
  String get scheduleEmptyPast => 'You have no past events.';

  @override
  String get scheduleLoadError => 'Could not load events.';

  @override
  String get eventDetailsTitle => 'Event details';

  @override
  String get eventWhenLabel => 'When';

  @override
  String get eventWhereLabel => 'Where';

  @override
  String get eventStatusLabel => 'Status';

  @override
  String get eventParticipantsLabel => 'Players';

  @override
  String get eventNotesLabel => 'Notes';

  @override
  String eventSpotsLeft(int count) {
    return '$count spots left';
  }

  @override
  String get eventLoadError => 'Could not load this event.';

  @override
  String get eventNoPlayers => 'No players yet.';

  @override
  String get eventYourStatus => 'Your status';

  @override
  String moreSuffix(int count) {
    return '+$count';
  }

  @override
  String get comingSoonTitle => 'Coming soon';

  @override
  String get comingSoonMessage =>
      'This section is not available in this build yet.';

  @override
  String get unknownPlayer => 'Player';

  @override
  String get rsvpAccept => 'Confirm';

  @override
  String get rsvpDecline => 'Decline';

  @override
  String get rsvpRejoin => 'Rejoin';

  @override
  String get rsvpLeave => 'Leave event';

  @override
  String get rsvpJoinWaitlist => 'Join waitlist';

  @override
  String get rsvpEditResponse => 'Edit response';

  @override
  String get rsvpDeclineTitle => 'Decline this event?';

  @override
  String get rsvpDeclineMessage =>
      'The organizer will be told you cannot make it.';

  @override
  String get rsvpLeaveTitle => 'Leave this event?';

  @override
  String get rsvpLeaveMessage => 'You will be removed from the event.';

  @override
  String get rsvpDone => 'Your response was saved.';

  @override
  String get rsvpNeedsPicker =>
      'Choosing between several times or partners is not available in this build yet.';

  @override
  String get rsvpNeedsSubscription =>
      'A subscription is required for this action.';

  @override
  String get rsvpActionFailed => 'Could not update your response.';

  @override
  String get cancelEventAction => 'Cancel event';

  @override
  String get cancelEventTitle => 'Cancel this event?';

  @override
  String get cancelEventReasonLabel => 'Reason (optional)';

  @override
  String get cancelEventRemoveLabel => 'Also remove it from the schedule';

  @override
  String get cancelEventConfirm => 'Cancel event';

  @override
  String get cancelEventKeep => 'Keep event';

  @override
  String get cancelEventDone => 'The event was cancelled.';

  @override
  String get cancelEventFailed => 'Could not cancel the event.';

  @override
  String get moreOptionsLabel => 'More options';

  @override
  String get placePickerTitle => 'Choose a venue';

  @override
  String get placeSearchHint => 'Search venues';

  @override
  String get tabSearchPlaces => 'Search';

  @override
  String get tabFavouritePlaces => 'Favourites';

  @override
  String get placesEmpty => 'No venues found.';

  @override
  String get placesFavouritesEmpty => 'You have no favourite venues yet.';

  @override
  String get placesLoadError => 'Could not load venues.';

  @override
  String get addFavouriteAction => 'Add to favourites';

  @override
  String get removeFavouriteAction => 'Remove from favourites';

  @override
  String get createEventTitle => 'Create event';

  @override
  String get createEventAction => 'Create event';

  @override
  String get createTypeTitle => 'What kind of event?';

  @override
  String get createTypeUnavailable => 'Not available in this build yet.';

  @override
  String get createSportTitle => 'Which sport?';

  @override
  String get createSettingsTitle => 'Event settings';

  @override
  String get createDeadlineLabel => 'Response deadline';

  @override
  String get createDeadlineHint =>
      'Players must respond this long before the event.';

  @override
  String createDeadlineValue(String count) {
    return '$count before';
  }

  @override
  String get createUnitHours => 'Hours';

  @override
  String get createUnitDays => 'Days';

  @override
  String get createAllowManageLabel => 'Let participants manage players';

  @override
  String get createPlayersTitle => 'Who is invited?';

  @override
  String get createPlayersSearchHint => 'Search players';

  @override
  String get createPlayersRequired => 'Invite at least one player.';

  @override
  String get createPlayersEmpty => 'No players found.';

  @override
  String get createPlayersLoadError => 'Could not load players.';

  @override
  String get createPlayersSelected => 'Invited';

  @override
  String get createWhenWhereTitle => 'When and where';

  @override
  String get createVenueLabel => 'Venue';

  @override
  String get createSelectVenue => 'Select a venue';

  @override
  String get createCourtsLabel => 'Courts';

  @override
  String get createNoCourts =>
      'This venue has no courts listed for this sport.';

  @override
  String get createDateLabel => 'Date';

  @override
  String get createTimeLabel => 'Start time';

  @override
  String get createDurationLabel => 'Duration';

  @override
  String createDurationValue(int minutes) {
    return '$minutes min';
  }

  @override
  String get createNotesLabel => 'Notes (optional)';

  @override
  String get createVenueRequired => 'Choose a venue.';

  @override
  String get createStartRequired => 'Choose a date and start time.';

  @override
  String get createStartInPast => 'The start time must be in the future.';

  @override
  String get createInviteSettingsTitle => 'Player limits';

  @override
  String get createMaxPlayersLabel => 'Maximum players';

  @override
  String get createRsvpLimitLabel => 'Responses allowed';

  @override
  String get createAcceptanceLabel => 'How players are added';

  @override
  String get createAcceptOrderOfResponse => 'First to respond';

  @override
  String get createAcceptPickManually => 'I pick manually';

  @override
  String get createDecrease => 'Decrease';

  @override
  String get createIncrease => 'Increase';

  @override
  String get createReviewTitle => 'Review';

  @override
  String get createReviewType => 'Type';

  @override
  String get createReviewSport => 'Sport';

  @override
  String get createReviewInvited => 'Invited';

  @override
  String get createFailed => 'Could not create the event.';

  @override
  String get createdTitle => 'Event created!';

  @override
  String get createdGoToSchedule => 'Go to schedule';

  @override
  String get createdSeeDetails => 'See event details';

  @override
  String get addEventAction => 'Create event';

  @override
  String get cancelWizardAction => 'Cancel';

  @override
  String get createCoachesTitle => 'Who is coaching?';

  @override
  String get createCoachesSearchHint => 'Search coaches';

  @override
  String get createCoachesRequired => 'Choose at least one coach.';

  @override
  String get createCoachesEmpty => 'No coaches found.';

  @override
  String get createPeopleTitle => 'Who is coming?';

  @override
  String get createPeopleRequired => 'Invite at least one person.';

  @override
  String get createReviewCoaches => 'Coaches';

  @override
  String get createCourtCountLabel => 'Number of courts';

  @override
  String createCourtsHint(int count) {
    return 'Choose up to $count courts.';
  }

  @override
  String get createScoringTitle => 'Scoring format';

  @override
  String get createScoringHint => 'Choose how matches are scored.';

  @override
  String get createScoringLoadError => 'We couldn\'t load the scoring formats.';

  @override
  String get createScoreGamesToWin => 'Minimum games to win';

  @override
  String get createScorePointsToWin => 'Points to win';

  @override
  String get createScoreMinimumPoints => 'Minimum points to win';

  @override
  String get createScoreTotalPoints => 'Total points';

  @override
  String get createScoreDuration => 'Round duration';

  @override
  String createScoreMinutes(int minutes) {
    return '$minutes mins';
  }

  @override
  String get createDecidingSetLabel => 'If the last set is tied';

  @override
  String get createDecidingRegular => 'Regular set';

  @override
  String get createDecidingTieBreak => 'Tie-break';

  @override
  String get createDecidingLater => 'Decide later';

  @override
  String get createLogResultsLabel => 'Players can log results';

  @override
  String get createMatchesTitle => 'Matches';

  @override
  String get createMatchesHint =>
      'Add the matches you will play. You can leave singles or doubles open.';

  @override
  String createMatchNumber(int number) {
    return 'Match $number';
  }

  @override
  String get createAddMatch => 'Add another match';

  @override
  String createRemoveMatch(int number) {
    return 'Remove match $number';
  }

  @override
  String get createMatchSingles => 'Singles';

  @override
  String get createMatchDoubles => 'Doubles';

  @override
  String get createMatchUndecided => 'Decide later';

  @override
  String get createRoundRobinTitle => 'Round robin';

  @override
  String get createRoundRobinCourtsHint => 'How many courts will be used?';

  @override
  String get createRoundRobinPlayersLabel => 'Players';

  @override
  String get createGameSingles => 'Singles';

  @override
  String get createGameDoubles => 'Doubles';

  @override
  String get createGameBoth => 'Both';

  @override
  String get createPartnersLabel => 'Partners';

  @override
  String get createPartnersRotating => 'Rotating';

  @override
  String get createPartnersRotatingHint => 'Partners change every round';

  @override
  String get createPartnersFixed => 'Fixed';

  @override
  String get createPartnersFixedHint =>
      'Pairs stay the same for the entire event';

  @override
  String get createRoundRobinFormatTitle =>
      'Select the type of your round robin';

  @override
  String get createFormatClassic => 'Classic';

  @override
  String get createFormatKing => 'King of the court';

  @override
  String get createFormatManual => 'Manual';

  @override
  String get createFormatClassicSingles =>
      'Rotate opponents each match, ensuring everyone competes against every player.';

  @override
  String get createFormatClassicRotating =>
      'Rotate partners and opponents each match, ensuring everyone plays with and against everyone.';

  @override
  String get createFormatClassicFixed =>
      'Keep the same partner throughout the event while rotating opponents each match.';

  @override
  String get createFormatKingSingles =>
      'Players battle to stay on the main court, rotating challengers each round.';

  @override
  String get createFormatKingRotating =>
      'Rotate partners and opponents while players compete to hold the winning court.';

  @override
  String get createFormatKingFixed =>
      'Fixed pairs battle to stay on the main court, rotating challengers each round.';

  @override
  String get createFormatManualHint =>
      'Build your round robin from scratch, choosing the structure and match setup yourself.';

  @override
  String get createAssignTypeTitle => 'How do you want to add players?';

  @override
  String get createAssignNow => 'Assign players to matches now';

  @override
  String get createAssignNowHint => 'Pick who plays in each match.';

  @override
  String get createAssignLater => 'Invite players and assign later';

  @override
  String get createAssignLaterHint =>
      'Invite players first and set the matches afterwards.';

  @override
  String get createAssignUndecided =>
      'Choose singles or doubles for every match to assign players now.';

  @override
  String get createAssignPlayersTitle => 'Assign players';

  @override
  String get createSideTop => 'Side A';

  @override
  String get createSideBottom => 'Side B';

  @override
  String get createAddPlayer => 'Add player';

  @override
  String createRemovePlayer(String name) {
    return 'Remove $name';
  }

  @override
  String get createAssignIncomplete => 'Fill every spot to continue.';

  @override
  String get createSlotPickerTitle => 'Choose a player';

  @override
  String get createReviewScoring => 'Scoring';

  @override
  String get createReviewMatches => 'Matches';

  @override
  String createReviewMatchLine(int number, String type) {
    return 'Match $number: $type';
  }

  @override
  String get teamsEmptyTitle => 'No teams yet';

  @override
  String get teamsEmptyBody =>
      'Create a team to organize events with your players.';

  @override
  String get teamsLoadError => 'We couldn\'t load your teams.';

  @override
  String get createTeamAction => 'Create team';

  @override
  String teamMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get teamTypeCasual => 'Casual';

  @override
  String get teamTypeCompetitive => 'Competitive';

  @override
  String get teamDetailsMembers => 'Members';

  @override
  String get teamMembersEmpty => 'No members yet.';

  @override
  String get teamMembersLoadError => 'We couldn\'t load the members.';

  @override
  String get teamDetailsLoadError => 'We couldn\'t load this team.';

  @override
  String get teamTabSchedule => 'Schedule';

  @override
  String get teamTabRankings => 'Rankings';

  @override
  String get teamTabMembers => 'Members';

  @override
  String get teamScheduleUpcoming => 'Upcoming';

  @override
  String get teamSchedulePast => 'Past';

  @override
  String get teamScheduleEmptyUpcoming => 'The team has no upcoming events.';

  @override
  String get teamScheduleEmptyPast => 'The team has no past events.';

  @override
  String get teamScheduleLoadError => 'The team\'s events could not be loaded.';

  @override
  String get teamRankingsEmpty => 'No ranking yet for this selection.';

  @override
  String get teamRankingsLoadError => 'The ranking could not be loaded.';

  @override
  String get teamRankingsOff =>
      'Player ranking is not turned on for this team.';

  @override
  String get teamRankingPeriod => 'Period';

  @override
  String get teamRankingMatchType => 'Match type';

  @override
  String get teamRankingAllMatches => 'All';

  @override
  String teamRankingRecord(int wins, int losses) {
    return '${wins}W - ${losses}L';
  }

  @override
  String teamRankingPoints(int points) {
    return '$points pts';
  }

  @override
  String teamRankingUp(int places) {
    return 'Up $places';
  }

  @override
  String teamRankingDown(int places) {
    return 'Down $places';
  }

  @override
  String teamRankingRank(int rank) {
    return 'Rank $rank';
  }

  @override
  String get teamMembersShowInactive => 'Show deactivated members';

  @override
  String get teamMemberInactive => 'Deactivated';

  @override
  String get teamMemberActions => 'Member actions';

  @override
  String get teamMemberEditRoles => 'Edit roles';

  @override
  String get teamMemberDeactivate => 'Deactivate';

  @override
  String get teamMemberReactivate => 'Reactivate';

  @override
  String get teamMemberRemove => 'Remove from team';

  @override
  String teamMemberRolesTitle(String name) {
    return 'Roles of $name';
  }

  @override
  String get teamMemberRolesNeedOne => 'Choose at least one role.';

  @override
  String get teamMemberOnlyCaptain =>
      'A team needs a captain. Make someone else a captain first.';

  @override
  String get teamMemberSave => 'Save';

  @override
  String get teamMemberYes => 'Yes';

  @override
  String get teamMemberCancel => 'Cancel';

  @override
  String teamMemberDeactivateTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String get teamMemberDeactivateText =>
      'They stay in the team but are left out of new events.';

  @override
  String teamMemberReactivateTitle(String name) {
    return 'Reactivate $name?';
  }

  @override
  String get teamMemberReactivateText =>
      'They will be part of new events again.';

  @override
  String teamMemberRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get teamMemberRemoveText =>
      'They are taken out of the team and its upcoming events.';

  @override
  String get teamMemberChangeFailed =>
      'The change could not be saved. Please try again.';

  @override
  String get teamAddMembers => 'Add members';

  @override
  String get teamAddMembersTitle => 'Add members';

  @override
  String get teamAddMembersHint => 'Search for people and choose their roles.';

  @override
  String get teamAddMembersSave => 'Add to team';

  @override
  String get teamAddMembersFailed =>
      'The members could not be added. Please try again.';

  @override
  String get teamAddMembersDone => 'Members added.';

  @override
  String get teamAddMembersEmpty => 'No one found.';

  @override
  String get teamAddMembersLoadError => 'The search failed.';

  @override
  String get teamRoleCaptain => 'Captain';

  @override
  String get teamRolePlayer => 'Player';

  @override
  String get teamRoleCoach => 'Coach';

  @override
  String get teamDetailsSports => 'Sports';

  @override
  String get teamDetailsType => 'Type';

  @override
  String get createTeamTitle => 'New team';

  @override
  String get createTeamNameLabel => 'Team name';

  @override
  String get createTeamNameRequired => 'Enter a team name.';

  @override
  String get createTeamTypeLabel => 'Team type';

  @override
  String get createTeamTypeRequired => 'Choose a team type.';

  @override
  String get createTeamSportsLabel => 'Sports';

  @override
  String get createTeamSportRequired => 'Choose at least one sport.';

  @override
  String get createTeamRankingLabel => 'Player ranking';

  @override
  String get createTeamRankingHint =>
      'Rank players by their results in team events.';

  @override
  String get createTeamParticipatingLabel => 'You take part as';

  @override
  String get createTeamParticipatingHint =>
      'You are the team captain. You can also play or coach.';

  @override
  String get createTeamMembersTitle => 'Add team members';

  @override
  String get createTeamMembersHint =>
      'Search people and choose their role in the team.';

  @override
  String get createTeamMembersSearchHint => 'Search people';

  @override
  String get createTeamMembersEmpty => 'No people found.';

  @override
  String get createTeamSubmitAction => 'Create team';

  @override
  String get createTeamFailed => 'We couldn\'t create the team. Try again.';

  @override
  String get createTeamCreated => 'Team created.';

  @override
  String get createTeamChoiceTitle => 'Is this a team event?';

  @override
  String get createTeamChoiceNonTeam => 'Not a team event';

  @override
  String get createTeamChoiceNonTeamHint => 'Invite players yourself.';

  @override
  String get createTeamChoiceTeam => 'Team event';

  @override
  String get createTeamChoiceTeamHint => 'Invite members of one of your teams.';

  @override
  String get createTeamSelectTitle => 'Which team?';

  @override
  String get createTeamSelectRequired => 'Choose a team.';

  @override
  String get createTeamSelectEmpty =>
      'You are not the captain of a team that plays this sport.';

  @override
  String get createTeamSelectCreate => 'Create a team';

  @override
  String get createReviewTeam => 'Team';

  @override
  String get createRankingLabel => 'Count towards team ranking';

  @override
  String get createDynamicsTitle => 'Who are you playing?';

  @override
  String get createDynamicsWithin => 'Within my team';

  @override
  String get createDynamicsWithinHint =>
      'Members of your team play each other.';

  @override
  String get createDynamicsOpponent => 'Another team';

  @override
  String get createDynamicsOpponentHint => 'Choose a team that is in the app.';

  @override
  String get createDynamicsNamed => 'A team by name';

  @override
  String get createDynamicsNamedHint =>
      'Enter the name of a team that is not in the app.';

  @override
  String get createOpponentNameLabel => 'Opponent team name';

  @override
  String get createOpponentNameRequired => 'Enter the opponent team name.';

  @override
  String get createOpponentTitle => 'Choose the opponent team';

  @override
  String get createOpponentSearchHint => 'Search teams';

  @override
  String get createOpponentRequired => 'Choose the opponent team.';

  @override
  String get createOpponentEmpty => 'No teams found.';

  @override
  String get createHomeAwayTitle => 'Which team is home?';

  @override
  String get createHomeTeamLabel => 'Home team';

  @override
  String get createAwayTeamLabel => 'Visiting team';

  @override
  String get createSwapTeams => 'Swap home and visiting team';

  @override
  String get createHomeNotDecided => 'Home team not decided yet';

  @override
  String get createReviewOpponent => 'Opponent';

  @override
  String get createOpponentSideNote =>
      'The opponent team assigns its own players.';

  @override
  String get createLessonAssignTitle => 'Who is the lesson for?';

  @override
  String get createLessonAssignOne => 'One player';

  @override
  String get createLessonAssignOneHint => 'Choose the player now.';

  @override
  String get createLessonAssignMany => 'Several players';

  @override
  String get createLessonAssignManyHint =>
      'Invite players; the first to accept gets the lesson.';

  @override
  String get createSinglePlayerTitle => 'Choose the player';

  @override
  String get createCoachesMaxHint => 'Choose up to two coaches.';

  @override
  String get eventManageAction => 'Manage event';

  @override
  String get eventManageTitle => 'Manage event';

  @override
  String get eventManageSettings => 'Settings';

  @override
  String get eventManageSettingsHint => 'Response deadline, limits and scoring';

  @override
  String get eventManagePlayers => 'People';

  @override
  String get eventManagePlayersHint =>
      'Add, confirm or remove players and coaches';

  @override
  String get eventManageSchedule => 'Date, time and venue';

  @override
  String get eventManageScheduleHint =>
      'Move the event to another time or place';

  @override
  String get eventManageScores => 'Scores';

  @override
  String get eventManageScoresHint =>
      'Enter or correct the results of the matches';

  @override
  String get eventManageLocked => 'This event can no longer be changed.';

  @override
  String get eventManageScheduleUnsupported =>
      'Changing the time of this event is not available in this build yet.';

  @override
  String get eventManageSaved => 'Changes saved.';

  @override
  String get eventManageFailed => 'We couldn\'t save the changes. Try again.';

  @override
  String get eventManageSave => 'Save';

  @override
  String get eventSettingsTitle => 'Event settings';

  @override
  String get eventPlayersTitle => 'People in this event';

  @override
  String get eventGroupConfirmed => 'Confirmed';

  @override
  String get eventGroupToBeConfirmed => 'To be confirmed';

  @override
  String get eventGroupWaitlisted => 'Waiting list';

  @override
  String get eventGroupInvited => 'Invited';

  @override
  String get eventGroupDeclined => 'Declined';

  @override
  String get eventGroupOther => 'Others';

  @override
  String get eventGroupCoaches => 'Coaches';

  @override
  String get eventAddPlayers => 'Add players';

  @override
  String get eventAddCoaches => 'Add coaches';

  @override
  String get eventRemoveSelected => 'Remove selected';

  @override
  String get eventConfirmSelected => 'Confirm selected';

  @override
  String get eventRemoveTitle => 'Remove from the event?';

  @override
  String get eventRemoveMessage => 'They will no longer be part of this event.';

  @override
  String get eventNoParticipants => 'No one yet.';

  @override
  String get eventAddPeopleTitle => 'Add people';

  @override
  String get eventAddPeopleAction => 'Add selected';

  @override
  String get eventAddPeopleEmpty => 'There is no one left to add.';

  @override
  String get eventScoresTitle => 'Scores';

  @override
  String get eventScoreEntryTitle => 'Enter score';

  @override
  String eventScoreSet(int number) {
    return 'Set $number';
  }

  @override
  String get eventScoreSingle => 'Score';

  @override
  String get eventScoreUnfinished => 'Match not finished';

  @override
  String get eventScoreSave => 'Save score';

  @override
  String get eventScoreErrorNone => 'Enter a score.';

  @override
  String get eventScoreErrorIncomplete => 'Enter both scores of a set.';

  @override
  String get eventScoreErrorNumber => 'Scores are whole numbers.';

  @override
  String get eventScoreNone => 'No score yet';

  @override
  String get eventScoreUnfinishedTag => 'Unfinished';

  @override
  String get eventScoreClearUnfinished => 'Remove unfinished status';

  @override
  String eventScoreWinning(int top, int bottom) {
    return 'Sets won: $top – $bottom';
  }

  @override
  String get eventScoreTop => 'Top side';

  @override
  String get eventScoreBottom => 'Bottom side';

  @override
  String eventMatchNumber(int number) {
    return 'Match $number';
  }

  @override
  String get deviceBlockedTitle => 'Security Warning';

  @override
  String get deviceBlockedMessage =>
      'This device appears to be rooted or jailbroken. That exposes your device to malware and keyloggers.\n\nWe do not recommend using our app on such a device. It is strongly recommended that you access your account on another device or reset this device to its original settings.';

  @override
  String get downtimeFallbackTitle => 'We\'ll be right back';

  @override
  String get downtimeFallbackMessage =>
      'The service is unavailable right now. Please try again in a little while.';

  @override
  String downtimeBackBefore(String time, String date) {
    return 'We will be back before $time $date.';
  }

  @override
  String get downtimeCheckAgain => 'Check again';

  @override
  String get accessNeedsSubscription => 'This feature needs a subscription.';

  @override
  String get accessBlocked => 'This isn\'t available right now.';

  @override
  String get notificationViewAction => 'View';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsHint =>
      'Push notifications and text messages';

  @override
  String get settingsReminders => 'Event reminders';

  @override
  String get settingsRemindersHint => 'When to be reminded before an event';

  @override
  String get settingsRate => 'Rate the app';

  @override
  String get locationsTitle => 'Locations';

  @override
  String get locationsSearchHint => 'Search venues';

  @override
  String get locationsNearby => 'Nearby';

  @override
  String get locationsFavourites => 'Favourites';

  @override
  String get locationsNearYou => 'Near your current location';

  @override
  String get locationsNoLocation =>
      'Turn on location to see the venues closest to you.';

  @override
  String get locationsEnable => 'Enable location';

  @override
  String get locationsOpenSettings => 'Open settings';

  @override
  String get locationsLocating => 'Finding your location';

  @override
  String get locationsFilter => 'Distance filter';

  @override
  String locationsDistanceValue(int distance, String unit) {
    return 'Within $distance $unit';
  }

  @override
  String get locationsDistanceHint =>
      'Show venues within this distance of you.';

  @override
  String get locationsApply => 'Apply';

  @override
  String get locationsReset => 'Reset to default';

  @override
  String get locationsDefaultUnit => 'mi';

  @override
  String get venueCourts => 'Courts';

  @override
  String get venueNoCourts => 'No courts are listed for this venue.';

  @override
  String get venueDirections => 'Directions';

  @override
  String get venueMembership => 'Membership required';

  @override
  String get venueLoadError => 'The venue could not be loaded.';

  @override
  String get venueCourtIndoor => 'Indoor';

  @override
  String get venueCourtOutdoor => 'Outdoor';

  @override
  String get settingsLocations => 'Locations';

  @override
  String get settingsLocationsHint => 'Find venues and manage your favourites';

  @override
  String get subscriptionTitle => 'Racketmates Pro';

  @override
  String get subscriptionBenefit1Title => 'Manage teams and events';

  @override
  String get subscriptionBenefit1Text =>
      'Create teams, run events and keep everyone in the loop.';

  @override
  String get subscriptionBenefit2Title => 'Grow your community';

  @override
  String get subscriptionBenefit2Text =>
      'Invite players, coaches and friends and build up your club.';

  @override
  String get subscriptionBenefit3Title => 'Priority support';

  @override
  String get subscriptionBenefit3Text =>
      'Chat with the Racketmates team whenever you need help.';

  @override
  String get subscriptionMonthly => 'Monthly';

  @override
  String get subscriptionYearly => 'Yearly';

  @override
  String subscriptionPerMonth(String price) {
    return '$price/month';
  }

  @override
  String subscriptionSave(int percent) {
    return 'Save $percent%';
  }

  @override
  String get subscriptionUpgrade => 'Upgrade now';

  @override
  String get subscriptionRestore => 'Restore purchases';

  @override
  String get subscriptionRedeem => 'Redeem code';

  @override
  String get subscriptionTerms => 'Terms of service';

  @override
  String get subscriptionPrivacy => 'Privacy policy';

  @override
  String get subscriptionPaymentAndroid =>
      'Payment is charged to your Google Play account. The subscription renews automatically until you cancel it in Google Play.';

  @override
  String get subscriptionPaymentIos =>
      'Payment is charged to your Apple ID account. The subscription renews automatically until you cancel it in your account settings.';

  @override
  String get subscriptionUnavailable =>
      'Subscriptions are not available on this device or build.';

  @override
  String get subscriptionPending =>
      'Your purchase is waiting for approval. Access starts once it is approved.';

  @override
  String get subscriptionFailed =>
      'The purchase did not complete. Please try again.';

  @override
  String get subscriptionLinkFailed =>
      'Your purchase went through but could not be activated yet. We will try again; if access does not appear, restore your purchases or contact support.';

  @override
  String get subscriptionCancelled => 'The purchase was cancelled.';

  @override
  String get subscriptionRestored => 'Subscription restored.';

  @override
  String get subscriptionNothingToRestore =>
      'No active subscription was found for this store account.';

  @override
  String get subscriptionRestoreFailed => 'Restoring failed. Please try again.';

  @override
  String get subscriptionSuccessTitle => 'You are all set';

  @override
  String get subscriptionSuccessText =>
      'Thank you for subscribing. All features are unlocked.';

  @override
  String get subscriptionSuccessContinue => 'Continue';

  @override
  String get subscriptionClose => 'Close';

  @override
  String get settingsSubscription => 'Subscription';

  @override
  String get settingsSubscriptionManage => 'Manage in the store';

  @override
  String get settingsSubscriptionPlans => 'See plans and upgrade';

  @override
  String get accessUpgradeAction => 'See plans';

  @override
  String get settingsSupport => 'Chat with support';

  @override
  String get settingsSupportHint => 'Ask the Racketmates team for help';

  @override
  String get settingsLogout => 'Log out';

  @override
  String get settingsLogoutTitle => 'Log out?';

  @override
  String get settingsLogoutMessage =>
      'You will need to sign in again to use the app.';

  @override
  String get settingsLogoutConfirm => 'Log out';

  @override
  String get settingsLoggingOut => 'Logging out…';

  @override
  String get settingsSubscriptionPremium => 'Premium';

  @override
  String settingsSubscriptionTrial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Free trial: $count days left',
      one: 'Free trial: 1 day left',
    );
    return '$_temp0';
  }

  @override
  String get settingsSubscriptionFree => 'Free';

  @override
  String get homeSettingsAction => 'Settings';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsPush => 'Push notifications';

  @override
  String get notificationsPushOn => 'On';

  @override
  String get notificationsPushOff => 'Off';

  @override
  String get notificationsPushOffHint =>
      'Turn on notifications for this app in your device settings to hear about invitations and changes to your events.';

  @override
  String get notificationsPushNotAsked =>
      'Allow notifications to hear about invitations and changes to your events.';

  @override
  String get notificationsAllow => 'Allow notifications';

  @override
  String get notificationsOpenSettings => 'Open settings';

  @override
  String get notificationsPushUnavailable =>
      'Push notifications are not available on this build.';

  @override
  String get notificationsText => 'Text messages';

  @override
  String get notificationsTextHint => 'Receive event updates by text message.';

  @override
  String get notificationsSaved => 'Notification settings updated.';

  @override
  String get notificationsFailed =>
      'We couldn\'t update your notification settings.';

  @override
  String get remindersTitle => 'Event reminders';

  @override
  String get remindersHint =>
      'You are reminded this long before each event you take part in.';

  @override
  String get remindersEmpty => 'You have no reminders yet.';

  @override
  String get remindersAdd => 'Add a reminder';

  @override
  String get remindersLoadError => 'We couldn\'t load your reminders.';

  @override
  String get remindersFailed => 'We couldn\'t update your reminders.';

  @override
  String get reminderRemove => 'Remove reminder';

  @override
  String get reminderUnitMinutes => 'Minutes';

  @override
  String get reminderUnitHours => 'Hours';

  @override
  String get reminderUnitDays => 'Days';

  @override
  String get reminderValueLabel => 'How long before';

  @override
  String reminderMinutesBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes before',
      one: '1 minute before',
    );
    return '$_temp0';
  }

  @override
  String reminderHoursBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours before',
      one: '1 hour before',
    );
    return '$_temp0';
  }

  @override
  String reminderDaysBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days before',
      one: '1 day before',
    );
    return '$_temp0';
  }
}
