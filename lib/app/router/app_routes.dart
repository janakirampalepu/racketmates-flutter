abstract final class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const home = '/home';
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
  static const protected = {home};
}
