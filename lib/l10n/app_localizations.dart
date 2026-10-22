import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Offline fallback screen-reader label for loading indicators. User-facing copy is server-driven; ARB only holds fallbacks.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loadingLabel;

  /// Placeholder until the real welcome screen is migrated; offline fallback only.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcomePlaceholder;

  /// Placeholder until the real home screen is migrated; offline fallback only.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homePlaceholder;

  /// No description provided for @signOutAction.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutAction;

  /// No description provided for @appUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'A new version is available'**
  String get appUpdateTitle;

  /// No description provided for @appUpdateAction.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get appUpdateAction;

  /// No description provided for @appUpdateLaterAction.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get appUpdateLaterAction;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Racketmates'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Organize games, teams and events in one place.'**
  String get welcomeSubtitle;

  /// No description provided for @signInAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInAction;

  /// No description provided for @signUpAction.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUpAction;

  /// No description provided for @phoneEntrySignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get phoneEntrySignInTitle;

  /// No description provided for @phoneEntrySignUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get phoneEntrySignUpTitle;

  /// No description provided for @phoneEntryDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number and we will text you a verification code.'**
  String get phoneEntryDescription;

  /// No description provided for @mobileNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileNumberLabel;

  /// No description provided for @countryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryLabel;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @phoneRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number.'**
  String get phoneRequiredError;

  /// No description provided for @phoneInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid mobile number.'**
  String get phoneInvalidError;

  /// No description provided for @genericErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericErrorMessage;

  /// No description provided for @networkErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get networkErrorMessage;

  /// No description provided for @backAction.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backAction;

  /// No description provided for @closeAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeAction;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHint;

  /// No description provided for @countryPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select country'**
  String get countryPickerTitle;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get otpTitle;

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {number}.'**
  String otpDescription(String number);

  /// No description provided for @otpChangeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get otpChangeNumber;

  /// No description provided for @otpInvalidCodeError.
  ///
  /// In en, this message translates to:
  /// **'That code is not valid. Try again.'**
  String get otpInvalidCodeError;

  /// No description provided for @otpResendAction.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResendAction;

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String otpResendIn(int seconds);

  /// No description provided for @otpCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get otpCodeLabel;

  /// No description provided for @notRegisteredTitle.
  ///
  /// In en, this message translates to:
  /// **'Number not registered'**
  String get notRegisteredTitle;

  /// No description provided for @notRegisteredMessage.
  ///
  /// In en, this message translates to:
  /// **'This number is not registered yet. Continue to create an account instead.'**
  String get notRegisteredMessage;

  /// No description provided for @alreadyRegisteredTitle.
  ///
  /// In en, this message translates to:
  /// **'Number already registered'**
  String get alreadyRegisteredTitle;

  /// No description provided for @alreadyRegisteredMessage.
  ///
  /// In en, this message translates to:
  /// **'This number already has an account. Continue to sign in instead.'**
  String get alreadyRegisteredMessage;

  /// No description provided for @signUpPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Sign-up is not available in this build yet.'**
  String get signUpPlaceholder;

  /// No description provided for @nextAction.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextAction;

  /// No description provided for @saveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveAction;

  /// No description provided for @skipForNowAction.
  ///
  /// In en, this message translates to:
  /// **'I\'ll do this later'**
  String get skipForNowAction;

  /// No description provided for @removeAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAction;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @signUpDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about you'**
  String get signUpDetailsTitle;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastNameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailLabel;

  /// No description provided for @firstNameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name.'**
  String get firstNameRequiredError;

  /// No description provided for @lastNameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name.'**
  String get lastNameRequiredError;

  /// No description provided for @emailInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get emailInvalidError;

  /// No description provided for @emailTakenError.
  ///
  /// In en, this message translates to:
  /// **'This email is already in use.'**
  String get emailTakenError;

  /// No description provided for @roleSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'How will you use Racketmates?'**
  String get roleSelectionTitle;

  /// No description provided for @rolePlayer.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get rolePlayer;

  /// No description provided for @roleCoach.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get roleCoach;

  /// No description provided for @roleParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get roleParent;

  /// No description provided for @roleRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Select at least one role.'**
  String get roleRequiredError;

  /// No description provided for @sportsPlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Which sports do you play?'**
  String get sportsPlayerTitle;

  /// No description provided for @sportsCoachTitle.
  ///
  /// In en, this message translates to:
  /// **'Which sports do you coach?'**
  String get sportsCoachTitle;

  /// No description provided for @sportBadminton.
  ///
  /// In en, this message translates to:
  /// **'Badminton'**
  String get sportBadminton;

  /// No description provided for @sportPadel.
  ///
  /// In en, this message translates to:
  /// **'Padel'**
  String get sportPadel;

  /// No description provided for @sportPickleball.
  ///
  /// In en, this message translates to:
  /// **'Pickleball'**
  String get sportPickleball;

  /// No description provided for @sportTennis.
  ///
  /// In en, this message translates to:
  /// **'Tennis'**
  String get sportTennis;

  /// No description provided for @sportRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Select at least one sport.'**
  String get sportRequiredError;

  /// No description provided for @kidsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your kids'**
  String get kidsTitle;

  /// No description provided for @addKidAction.
  ///
  /// In en, this message translates to:
  /// **'Add a kid'**
  String get addKidAction;

  /// No description provided for @kidsMaxReached.
  ///
  /// In en, this message translates to:
  /// **'You can add up to 2 kids.'**
  String get kidsMaxReached;

  /// No description provided for @kidFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a kid'**
  String get kidFormTitle;

  /// No description provided for @kidMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Kid\'s mobile number (optional)'**
  String get kidMobileLabel;

  /// No description provided for @kidMobileInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid mobile number.'**
  String get kidMobileInvalidError;

  /// No description provided for @kidMobileTakenError.
  ///
  /// In en, this message translates to:
  /// **'This number is already registered.'**
  String get kidMobileTakenError;

  /// No description provided for @creatingAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'Creating your account...'**
  String get creatingAccountMessage;

  /// No description provided for @profilePictureTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a profile picture'**
  String get profilePictureTitle;

  /// No description provided for @profilePictureHint.
  ///
  /// In en, this message translates to:
  /// **'Help others recognize you.'**
  String get profilePictureHint;

  /// No description provided for @takePhotoAction.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhotoAction;

  /// No description provided for @chooseFromGalleryAction.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGalleryAction;

  /// No description provided for @uploadPhotoAction.
  ///
  /// In en, this message translates to:
  /// **'Upload photo'**
  String get uploadPhotoAction;

  /// No description provided for @congratulationsTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get congratulationsTitle;

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}.'**
  String congratulationsGreeting(String name);

  /// No description provided for @goToHomeAction.
  ///
  /// In en, this message translates to:
  /// **'Take me to home'**
  String get goToHomeAction;

  /// No description provided for @addFirstEventAction.
  ///
  /// In en, this message translates to:
  /// **'Add my first event'**
  String get addFirstEventAction;

  /// No description provided for @profilePictureUploadError.
  ///
  /// In en, this message translates to:
  /// **'Could not upload the photo. Try again.'**
  String get profilePictureUploadError;

  /// Placeholder greeting until the real home screen is migrated.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String homeGreeting(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
