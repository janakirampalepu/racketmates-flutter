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

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get navSchedule;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navTeams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get navTeams;

  /// No description provided for @homePendingActions.
  ///
  /// In en, this message translates to:
  /// **'Pending actions'**
  String get homePendingActions;

  /// No description provided for @homeUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get homeUpcoming;

  /// No description provided for @homeLatestUpdates.
  ///
  /// In en, this message translates to:
  /// **'Latest updates'**
  String get homeLatestUpdates;

  /// No description provided for @homeActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get homeActivity;

  /// No description provided for @homePast.
  ///
  /// In en, this message translates to:
  /// **'Recent games'**
  String get homePast;

  /// No description provided for @seeAllAction.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAllAction;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retryAction;

  /// No description provided for @emptyPendingActions.
  ///
  /// In en, this message translates to:
  /// **'Nothing needs your attention.'**
  String get emptyPendingActions;

  /// No description provided for @emptyUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events.'**
  String get emptyUpcoming;

  /// No description provided for @emptyLatestUpdates.
  ///
  /// In en, this message translates to:
  /// **'No updates yet.'**
  String get emptyLatestUpdates;

  /// No description provided for @emptyActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity yet.'**
  String get emptyActivity;

  /// No description provided for @emptyPast.
  ///
  /// In en, this message translates to:
  /// **'No past events.'**
  String get emptyPast;

  /// No description provided for @sectionLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this section.'**
  String get sectionLoadError;

  /// No description provided for @statWins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get statWins;

  /// No description provided for @statLosses.
  ///
  /// In en, this message translates to:
  /// **'Losses'**
  String get statLosses;

  /// No description provided for @statEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get statEvents;

  /// No description provided for @statHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get statHours;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleTitle;

  /// No description provided for @tabUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get tabUpcoming;

  /// No description provided for @tabPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get tabPast;

  /// No description provided for @scheduleEmptyUpcoming.
  ///
  /// In en, this message translates to:
  /// **'You have no upcoming events.'**
  String get scheduleEmptyUpcoming;

  /// No description provided for @scheduleEmptyPast.
  ///
  /// In en, this message translates to:
  /// **'You have no past events.'**
  String get scheduleEmptyPast;

  /// No description provided for @scheduleLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load events.'**
  String get scheduleLoadError;

  /// No description provided for @eventDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Event details'**
  String get eventDetailsTitle;

  /// No description provided for @eventWhenLabel.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get eventWhenLabel;

  /// No description provided for @eventWhereLabel.
  ///
  /// In en, this message translates to:
  /// **'Where'**
  String get eventWhereLabel;

  /// No description provided for @eventStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get eventStatusLabel;

  /// No description provided for @eventParticipantsLabel.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get eventParticipantsLabel;

  /// No description provided for @eventNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get eventNotesLabel;

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'{count} spots left'**
  String eventSpotsLeft(int count);

  /// No description provided for @eventLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this event.'**
  String get eventLoadError;

  /// No description provided for @eventNoPlayers.
  ///
  /// In en, this message translates to:
  /// **'No players yet.'**
  String get eventNoPlayers;

  /// No description provided for @eventYourStatus.
  ///
  /// In en, this message translates to:
  /// **'Your status'**
  String get eventYourStatus;

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String moreSuffix(int count);

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'This section is not available in this build yet.'**
  String get comingSoonMessage;

  /// No description provided for @unknownPlayer.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get unknownPlayer;

  /// No description provided for @rsvpAccept.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get rsvpAccept;

  /// No description provided for @rsvpDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get rsvpDecline;

  /// No description provided for @rsvpRejoin.
  ///
  /// In en, this message translates to:
  /// **'Rejoin'**
  String get rsvpRejoin;

  /// No description provided for @rsvpLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave event'**
  String get rsvpLeave;

  /// No description provided for @rsvpJoinWaitlist.
  ///
  /// In en, this message translates to:
  /// **'Join waitlist'**
  String get rsvpJoinWaitlist;

  /// No description provided for @rsvpEditResponse.
  ///
  /// In en, this message translates to:
  /// **'Edit response'**
  String get rsvpEditResponse;

  /// No description provided for @rsvpDeclineTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline this event?'**
  String get rsvpDeclineTitle;

  /// No description provided for @rsvpDeclineMessage.
  ///
  /// In en, this message translates to:
  /// **'The organizer will be told you cannot make it.'**
  String get rsvpDeclineMessage;

  /// No description provided for @rsvpLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this event?'**
  String get rsvpLeaveTitle;

  /// No description provided for @rsvpLeaveMessage.
  ///
  /// In en, this message translates to:
  /// **'You will be removed from the event.'**
  String get rsvpLeaveMessage;

  /// No description provided for @rsvpDone.
  ///
  /// In en, this message translates to:
  /// **'Your response was saved.'**
  String get rsvpDone;

  /// No description provided for @rsvpNeedsPicker.
  ///
  /// In en, this message translates to:
  /// **'Choosing between several times or partners is not available in this build yet.'**
  String get rsvpNeedsPicker;

  /// No description provided for @rsvpNeedsSubscription.
  ///
  /// In en, this message translates to:
  /// **'A subscription is required for this action.'**
  String get rsvpNeedsSubscription;

  /// No description provided for @rsvpActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update your response.'**
  String get rsvpActionFailed;

  /// No description provided for @cancelEventAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel event'**
  String get cancelEventAction;

  /// No description provided for @cancelEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this event?'**
  String get cancelEventTitle;

  /// No description provided for @cancelEventReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get cancelEventReasonLabel;

  /// No description provided for @cancelEventRemoveLabel.
  ///
  /// In en, this message translates to:
  /// **'Also remove it from the schedule'**
  String get cancelEventRemoveLabel;

  /// No description provided for @cancelEventConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel event'**
  String get cancelEventConfirm;

  /// No description provided for @cancelEventKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep event'**
  String get cancelEventKeep;

  /// No description provided for @cancelEventDone.
  ///
  /// In en, this message translates to:
  /// **'The event was cancelled.'**
  String get cancelEventDone;

  /// No description provided for @cancelEventFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel the event.'**
  String get cancelEventFailed;

  /// No description provided for @moreOptionsLabel.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptionsLabel;

  /// No description provided for @placePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a venue'**
  String get placePickerTitle;

  /// No description provided for @placeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search venues'**
  String get placeSearchHint;

  /// No description provided for @tabSearchPlaces.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tabSearchPlaces;

  /// No description provided for @tabFavouritePlaces.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get tabFavouritePlaces;

  /// No description provided for @placesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No venues found.'**
  String get placesEmpty;

  /// No description provided for @placesFavouritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have no favourite venues yet.'**
  String get placesFavouritesEmpty;

  /// No description provided for @placesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load venues.'**
  String get placesLoadError;

  /// No description provided for @addFavouriteAction.
  ///
  /// In en, this message translates to:
  /// **'Add to favourites'**
  String get addFavouriteAction;

  /// No description provided for @removeFavouriteAction.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get removeFavouriteAction;

  /// No description provided for @createEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Create event'**
  String get createEventTitle;

  /// No description provided for @createEventAction.
  ///
  /// In en, this message translates to:
  /// **'Create event'**
  String get createEventAction;

  /// No description provided for @createTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'What kind of event?'**
  String get createTypeTitle;

  /// No description provided for @createTypeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available in this build yet.'**
  String get createTypeUnavailable;

  /// No description provided for @createSportTitle.
  ///
  /// In en, this message translates to:
  /// **'Which sport?'**
  String get createSportTitle;

  /// No description provided for @createSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Event settings'**
  String get createSettingsTitle;

  /// No description provided for @createDeadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Response deadline'**
  String get createDeadlineLabel;

  /// No description provided for @createDeadlineHint.
  ///
  /// In en, this message translates to:
  /// **'Players must respond this long before the event.'**
  String get createDeadlineHint;

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'{count} before'**
  String createDeadlineValue(String count);

  /// No description provided for @createUnitHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get createUnitHours;

  /// No description provided for @createUnitDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get createUnitDays;

  /// No description provided for @createAllowManageLabel.
  ///
  /// In en, this message translates to:
  /// **'Let participants manage players'**
  String get createAllowManageLabel;

  /// No description provided for @createPlayersTitle.
  ///
  /// In en, this message translates to:
  /// **'Who is invited?'**
  String get createPlayersTitle;

  /// No description provided for @createPlayersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search players'**
  String get createPlayersSearchHint;

  /// No description provided for @createPlayersRequired.
  ///
  /// In en, this message translates to:
  /// **'Invite at least one player.'**
  String get createPlayersRequired;

  /// No description provided for @createPlayersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No players found.'**
  String get createPlayersEmpty;

  /// No description provided for @createPlayersLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load players.'**
  String get createPlayersLoadError;

  /// No description provided for @createPlayersSelected.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get createPlayersSelected;

  /// No description provided for @createWhenWhereTitle.
  ///
  /// In en, this message translates to:
  /// **'When and where'**
  String get createWhenWhereTitle;

  /// No description provided for @createVenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get createVenueLabel;

  /// No description provided for @createSelectVenue.
  ///
  /// In en, this message translates to:
  /// **'Select a venue'**
  String get createSelectVenue;

  /// No description provided for @createCourtsLabel.
  ///
  /// In en, this message translates to:
  /// **'Courts'**
  String get createCourtsLabel;

  /// No description provided for @createNoCourts.
  ///
  /// In en, this message translates to:
  /// **'This venue has no courts listed for this sport.'**
  String get createNoCourts;

  /// No description provided for @createDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get createDateLabel;

  /// No description provided for @createTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get createTimeLabel;

  /// No description provided for @createDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get createDurationLabel;

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String createDurationValue(int minutes);

  /// No description provided for @createNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get createNotesLabel;

  /// No description provided for @createVenueRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a venue.'**
  String get createVenueRequired;

  /// No description provided for @createStartRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a date and start time.'**
  String get createStartRequired;

  /// No description provided for @createStartInPast.
  ///
  /// In en, this message translates to:
  /// **'The start time must be in the future.'**
  String get createStartInPast;

  /// No description provided for @createInviteSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Player limits'**
  String get createInviteSettingsTitle;

  /// No description provided for @createMaxPlayersLabel.
  ///
  /// In en, this message translates to:
  /// **'Maximum players'**
  String get createMaxPlayersLabel;

  /// No description provided for @createRsvpLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Responses allowed'**
  String get createRsvpLimitLabel;

  /// No description provided for @createAcceptanceLabel.
  ///
  /// In en, this message translates to:
  /// **'How players are added'**
  String get createAcceptanceLabel;

  /// No description provided for @createAcceptOrderOfResponse.
  ///
  /// In en, this message translates to:
  /// **'First to respond'**
  String get createAcceptOrderOfResponse;

  /// No description provided for @createAcceptPickManually.
  ///
  /// In en, this message translates to:
  /// **'I pick manually'**
  String get createAcceptPickManually;

  /// No description provided for @createDecrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get createDecrease;

  /// No description provided for @createIncrease.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get createIncrease;

  /// No description provided for @createReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get createReviewTitle;

  /// No description provided for @createReviewType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get createReviewType;

  /// No description provided for @createReviewSport.
  ///
  /// In en, this message translates to:
  /// **'Sport'**
  String get createReviewSport;

  /// No description provided for @createReviewInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get createReviewInvited;

  /// No description provided for @createFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the event.'**
  String get createFailed;

  /// No description provided for @createdTitle.
  ///
  /// In en, this message translates to:
  /// **'Event created!'**
  String get createdTitle;

  /// No description provided for @createdGoToSchedule.
  ///
  /// In en, this message translates to:
  /// **'Go to schedule'**
  String get createdGoToSchedule;

  /// No description provided for @createdSeeDetails.
  ///
  /// In en, this message translates to:
  /// **'See event details'**
  String get createdSeeDetails;

  /// No description provided for @addEventAction.
  ///
  /// In en, this message translates to:
  /// **'Create event'**
  String get addEventAction;

  /// No description provided for @cancelWizardAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelWizardAction;

  /// No description provided for @createCoachesTitle.
  ///
  /// In en, this message translates to:
  /// **'Who is coaching?'**
  String get createCoachesTitle;

  /// No description provided for @createCoachesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search coaches'**
  String get createCoachesSearchHint;

  /// No description provided for @createCoachesRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one coach.'**
  String get createCoachesRequired;

  /// No description provided for @createCoachesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No coaches found.'**
  String get createCoachesEmpty;

  /// No description provided for @createPeopleTitle.
  ///
  /// In en, this message translates to:
  /// **'Who is coming?'**
  String get createPeopleTitle;

  /// No description provided for @createPeopleRequired.
  ///
  /// In en, this message translates to:
  /// **'Invite at least one person.'**
  String get createPeopleRequired;

  /// No description provided for @createReviewCoaches.
  ///
  /// In en, this message translates to:
  /// **'Coaches'**
  String get createReviewCoaches;

  /// No description provided for @createCourtCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of courts'**
  String get createCourtCountLabel;

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'Choose up to {count} courts.'**
  String createCourtsHint(int count);

  /// No description provided for @createScoringTitle.
  ///
  /// In en, this message translates to:
  /// **'Scoring format'**
  String get createScoringTitle;

  /// No description provided for @createScoringHint.
  ///
  /// In en, this message translates to:
  /// **'Choose how matches are scored.'**
  String get createScoringHint;

  /// No description provided for @createScoringLoadError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the scoring formats.'**
  String get createScoringLoadError;

  /// No description provided for @createScoreGamesToWin.
  ///
  /// In en, this message translates to:
  /// **'Minimum games to win'**
  String get createScoreGamesToWin;

  /// No description provided for @createScorePointsToWin.
  ///
  /// In en, this message translates to:
  /// **'Points to win'**
  String get createScorePointsToWin;

  /// No description provided for @createScoreMinimumPoints.
  ///
  /// In en, this message translates to:
  /// **'Minimum points to win'**
  String get createScoreMinimumPoints;

  /// No description provided for @createScoreTotalPoints.
  ///
  /// In en, this message translates to:
  /// **'Total points'**
  String get createScoreTotalPoints;

  /// No description provided for @createScoreDuration.
  ///
  /// In en, this message translates to:
  /// **'Round duration'**
  String get createScoreDuration;

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'{minutes} mins'**
  String createScoreMinutes(int minutes);

  /// No description provided for @createDecidingSetLabel.
  ///
  /// In en, this message translates to:
  /// **'If the last set is tied'**
  String get createDecidingSetLabel;

  /// No description provided for @createDecidingRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular set'**
  String get createDecidingRegular;

  /// No description provided for @createDecidingTieBreak.
  ///
  /// In en, this message translates to:
  /// **'Tie-break'**
  String get createDecidingTieBreak;

  /// No description provided for @createDecidingLater.
  ///
  /// In en, this message translates to:
  /// **'Decide later'**
  String get createDecidingLater;

  /// No description provided for @createLogResultsLabel.
  ///
  /// In en, this message translates to:
  /// **'Players can log results'**
  String get createLogResultsLabel;

  /// No description provided for @createMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get createMatchesTitle;

  /// No description provided for @createMatchesHint.
  ///
  /// In en, this message translates to:
  /// **'Add the matches you will play. You can leave singles or doubles open.'**
  String get createMatchesHint;

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'Match {number}'**
  String createMatchNumber(int number);

  /// No description provided for @createAddMatch.
  ///
  /// In en, this message translates to:
  /// **'Add another match'**
  String get createAddMatch;

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'Remove match {number}'**
  String createRemoveMatch(int number);

  /// No description provided for @createMatchSingles.
  ///
  /// In en, this message translates to:
  /// **'Singles'**
  String get createMatchSingles;

  /// No description provided for @createMatchDoubles.
  ///
  /// In en, this message translates to:
  /// **'Doubles'**
  String get createMatchDoubles;

  /// No description provided for @createMatchUndecided.
  ///
  /// In en, this message translates to:
  /// **'Decide later'**
  String get createMatchUndecided;

  /// No description provided for @createRoundRobinTitle.
  ///
  /// In en, this message translates to:
  /// **'Round robin'**
  String get createRoundRobinTitle;

  /// No description provided for @createRoundRobinCourtsHint.
  ///
  /// In en, this message translates to:
  /// **'How many courts will be used?'**
  String get createRoundRobinCourtsHint;

  /// No description provided for @createRoundRobinPlayersLabel.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get createRoundRobinPlayersLabel;

  /// No description provided for @createGameSingles.
  ///
  /// In en, this message translates to:
  /// **'Singles'**
  String get createGameSingles;

  /// No description provided for @createGameDoubles.
  ///
  /// In en, this message translates to:
  /// **'Doubles'**
  String get createGameDoubles;

  /// No description provided for @createGameBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get createGameBoth;

  /// No description provided for @createPartnersLabel.
  ///
  /// In en, this message translates to:
  /// **'Partners'**
  String get createPartnersLabel;

  /// No description provided for @createPartnersRotating.
  ///
  /// In en, this message translates to:
  /// **'Rotating'**
  String get createPartnersRotating;

  /// No description provided for @createPartnersRotatingHint.
  ///
  /// In en, this message translates to:
  /// **'Partners change every round'**
  String get createPartnersRotatingHint;

  /// No description provided for @createPartnersFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get createPartnersFixed;

  /// No description provided for @createPartnersFixedHint.
  ///
  /// In en, this message translates to:
  /// **'Pairs stay the same for the entire event'**
  String get createPartnersFixedHint;

  /// No description provided for @createRoundRobinFormatTitle.
  ///
  /// In en, this message translates to:
  /// **'Select the type of your round robin'**
  String get createRoundRobinFormatTitle;

  /// No description provided for @createFormatClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get createFormatClassic;

  /// No description provided for @createFormatKing.
  ///
  /// In en, this message translates to:
  /// **'King of the court'**
  String get createFormatKing;

  /// No description provided for @createFormatManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get createFormatManual;

  /// No description provided for @createFormatClassicSingles.
  ///
  /// In en, this message translates to:
  /// **'Rotate opponents each match, ensuring everyone competes against every player.'**
  String get createFormatClassicSingles;

  /// No description provided for @createFormatClassicRotating.
  ///
  /// In en, this message translates to:
  /// **'Rotate partners and opponents each match, ensuring everyone plays with and against everyone.'**
  String get createFormatClassicRotating;

  /// No description provided for @createFormatClassicFixed.
  ///
  /// In en, this message translates to:
  /// **'Keep the same partner throughout the event while rotating opponents each match.'**
  String get createFormatClassicFixed;

  /// No description provided for @createFormatKingSingles.
  ///
  /// In en, this message translates to:
  /// **'Players battle to stay on the main court, rotating challengers each round.'**
  String get createFormatKingSingles;

  /// No description provided for @createFormatKingRotating.
  ///
  /// In en, this message translates to:
  /// **'Rotate partners and opponents while players compete to hold the winning court.'**
  String get createFormatKingRotating;

  /// No description provided for @createFormatKingFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed pairs battle to stay on the main court, rotating challengers each round.'**
  String get createFormatKingFixed;

  /// No description provided for @createFormatManualHint.
  ///
  /// In en, this message translates to:
  /// **'Build your round robin from scratch, choosing the structure and match setup yourself.'**
  String get createFormatManualHint;

  /// No description provided for @createAssignTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'How do you want to add players?'**
  String get createAssignTypeTitle;

  /// No description provided for @createAssignNow.
  ///
  /// In en, this message translates to:
  /// **'Assign players to matches now'**
  String get createAssignNow;

  /// No description provided for @createAssignNowHint.
  ///
  /// In en, this message translates to:
  /// **'Pick who plays in each match.'**
  String get createAssignNowHint;

  /// No description provided for @createAssignLater.
  ///
  /// In en, this message translates to:
  /// **'Invite players and assign later'**
  String get createAssignLater;

  /// No description provided for @createAssignLaterHint.
  ///
  /// In en, this message translates to:
  /// **'Invite players first and set the matches afterwards.'**
  String get createAssignLaterHint;

  /// No description provided for @createAssignUndecided.
  ///
  /// In en, this message translates to:
  /// **'Choose singles or doubles for every match to assign players now.'**
  String get createAssignUndecided;

  /// No description provided for @createAssignPlayersTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign players'**
  String get createAssignPlayersTitle;

  /// No description provided for @createSideTop.
  ///
  /// In en, this message translates to:
  /// **'Side A'**
  String get createSideTop;

  /// No description provided for @createSideBottom.
  ///
  /// In en, this message translates to:
  /// **'Side B'**
  String get createSideBottom;

  /// No description provided for @createAddPlayer.
  ///
  /// In en, this message translates to:
  /// **'Add player'**
  String get createAddPlayer;

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String createRemovePlayer(String name);

  /// No description provided for @createAssignIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Fill every spot to continue.'**
  String get createAssignIncomplete;

  /// No description provided for @createSlotPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a player'**
  String get createSlotPickerTitle;

  /// No description provided for @createReviewScoring.
  ///
  /// In en, this message translates to:
  /// **'Scoring'**
  String get createReviewScoring;

  /// No description provided for @createReviewMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get createReviewMatches;

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'Match {number}: {type}'**
  String createReviewMatchLine(int number, String type);

  /// No description provided for @teamsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No teams yet'**
  String get teamsEmptyTitle;

  /// No description provided for @teamsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create a team to organize events with your players.'**
  String get teamsEmptyBody;

  /// No description provided for @teamsLoadError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your teams.'**
  String get teamsLoadError;

  /// No description provided for @createTeamAction.
  ///
  /// In en, this message translates to:
  /// **'Create team'**
  String get createTeamAction;

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String teamMembersCount(int count);

  /// No description provided for @teamTypeCasual.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get teamTypeCasual;

  /// No description provided for @teamTypeCompetitive.
  ///
  /// In en, this message translates to:
  /// **'Competitive'**
  String get teamTypeCompetitive;

  /// No description provided for @teamDetailsMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get teamDetailsMembers;

  /// No description provided for @teamMembersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No members yet.'**
  String get teamMembersEmpty;

  /// No description provided for @teamMembersLoadError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the members.'**
  String get teamMembersLoadError;

  /// No description provided for @teamDetailsLoadError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this team.'**
  String get teamDetailsLoadError;

  /// No description provided for @teamRoleCaptain.
  ///
  /// In en, this message translates to:
  /// **'Captain'**
  String get teamRoleCaptain;

  /// No description provided for @teamRolePlayer.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get teamRolePlayer;

  /// No description provided for @teamRoleCoach.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get teamRoleCoach;

  /// No description provided for @teamDetailsSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get teamDetailsSports;

  /// No description provided for @teamDetailsType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get teamDetailsType;

  /// No description provided for @createTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'New team'**
  String get createTeamTitle;

  /// No description provided for @createTeamNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Team name'**
  String get createTeamNameLabel;

  /// No description provided for @createTeamNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a team name.'**
  String get createTeamNameRequired;

  /// No description provided for @createTeamTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Team type'**
  String get createTeamTypeLabel;

  /// No description provided for @createTeamTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a team type.'**
  String get createTeamTypeRequired;

  /// No description provided for @createTeamSportsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get createTeamSportsLabel;

  /// No description provided for @createTeamSportRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one sport.'**
  String get createTeamSportRequired;

  /// No description provided for @createTeamRankingLabel.
  ///
  /// In en, this message translates to:
  /// **'Player ranking'**
  String get createTeamRankingLabel;

  /// No description provided for @createTeamRankingHint.
  ///
  /// In en, this message translates to:
  /// **'Rank players by their results in team events.'**
  String get createTeamRankingHint;

  /// No description provided for @createTeamParticipatingLabel.
  ///
  /// In en, this message translates to:
  /// **'You take part as'**
  String get createTeamParticipatingLabel;

  /// No description provided for @createTeamParticipatingHint.
  ///
  /// In en, this message translates to:
  /// **'You are the team captain. You can also play or coach.'**
  String get createTeamParticipatingHint;

  /// No description provided for @createTeamMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Add team members'**
  String get createTeamMembersTitle;

  /// No description provided for @createTeamMembersHint.
  ///
  /// In en, this message translates to:
  /// **'Search people and choose their role in the team.'**
  String get createTeamMembersHint;

  /// No description provided for @createTeamMembersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search people'**
  String get createTeamMembersSearchHint;

  /// No description provided for @createTeamMembersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No people found.'**
  String get createTeamMembersEmpty;

  /// No description provided for @createTeamSubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Create team'**
  String get createTeamSubmitAction;

  /// No description provided for @createTeamFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t create the team. Try again.'**
  String get createTeamFailed;

  /// No description provided for @createTeamCreated.
  ///
  /// In en, this message translates to:
  /// **'Team created.'**
  String get createTeamCreated;

  /// No description provided for @createTeamChoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Is this a team event?'**
  String get createTeamChoiceTitle;

  /// No description provided for @createTeamChoiceNonTeam.
  ///
  /// In en, this message translates to:
  /// **'Not a team event'**
  String get createTeamChoiceNonTeam;

  /// No description provided for @createTeamChoiceNonTeamHint.
  ///
  /// In en, this message translates to:
  /// **'Invite players yourself.'**
  String get createTeamChoiceNonTeamHint;

  /// No description provided for @createTeamChoiceTeam.
  ///
  /// In en, this message translates to:
  /// **'Team event'**
  String get createTeamChoiceTeam;

  /// No description provided for @createTeamChoiceTeamHint.
  ///
  /// In en, this message translates to:
  /// **'Invite members of one of your teams.'**
  String get createTeamChoiceTeamHint;

  /// No description provided for @createTeamSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Which team?'**
  String get createTeamSelectTitle;

  /// No description provided for @createTeamSelectRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a team.'**
  String get createTeamSelectRequired;

  /// No description provided for @createTeamSelectEmpty.
  ///
  /// In en, this message translates to:
  /// **'You are not the captain of a team that plays this sport.'**
  String get createTeamSelectEmpty;

  /// No description provided for @createTeamSelectCreate.
  ///
  /// In en, this message translates to:
  /// **'Create a team'**
  String get createTeamSelectCreate;

  /// No description provided for @createReviewTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get createReviewTeam;

  /// No description provided for @createRankingLabel.
  ///
  /// In en, this message translates to:
  /// **'Count towards team ranking'**
  String get createRankingLabel;

  /// No description provided for @createDynamicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Who are you playing?'**
  String get createDynamicsTitle;

  /// No description provided for @createDynamicsWithin.
  ///
  /// In en, this message translates to:
  /// **'Within my team'**
  String get createDynamicsWithin;

  /// No description provided for @createDynamicsWithinHint.
  ///
  /// In en, this message translates to:
  /// **'Members of your team play each other.'**
  String get createDynamicsWithinHint;

  /// No description provided for @createDynamicsOpponent.
  ///
  /// In en, this message translates to:
  /// **'Another team'**
  String get createDynamicsOpponent;

  /// No description provided for @createDynamicsOpponentHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a team that is in the app.'**
  String get createDynamicsOpponentHint;

  /// No description provided for @createDynamicsNamed.
  ///
  /// In en, this message translates to:
  /// **'A team by name'**
  String get createDynamicsNamed;

  /// No description provided for @createDynamicsNamedHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the name of a team that is not in the app.'**
  String get createDynamicsNamedHint;

  /// No description provided for @createOpponentNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Opponent team name'**
  String get createOpponentNameLabel;

  /// No description provided for @createOpponentNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the opponent team name.'**
  String get createOpponentNameRequired;

  /// No description provided for @createOpponentTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the opponent team'**
  String get createOpponentTitle;

  /// No description provided for @createOpponentSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search teams'**
  String get createOpponentSearchHint;

  /// No description provided for @createOpponentRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose the opponent team.'**
  String get createOpponentRequired;

  /// No description provided for @createOpponentEmpty.
  ///
  /// In en, this message translates to:
  /// **'No teams found.'**
  String get createOpponentEmpty;

  /// No description provided for @createHomeAwayTitle.
  ///
  /// In en, this message translates to:
  /// **'Which team is home?'**
  String get createHomeAwayTitle;

  /// No description provided for @createHomeTeamLabel.
  ///
  /// In en, this message translates to:
  /// **'Home team'**
  String get createHomeTeamLabel;

  /// No description provided for @createAwayTeamLabel.
  ///
  /// In en, this message translates to:
  /// **'Visiting team'**
  String get createAwayTeamLabel;

  /// No description provided for @createSwapTeams.
  ///
  /// In en, this message translates to:
  /// **'Swap home and visiting team'**
  String get createSwapTeams;

  /// No description provided for @createHomeNotDecided.
  ///
  /// In en, this message translates to:
  /// **'Home team not decided yet'**
  String get createHomeNotDecided;

  /// No description provided for @createReviewOpponent.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get createReviewOpponent;

  /// No description provided for @createOpponentSideNote.
  ///
  /// In en, this message translates to:
  /// **'The opponent team assigns its own players.'**
  String get createOpponentSideNote;
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
