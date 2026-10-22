/// Appium identifiers. `sign_in_button` matches the native iOS identifier;
/// `sign_up_button` has no native iOS equivalent (align with the Appium suite).
abstract final class WelcomeTestIds {
  static const root = 'welcome_screen';
  static const title = 'appLanding_title';
  static const subtitle = 'appLanding_description';
  static const signInButton = 'sign_in_button';
  static const signUpButton = 'sign_up_button';
}
