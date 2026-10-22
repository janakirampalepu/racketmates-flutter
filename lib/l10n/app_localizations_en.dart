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
}
