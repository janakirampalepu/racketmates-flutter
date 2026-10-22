abstract final class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const home = '/home';
  static const schedule = '/schedule';
  static const chat = '/chat';
  static const teams = '/teams';
  static const event = '/event';
  static const places = '/places';
  static const createEvent = '/create-event';
  static const createEventSport = '/create-event/sport';
  static const createEventSettings = '/create-event/settings';
  static const createEventPlayers = '/create-event/players';
  static const createEventWhenWhere = '/create-event/when-where';
  static const createEventInviteSettings = '/create-event/invite-settings';
  static const createEventReview = '/create-event/review';
  static const createEventSuccess = '/create-event/success';

  static bool isCreateEvent(String location) =>
      location == createEvent || location.startsWith('$createEvent/');

  /// Place picker, optionally filtered by sport (`st_tennis`).
  static String placesFor({String? sport}) => sport == null
      ? places
      : Uri(path: places, queryParameters: {'sport': sport}).toString();

  static String createEventSuccessFor(int? eventId) => eventId == null
      ? createEventSuccess
      : Uri(
          path: createEventSuccess,
          queryParameters: {'eventId': '$eventId'},
        ).toString();

  static String eventFor(int id) => '$event/$id';
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
      location.startsWith('$event/') ||
      location == places ||
      isCreateEvent(location);
}
