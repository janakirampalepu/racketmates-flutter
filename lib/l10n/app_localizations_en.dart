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
}
