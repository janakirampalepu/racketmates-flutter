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
}
