abstract final class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const home = '/home';
  static const appUpdate = '/app-update';
  static const phoneEntry = '/phone-entry';
  static const countryPicker = '/country-picker';
  static const otp = '/otp';
  static const signUp = '/sign-up';

  /// Pre-login routes a signed-in user is redirected away from.
  static const preLogin = {welcome, phoneEntry, countryPicker, otp, signUp};

  /// Routes that need a signed-in session.
  static const protected = {home};
}
