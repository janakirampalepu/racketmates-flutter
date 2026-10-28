import 'package:racketmates/common/create_event/event_draft.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const deviceBlocked = '/device-blocked';
  static const downtime = '/downtime';
  static const welcome = '/welcome';
  static const home = '/home';
  static const schedule = '/schedule';
  static const drafts = '/drafts';
  static const chat = '/chat';
  static const chatChannel = '/chat/channel';
  static const chatChannelDetails = '/chat/channel/details';
  static const locations = '/locations';
  static const chatNew = '/chat/new';
  static const subscription = '/subscription';
  static const subscriptionSuccess = '/subscription/success';
  static const teams = '/teams';
  static const event = '/event';
  static const places = '/places';
  static const settings = '/settings';
  static const notificationSettings = '/settings/notifications';
  static const eventReminders = '/settings/reminders';
  static const profile = '/settings/profile';
  static const kids = '/settings/kids';
  static const kidEdit = '/settings/kids/edit';
  static const changePhone = '/settings/phone';
  static const shareWithFriends = '/settings/share';
  static const contactUs = '/settings/contact';
  static const deleteAccount = '/settings/delete-account';
  static const team = '/team';
  static const createTeam = '/create-team';
  static const createTeamMembers = '/create-team/members';
  static const createEvent = '/create-event';
  static const createEventSport = '/create-event/sport';
  static const createEventTeamChoice = '/create-event/team-choice';
  static const createEventTeamSelect = '/create-event/team-select';
  static const createEventTeamDynamics = '/create-event/team-dynamics';
  static const createEventOpponentSelect = '/create-event/opponent-select';
  static const createEventHomeAway = '/create-event/home-away';
  static const createEventSettings = '/create-event/settings';
  static const createEventCoaches = '/create-event/coaches';
  static const createEventPlayers = '/create-event/players';
  static const createEventMatches = '/create-event/matches';
  static const createEventRoundRobinFormat = '/create-event/round-robin-format';
  static const createEventAssignType = '/create-event/assign-type';
  static const createEventAssignPlayers = '/create-event/assign-players';
  static const createEventSlotPicker = '/create-event/assign-players/pick';
  static const createEventWhenWhere = '/create-event/when-where';
  static const createEventInviteSettings = '/create-event/invite-settings';
  static const createEventReview = '/create-event/review';
  static const createEventSuccess = '/create-event/success';

  /// Route of a wizard step (see `createEventStepsFor`).
  /// The wizard step a location belongs to (null elsewhere).
  static CreateEventStep? stepForRoute(String location) {
    for (final step in CreateEventStep.values) {
      if (routeForStep(step) == location) return step;
    }
    return null;
  }

  static String routeForStep(CreateEventStep step) => switch (step) {
    CreateEventStep.type => createEvent,
    CreateEventStep.sport => createEventSport,
    CreateEventStep.teamChoice => createEventTeamChoice,
    CreateEventStep.teamSelect => createEventTeamSelect,
    CreateEventStep.teamDynamics => createEventTeamDynamics,
    CreateEventStep.opponentSelect => createEventOpponentSelect,
    CreateEventStep.homeAway => createEventHomeAway,
    CreateEventStep.settings => createEventSettings,
    CreateEventStep.coaches => createEventCoaches,
    CreateEventStep.players => createEventPlayers,
    CreateEventStep.matches => createEventMatches,
    CreateEventStep.roundRobinFormat => createEventRoundRobinFormat,
    CreateEventStep.assignType => createEventAssignType,
    CreateEventStep.assignPlayers => createEventAssignPlayers,
    CreateEventStep.whenWhere => createEventWhenWhere,
    CreateEventStep.inviteSettings => createEventInviteSettings,
    CreateEventStep.review => createEventReview,
  };

  static bool isCreateEvent(String location) =>
      location == createEvent || location.startsWith('$createEvent/');

  /// Place picker, optionally filtered by sport (`st_tennis`).
  static String placesFor({String? sport}) => sport == null
      ? places
      : Uri(path: places, queryParameters: {'sport': sport}).toString();

  /// Player picker for one slot of one match.
  static String slotPickerFor({
    required int match,
    required String side,
    required String position,
  }) => Uri(
    path: createEventSlotPicker,
    queryParameters: {'match': '$match', 'side': side, 'position': position},
  ).toString();

  static String createEventSuccessFor(int? eventId) => eventId == null
      ? createEventSuccess
      : Uri(
          path: createEventSuccess,
          queryParameters: {'eventId': '$eventId'},
        ).toString();

  static String eventFor(int id) => '$event/$id';

  /// One venue's page.
  static String venueFor(int id) => '$locations/$id';

  /// One chat conversation, by its Sendbird channel url.
  static String chatChannelFor(String url) =>
      Uri(path: chatChannel, queryParameters: {'url': url}).toString();

  /// That conversation's details screen.
  static String chatChannelDetailsFor(String url) =>
      Uri(path: chatChannelDetails, queryParameters: {'url': url}).toString();
  static String eventManageFor(int id) => '$event/$id/manage';
  static String eventManageSettingsFor(int id) => '$event/$id/manage/settings';
  static String eventManagePlayersFor(int id) => '$event/$id/manage/players';
  static String eventManageScheduleFor(int id) => '$event/$id/manage/schedule';
  static String eventManageScheduleMatchFor(int id, int matchId) =>
      '$event/$id/manage/schedule/$matchId';
  static String eventManagePairsFor(int id) => '$event/$id/manage/pairs';
  static String eventManageRoundsFor(int id) => '$event/$id/manage/rounds';
  static String eventManageScoresFor(int id) => '$event/$id/manage/scores';
  static String eventManageScoreFor(int id, int matchId) =>
      '$event/$id/manage/scores/$matchId';

  /// Add people to an event: players (or attendees), or coaches.
  static String eventManageAddPeopleFor(int id, {required bool coaches}) => Uri(
    path: '$event/$id/manage/add-people',
    queryParameters: {'role': coaches ? 'coach' : 'player'},
  ).toString();
  static String roleSportsFor(String role) => '$settings/sports/$role';

  /// Add (no id) or edit a kid.
  static String kidEditFor([int? id]) => Uri(
    path: kidEdit,
    queryParameters: id == null ? null : {'id': '$id'},
  ).toString();

  static String teamFor(int id) => '$team/$id';
  static String teamAddMembersFor(int id) => '$team/$id/add-members';
  static String teamSettingsFor(int id) => '$team/$id/settings';
  static String teamScheduleFor(int id) => '$team/$id/schedule';
  static String teamChatFor(int id) => '$team/$id/chat';
  static String teamRankingsFor(int id) => '$team/$id/rankings';
  static String teamMembersFor(int id) => '$team/$id/members';
  static const appUpdate = '/app-update';
  static const phoneEntry = '/phone-entry';
  static const countryPicker = '/country-picker';
  static const otp = '/otp';
  static const signUp = '/sign-up';
  static const roleSelection = '/sign-up/roles';
  static const sportsSelection = '/sign-up/sports';
  static const kidsList = '/sign-up/kids';
  static const kidForm = '/sign-up/kid';
  static const profilePicture = '/sign-up/profile-picture';
  static const congratulations = '/sign-up/congratulations';

  static String sports(String role) => '$sportsSelection/$role';

  /// Query parameters instead of route `extra` (which go_router drops when it
  /// rebuilds routes).
  static String phoneEntryFor(String mode) => '$phoneEntry?mode=$mode';

  static String kidFormFor({int? index, bool fromList = false}) {
    final params = {
      if (index != null) 'index': '$index',
      if (fromList) 'list': '1',
    };
    return Uri(
      path: kidForm,
      queryParameters: params.isEmpty ? null : params,
    ).toString();
  }

  /// Pre-login routes a signed-in user is redirected away from.
  static const preLogin = {welcome, phoneEntry, countryPicker, otp, signUp};

  /// Sign-up steps; they stay reachable while a sign-up is in progress even
  /// though a session already exists (account created / resumed).
  static bool isSignUpStep(String location) =>
      location == signUp || location.startsWith('$signUp/');

  /// Steps that need the session created at the end of sign-up.
  static const afterAccountCreated = {profilePicture, congratulations};

  /// Routes that need a signed-in session.
  static bool isProtected(String location) =>
      const {home, schedule, chat, teams}.contains(location) ||
      location.startsWith('$chat/') ||
      location == locations ||
      location.startsWith('$locations/') ||
      location == drafts ||
      location == subscription ||
      location.startsWith('$subscription/') ||
      location.startsWith('$event/') ||
      location.startsWith('$team/') ||
      location == settings ||
      location.startsWith('$settings/') ||
      location == createTeam ||
      location == createTeamMembers ||
      location == places ||
      isCreateEvent(location);
}
