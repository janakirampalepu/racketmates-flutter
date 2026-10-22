abstract final class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const home = '/home';
  static const appUpdate = '/app-update';

  /// Routes that need a signed-in session.
  static const protected = {home};
}
