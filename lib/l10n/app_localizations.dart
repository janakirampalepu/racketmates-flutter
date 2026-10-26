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

  /// No description provided for @welcomeAlreadyMember.
  ///
  /// In en, this message translates to:
  /// **'Already a member?'**
  String get welcomeAlreadyMember;

  /// No description provided for @otpDescriptionShort.
  ///
  /// In en, this message translates to:
  /// **'A verification code has been sent to'**
  String get otpDescriptionShort;

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

  /// No description provided for @chatNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get chatNewTitle;

  /// No description provided for @chatNewSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search players'**
  String get chatNewSearchHint;

  /// No description provided for @chatNewEmpty.
  ///
  /// In en, this message translates to:
  /// **'No players found.'**
  String get chatNewEmpty;

  /// No description provided for @chatNewError.
  ///
  /// In en, this message translates to:
  /// **'Players could not be loaded.'**
  String get chatNewError;

  /// No description provided for @chatNewCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'The chat could not be started. Please try again.'**
  String get chatNewCreateFailed;

  /// No description provided for @chatNewStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting the chat'**
  String get chatNewStarting;

  /// No description provided for @chatNewAction.
  ///
  /// In en, this message translates to:
  /// **'Start a new chat'**
  String get chatNewAction;

  /// No description provided for @eventChatAction.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get eventChatAction;

  /// No description provided for @eventChatChoose.
  ///
  /// In en, this message translates to:
  /// **'Which chat room do you want to open?'**
  String get eventChatChoose;

  /// No description provided for @eventChatPlayers.
  ///
  /// In en, this message translates to:
  /// **'Players chat room'**
  String get eventChatPlayers;

  /// No description provided for @eventChatCaptains.
  ///
  /// In en, this message translates to:
  /// **'Captains chat room'**
  String get eventChatCaptains;

  /// No description provided for @eventChatFailed.
  ///
  /// In en, this message translates to:
  /// **'The chat room could not be opened. Please try again.'**
  String get eventChatFailed;

  /// No description provided for @eventChatOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening the chat room'**
  String get eventChatOpening;

  /// No description provided for @chatConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to chat'**
  String get chatConnecting;

  /// No description provided for @chatFailed.
  ///
  /// In en, this message translates to:
  /// **'Chat could not connect. Check your connection and try again.'**
  String get chatFailed;

  /// No description provided for @chatUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Chat is not available on this build.'**
  String get chatUnavailable;

  /// Spoken label of the chat tab badge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unread message} other{{count} unread messages}}'**
  String navChatUnread(int count);

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

  /// No description provided for @familyPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose who to show'**
  String get familyPickerTitle;

  /// No description provided for @familyPickerSelectAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Select at least one person.'**
  String get familyPickerSelectAtLeastOne;

  /// No description provided for @familyPickerSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get familyPickerSaveAction;

  /// No description provided for @activityWeeklyAverageLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly average:'**
  String get activityWeeklyAverageLabel;

  /// No description provided for @activityLegendGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get activityLegendGames;

  /// No description provided for @activityLegendPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get activityLegendPractice;

  /// No description provided for @activityLegendLessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get activityLegendLessons;

  /// No description provided for @activityLegendMeetings.
  ///
  /// In en, this message translates to:
  /// **'Casual Meetings'**
  String get activityLegendMeetings;

  /// No description provided for @activityNoActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get activityNoActivityTitle;

  /// No description provided for @activityNoActivityDescription.
  ///
  /// In en, this message translates to:
  /// **'Your games, practices and lessons will show up here.'**
  String get activityNoActivityDescription;

  /// No description provided for @homeMaintenanceDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get homeMaintenanceDismiss;

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

  /// No description provided for @eventDraftSave.
  ///
  /// In en, this message translates to:
  /// **'Save as draft'**
  String get eventDraftSave;

  /// No description provided for @eventDraftDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get eventDraftDiscard;

  /// No description provided for @eventDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved as a draft.'**
  String get eventDraftSaved;

  /// No description provided for @eventDraftSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The draft could not be saved. Please try again.'**
  String get eventDraftSaveFailed;

  /// No description provided for @eventDraftMenu.
  ///
  /// In en, this message translates to:
  /// **'Draft options'**
  String get eventDraftMenu;

  /// No description provided for @eventDraftDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this event?'**
  String get eventDraftDiscardTitle;

  /// No description provided for @eventDraftDiscardText.
  ///
  /// In en, this message translates to:
  /// **'Nothing you entered will be kept.'**
  String get eventDraftDiscardText;

  /// No description provided for @eventDraftDiscardSavedText.
  ///
  /// In en, this message translates to:
  /// **'The saved draft is deleted too.'**
  String get eventDraftDiscardSavedText;

  /// No description provided for @eventDraftKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get eventDraftKeep;

  /// No description provided for @eventDraftLeave.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get eventDraftLeave;

  /// No description provided for @draftsTitle.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get draftsTitle;

  /// No description provided for @draftsAction.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get draftsAction;

  /// No description provided for @draftsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have no drafts.'**
  String get draftsEmpty;

  /// No description provided for @draftsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Drafts could not be loaded.'**
  String get draftsLoadError;

  /// No description provided for @draftsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String draftsUpdated(String date);

  /// No description provided for @draftDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete draft'**
  String get draftDelete;

  /// No description provided for @draftDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this draft?'**
  String get draftDeleteTitle;

  /// No description provided for @draftDeleteText.
  ///
  /// In en, this message translates to:
  /// **'The draft is deleted for good.'**
  String get draftDeleteText;

  /// No description provided for @draftDeleted.
  ///
  /// In en, this message translates to:
  /// **'Draft deleted.'**
  String get draftDeleted;

  /// No description provided for @draftDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'The draft could not be deleted. Please try again.'**
  String get draftDeleteFailed;

  /// No description provided for @draftOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'This draft could not be opened.'**
  String get draftOpenFailed;

  /// No description provided for @draftOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening the draft'**
  String get draftOpening;

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

  /// No description provided for @teamTabSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get teamTabSchedule;

  /// No description provided for @teamTabRankings.
  ///
  /// In en, this message translates to:
  /// **'Rankings'**
  String get teamTabRankings;

  /// No description provided for @teamTabMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get teamTabMembers;

  /// No description provided for @teamScheduleUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get teamScheduleUpcoming;

  /// No description provided for @teamSchedulePast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get teamSchedulePast;

  /// No description provided for @teamScheduleEmptyUpcoming.
  ///
  /// In en, this message translates to:
  /// **'The team has no upcoming events.'**
  String get teamScheduleEmptyUpcoming;

  /// No description provided for @teamScheduleEmptyPast.
  ///
  /// In en, this message translates to:
  /// **'The team has no past events.'**
  String get teamScheduleEmptyPast;

  /// No description provided for @teamScheduleLoadError.
  ///
  /// In en, this message translates to:
  /// **'The team\'s events could not be loaded.'**
  String get teamScheduleLoadError;

  /// No description provided for @teamRankingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No ranking yet for this selection.'**
  String get teamRankingsEmpty;

  /// No description provided for @teamRankingsLoadError.
  ///
  /// In en, this message translates to:
  /// **'The ranking could not be loaded.'**
  String get teamRankingsLoadError;

  /// No description provided for @teamRankingsOff.
  ///
  /// In en, this message translates to:
  /// **'Player ranking is not turned on for this team.'**
  String get teamRankingsOff;

  /// No description provided for @teamRankingPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get teamRankingPeriod;

  /// No description provided for @teamRankingMatchType.
  ///
  /// In en, this message translates to:
  /// **'Match type'**
  String get teamRankingMatchType;

  /// No description provided for @teamRankingAllMatches.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get teamRankingAllMatches;

  /// No description provided for @teamRankingRecord.
  ///
  /// In en, this message translates to:
  /// **'{wins}W - {losses}L'**
  String teamRankingRecord(int wins, int losses);

  /// No description provided for @teamRankingPoints.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String teamRankingPoints(int points);

  /// No description provided for @teamRankingUp.
  ///
  /// In en, this message translates to:
  /// **'Up {places}'**
  String teamRankingUp(int places);

  /// No description provided for @teamRankingDown.
  ///
  /// In en, this message translates to:
  /// **'Down {places}'**
  String teamRankingDown(int places);

  /// No description provided for @teamRankingRank.
  ///
  /// In en, this message translates to:
  /// **'Rank {rank}'**
  String teamRankingRank(int rank);

  /// No description provided for @teamMembersShowInactive.
  ///
  /// In en, this message translates to:
  /// **'Show deactivated members'**
  String get teamMembersShowInactive;

  /// No description provided for @teamMemberInactive.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get teamMemberInactive;

  /// No description provided for @teamMemberActions.
  ///
  /// In en, this message translates to:
  /// **'Member actions'**
  String get teamMemberActions;

  /// No description provided for @teamMemberEditRoles.
  ///
  /// In en, this message translates to:
  /// **'Edit roles'**
  String get teamMemberEditRoles;

  /// No description provided for @teamMemberDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get teamMemberDeactivate;

  /// No description provided for @teamMemberReactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get teamMemberReactivate;

  /// No description provided for @teamMemberRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from team'**
  String get teamMemberRemove;

  /// No description provided for @teamMemberRolesTitle.
  ///
  /// In en, this message translates to:
  /// **'Roles of {name}'**
  String teamMemberRolesTitle(String name);

  /// No description provided for @teamMemberRolesNeedOne.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one role.'**
  String get teamMemberRolesNeedOne;

  /// No description provided for @teamMemberOnlyCaptain.
  ///
  /// In en, this message translates to:
  /// **'A team needs a captain. Make someone else a captain first.'**
  String get teamMemberOnlyCaptain;

  /// No description provided for @teamMemberSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get teamMemberSave;

  /// No description provided for @teamMemberYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get teamMemberYes;

  /// No description provided for @teamMemberCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get teamMemberCancel;

  /// No description provided for @teamMemberDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String teamMemberDeactivateTitle(String name);

  /// No description provided for @teamMemberDeactivateText.
  ///
  /// In en, this message translates to:
  /// **'They stay in the team but are left out of new events.'**
  String get teamMemberDeactivateText;

  /// No description provided for @teamMemberReactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Reactivate {name}?'**
  String teamMemberReactivateTitle(String name);

  /// No description provided for @teamMemberReactivateText.
  ///
  /// In en, this message translates to:
  /// **'They will be part of new events again.'**
  String get teamMemberReactivateText;

  /// No description provided for @teamMemberRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String teamMemberRemoveTitle(String name);

  /// No description provided for @teamMemberRemoveText.
  ///
  /// In en, this message translates to:
  /// **'They are taken out of the team and its upcoming events.'**
  String get teamMemberRemoveText;

  /// No description provided for @teamMemberChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'The change could not be saved. Please try again.'**
  String get teamMemberChangeFailed;

  /// No description provided for @teamAddMembers.
  ///
  /// In en, this message translates to:
  /// **'Add members'**
  String get teamAddMembers;

  /// No description provided for @teamAddMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Add members'**
  String get teamAddMembersTitle;

  /// No description provided for @teamAddMembersHint.
  ///
  /// In en, this message translates to:
  /// **'Search for people and choose their roles.'**
  String get teamAddMembersHint;

  /// No description provided for @teamAddMembersSave.
  ///
  /// In en, this message translates to:
  /// **'Add to team'**
  String get teamAddMembersSave;

  /// No description provided for @teamAddMembersFailed.
  ///
  /// In en, this message translates to:
  /// **'The members could not be added. Please try again.'**
  String get teamAddMembersFailed;

  /// No description provided for @teamAddMembersDone.
  ///
  /// In en, this message translates to:
  /// **'Members added.'**
  String get teamAddMembersDone;

  /// No description provided for @teamAddMembersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one found.'**
  String get teamAddMembersEmpty;

  /// No description provided for @teamAddMembersLoadError.
  ///
  /// In en, this message translates to:
  /// **'The search failed.'**
  String get teamAddMembersLoadError;

  /// No description provided for @teamSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Team settings'**
  String get teamSettingsTitle;

  /// No description provided for @teamSettingsAction.
  ///
  /// In en, this message translates to:
  /// **'Team settings'**
  String get teamSettingsAction;

  /// No description provided for @teamSettingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get teamSettingsSave;

  /// No description provided for @teamSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Team updated.'**
  String get teamSettingsSaved;

  /// No description provided for @teamSettingsFailed.
  ///
  /// In en, this message translates to:
  /// **'The team could not be updated. Please try again.'**
  String get teamSettingsFailed;

  /// No description provided for @teamArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive team'**
  String get teamArchive;

  /// No description provided for @teamUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive team'**
  String get teamUnarchive;

  /// No description provided for @teamDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete team'**
  String get teamDelete;

  /// No description provided for @teamArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive {name}?'**
  String teamArchiveTitle(String name);

  /// No description provided for @teamArchiveText.
  ///
  /// In en, this message translates to:
  /// **'An archived team keeps its history but cannot get new events. You can unarchive it later.'**
  String get teamArchiveText;

  /// No description provided for @teamUnarchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Unarchive {name}?'**
  String teamUnarchiveTitle(String name);

  /// No description provided for @teamUnarchiveText.
  ///
  /// In en, this message translates to:
  /// **'The team becomes active again and can get new events.'**
  String get teamUnarchiveText;

  /// No description provided for @teamDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String teamDeleteTitle(String name);

  /// No description provided for @teamDeleteText.
  ///
  /// In en, this message translates to:
  /// **'The team and its events are deleted for everyone. This cannot be undone.'**
  String get teamDeleteText;

  /// No description provided for @teamActionYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get teamActionYes;

  /// No description provided for @teamActionNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get teamActionNo;

  /// No description provided for @teamArchivedDone.
  ///
  /// In en, this message translates to:
  /// **'Team archived.'**
  String get teamArchivedDone;

  /// No description provided for @teamUnarchivedDone.
  ///
  /// In en, this message translates to:
  /// **'Team unarchived.'**
  String get teamUnarchivedDone;

  /// No description provided for @teamDeletedDone.
  ///
  /// In en, this message translates to:
  /// **'Team deleted.'**
  String get teamDeletedDone;

  /// No description provided for @teamActionFailed.
  ///
  /// In en, this message translates to:
  /// **'That did not work. Please try again.'**
  String get teamActionFailed;

  /// No description provided for @teamArchivedBanner.
  ///
  /// In en, this message translates to:
  /// **'This team is archived.'**
  String get teamArchivedBanner;

  /// No description provided for @teamArchivedBadge.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get teamArchivedBadge;

  /// No description provided for @teamArchivedCreateEvent.
  ///
  /// In en, this message translates to:
  /// **'An archived team cannot get new events. Unarchive it first.'**
  String get teamArchivedCreateEvent;

  /// No description provided for @teamCreateEvent.
  ///
  /// In en, this message translates to:
  /// **'Create event'**
  String get teamCreateEvent;

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

  /// No description provided for @createLessonAssignTitle.
  ///
  /// In en, this message translates to:
  /// **'Who is the lesson for?'**
  String get createLessonAssignTitle;

  /// No description provided for @createLessonAssignOne.
  ///
  /// In en, this message translates to:
  /// **'One player'**
  String get createLessonAssignOne;

  /// No description provided for @createLessonAssignOneHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the player now.'**
  String get createLessonAssignOneHint;

  /// No description provided for @createLessonAssignMany.
  ///
  /// In en, this message translates to:
  /// **'Several players'**
  String get createLessonAssignMany;

  /// No description provided for @createLessonAssignManyHint.
  ///
  /// In en, this message translates to:
  /// **'Invite players; the first to accept gets the lesson.'**
  String get createLessonAssignManyHint;

  /// No description provided for @createSinglePlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the player'**
  String get createSinglePlayerTitle;

  /// No description provided for @createCoachesMaxHint.
  ///
  /// In en, this message translates to:
  /// **'Choose up to two coaches.'**
  String get createCoachesMaxHint;

  /// No description provided for @eventManageAction.
  ///
  /// In en, this message translates to:
  /// **'Manage event'**
  String get eventManageAction;

  /// No description provided for @eventManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage event'**
  String get eventManageTitle;

  /// No description provided for @eventManageSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get eventManageSettings;

  /// No description provided for @eventManageSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Response deadline, limits and scoring'**
  String get eventManageSettingsHint;

  /// No description provided for @eventManagePlayers.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get eventManagePlayers;

  /// No description provided for @eventManagePlayersHint.
  ///
  /// In en, this message translates to:
  /// **'Add, confirm or remove players and coaches'**
  String get eventManagePlayersHint;

  /// No description provided for @eventManageSchedule.
  ///
  /// In en, this message translates to:
  /// **'Date, time and venue'**
  String get eventManageSchedule;

  /// No description provided for @eventManageScheduleHint.
  ///
  /// In en, this message translates to:
  /// **'Move the event to another time or place'**
  String get eventManageScheduleHint;

  /// No description provided for @eventManageScores.
  ///
  /// In en, this message translates to:
  /// **'Scores'**
  String get eventManageScores;

  /// No description provided for @eventManageScoresHint.
  ///
  /// In en, this message translates to:
  /// **'Enter or correct the results of the matches'**
  String get eventManageScoresHint;

  /// No description provided for @eventManageRounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get eventManageRounds;

  /// No description provided for @eventManageRoundsHint.
  ///
  /// In en, this message translates to:
  /// **'See and edit the rounds of this round robin'**
  String get eventManageRoundsHint;

  /// No description provided for @eventManageRoundsSetUp.
  ///
  /// In en, this message translates to:
  /// **'Set up rounds'**
  String get eventManageRoundsSetUp;

  /// No description provided for @eventManageRoundsSetUpHint.
  ///
  /// In en, this message translates to:
  /// **'Generate the rounds from the confirmed players'**
  String get eventManageRoundsSetUpHint;

  /// No description provided for @eventManageRoundsFixedHint.
  ///
  /// In en, this message translates to:
  /// **'Pair the players, then generate the rounds'**
  String get eventManageRoundsFixedHint;

  /// No description provided for @rsvpPrefsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your game'**
  String get rsvpPrefsTitle;

  /// No description provided for @rsvpPrefsMatchType.
  ///
  /// In en, this message translates to:
  /// **'Match type'**
  String get rsvpPrefsMatchType;

  /// No description provided for @rsvpPrefsDoubles.
  ///
  /// In en, this message translates to:
  /// **'Doubles'**
  String get rsvpPrefsDoubles;

  /// No description provided for @rsvpPrefsBoth.
  ///
  /// In en, this message translates to:
  /// **'Singles or doubles'**
  String get rsvpPrefsBoth;

  /// No description provided for @rsvpPrefsPartner.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get rsvpPrefsPartner;

  /// No description provided for @rsvpPrefsHavePartner.
  ///
  /// In en, this message translates to:
  /// **'I have a partner'**
  String get rsvpPrefsHavePartner;

  /// No description provided for @rsvpPrefsNeedPartner.
  ///
  /// In en, this message translates to:
  /// **'I need a partner'**
  String get rsvpPrefsNeedPartner;

  /// No description provided for @rsvpPrefsSelectPartner.
  ///
  /// In en, this message translates to:
  /// **'Select partner'**
  String get rsvpPrefsSelectPartner;

  /// No description provided for @rsvpPrefsChangePartner.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get rsvpPrefsChangePartner;

  /// No description provided for @rsvpPrefsNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get rsvpPrefsNotes;

  /// No description provided for @rsvpPrefsSubmit.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get rsvpPrefsSubmit;

  /// No description provided for @rsvpPrefsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get rsvpPrefsSave;

  /// No description provided for @rsvpPartnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select partner'**
  String get rsvpPartnerTitle;

  /// No description provided for @rsvpPartnerSearch.
  ///
  /// In en, this message translates to:
  /// **'Search players'**
  String get rsvpPartnerSearch;

  /// No description provided for @rsvpPartnerNone.
  ///
  /// In en, this message translates to:
  /// **'No partners'**
  String get rsvpPartnerNone;

  /// No description provided for @rsvpPartnerSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get rsvpPartnerSelect;

  /// No description provided for @rsvpPartnerLoadError.
  ///
  /// In en, this message translates to:
  /// **'The players could not be loaded.'**
  String get rsvpPartnerLoadError;

  /// No description provided for @eventPartnerYours.
  ///
  /// In en, this message translates to:
  /// **'Your partner'**
  String get eventPartnerYours;

  /// No description provided for @eventPartnerRequested.
  ///
  /// In en, this message translates to:
  /// **'Someone wants to play with you'**
  String get eventPartnerRequested;

  /// No description provided for @eventPartnerChoose.
  ///
  /// In en, this message translates to:
  /// **'You have not chosen a partner yet.'**
  String get eventPartnerChoose;

  /// No description provided for @eventPartnerEdit.
  ///
  /// In en, this message translates to:
  /// **'Change partner'**
  String get eventPartnerEdit;

  /// No description provided for @eventPartnerChooseAction.
  ///
  /// In en, this message translates to:
  /// **'Choose a partner'**
  String get eventPartnerChooseAction;

  /// No description provided for @eventPrefsSaved.
  ///
  /// In en, this message translates to:
  /// **'Your game preferences were saved.'**
  String get eventPrefsSaved;

  /// No description provided for @eventPrefsFailed.
  ///
  /// In en, this message translates to:
  /// **'Your preferences could not be saved. Please try again.'**
  String get eventPrefsFailed;

  /// No description provided for @kidSportsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get kidSportsLabel;

  /// No description provided for @eventPairsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pairs'**
  String get eventPairsTitle;

  /// No description provided for @eventPairsInfo.
  ///
  /// In en, this message translates to:
  /// **'Create pairs for your round robin. Players who aren\'t paired play singles.'**
  String get eventPairsInfo;

  /// No description provided for @eventPairsHeading.
  ///
  /// In en, this message translates to:
  /// **'Pairs'**
  String get eventPairsHeading;

  /// No description provided for @eventPairsNone.
  ///
  /// In en, this message translates to:
  /// **'No pairs yet.'**
  String get eventPairsNone;

  /// No description provided for @eventPairsUnpaired.
  ///
  /// In en, this message translates to:
  /// **'Players without a partner'**
  String get eventPairsUnpaired;

  /// No description provided for @eventPairsUnpairedNone.
  ///
  /// In en, this message translates to:
  /// **'Everyone has a partner.'**
  String get eventPairsUnpairedNone;

  /// No description provided for @eventPairsPick.
  ///
  /// In en, this message translates to:
  /// **'Select two players to pair them.'**
  String get eventPairsPick;

  /// No description provided for @eventPairsPair.
  ///
  /// In en, this message translates to:
  /// **'Pair up'**
  String get eventPairsPair;

  /// No description provided for @eventPairsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove pair'**
  String get eventPairsRemove;

  /// No description provided for @eventPairsContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue to rounds'**
  String get eventPairsContinue;

  /// No description provided for @eventPairsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get eventPairsFilterAll;

  /// No description provided for @eventPairsFilterDoubles.
  ///
  /// In en, this message translates to:
  /// **'Doubles'**
  String get eventPairsFilterDoubles;

  /// No description provided for @eventPairsFilterBoth.
  ///
  /// In en, this message translates to:
  /// **'Singles or doubles'**
  String get eventPairsFilterBoth;

  /// No description provided for @eventPairsLoadError.
  ///
  /// In en, this message translates to:
  /// **'The players could not be loaded.'**
  String get eventPairsLoadError;

  /// No description provided for @eventRoundSideTop.
  ///
  /// In en, this message translates to:
  /// **'Top side'**
  String get eventRoundSideTop;

  /// No description provided for @eventRoundSideBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom side'**
  String get eventRoundSideBottom;

  /// No description provided for @eventRoundNoPlayers.
  ///
  /// In en, this message translates to:
  /// **'Assign players'**
  String get eventRoundNoPlayers;

  /// No description provided for @eventAssignTitle.
  ///
  /// In en, this message translates to:
  /// **'Select players'**
  String get eventAssignTitle;

  /// No description provided for @eventAssignSearch.
  ///
  /// In en, this message translates to:
  /// **'Search players'**
  String get eventAssignSearch;

  /// No description provided for @eventAssignNone.
  ///
  /// In en, this message translates to:
  /// **'No players to choose from.'**
  String get eventAssignNone;

  /// No description provided for @eventAssignSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get eventAssignSave;

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'Up to {count} per side.'**
  String eventAssignLimit(int count);

  /// No description provided for @eventRoundsWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for players'**
  String get eventRoundsWaitingTitle;

  /// No description provided for @eventRoundsWaitingText.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have enough players yet to start generating the rounds.'**
  String get eventRoundsWaitingText;

  /// No description provided for @eventRoundsOk.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get eventRoundsOk;

  /// No description provided for @eventRoundsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get eventRoundsTitle;

  /// No description provided for @eventRoundsEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no rounds yet.'**
  String get eventRoundsEmpty;

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'Round {number}'**
  String eventRoundNumber(int number);

  /// No description provided for @eventRoundAdd.
  ///
  /// In en, this message translates to:
  /// **'Add round'**
  String get eventRoundAdd;

  /// No description provided for @eventRoundRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove round'**
  String get eventRoundRemove;

  /// No description provided for @eventRoundKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep round'**
  String get eventRoundKeep;

  /// No description provided for @eventRoundRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this round?'**
  String get eventRoundRemoveTitle;

  /// No description provided for @eventRoundRemoveText.
  ///
  /// In en, this message translates to:
  /// **'If you remove this round, its matches will be missing at the end of the event. This can\'t be undone.'**
  String get eventRoundRemoveText;

  /// No description provided for @eventMatchRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove match'**
  String get eventMatchRemove;

  /// No description provided for @eventMatchRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this match?'**
  String get eventMatchRemoveTitle;

  /// No description provided for @eventMatchRemoveText.
  ///
  /// In en, this message translates to:
  /// **'The match is removed from the round. This can\'t be undone.'**
  String get eventMatchRemoveText;

  /// No description provided for @eventMatchChangeCourt.
  ///
  /// In en, this message translates to:
  /// **'Change court'**
  String get eventMatchChangeCourt;

  /// No description provided for @eventMatchCourtTitle.
  ///
  /// In en, this message translates to:
  /// **'Move to court'**
  String get eventMatchCourtTitle;

  /// No description provided for @eventMatchNoCourt.
  ///
  /// In en, this message translates to:
  /// **'No court'**
  String get eventMatchNoCourt;

  /// No description provided for @eventMatchNoCourts.
  ///
  /// In en, this message translates to:
  /// **'This event has no courts to choose from.'**
  String get eventMatchNoCourts;

  /// No description provided for @eventManageLocked.
  ///
  /// In en, this message translates to:
  /// **'This event can no longer be changed.'**
  String get eventManageLocked;

  /// No description provided for @eventManageScheduleUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Changing the time of this event is not available in this build yet.'**
  String get eventManageScheduleUnsupported;

  /// No description provided for @eventManageSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved.'**
  String get eventManageSaved;

  /// No description provided for @eventManageFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save the changes. Try again.'**
  String get eventManageFailed;

  /// No description provided for @eventManageSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get eventManageSave;

  /// No description provided for @eventSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Event settings'**
  String get eventSettingsTitle;

  /// No description provided for @eventPlayersTitle.
  ///
  /// In en, this message translates to:
  /// **'People in this event'**
  String get eventPlayersTitle;

  /// No description provided for @eventGroupConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get eventGroupConfirmed;

  /// No description provided for @eventGroupToBeConfirmed.
  ///
  /// In en, this message translates to:
  /// **'To be confirmed'**
  String get eventGroupToBeConfirmed;

  /// No description provided for @eventGroupWaitlisted.
  ///
  /// In en, this message translates to:
  /// **'Waiting list'**
  String get eventGroupWaitlisted;

  /// No description provided for @eventGroupInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get eventGroupInvited;

  /// No description provided for @eventGroupDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get eventGroupDeclined;

  /// No description provided for @eventGroupOther.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get eventGroupOther;

  /// No description provided for @eventGroupCoaches.
  ///
  /// In en, this message translates to:
  /// **'Coaches'**
  String get eventGroupCoaches;

  /// No description provided for @eventAddPlayers.
  ///
  /// In en, this message translates to:
  /// **'Add players'**
  String get eventAddPlayers;

  /// No description provided for @eventAddCoaches.
  ///
  /// In en, this message translates to:
  /// **'Add coaches'**
  String get eventAddCoaches;

  /// No description provided for @eventRemoveSelected.
  ///
  /// In en, this message translates to:
  /// **'Remove selected'**
  String get eventRemoveSelected;

  /// No description provided for @eventConfirmSelected.
  ///
  /// In en, this message translates to:
  /// **'Confirm selected'**
  String get eventConfirmSelected;

  /// No description provided for @eventRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from the event?'**
  String get eventRemoveTitle;

  /// No description provided for @eventRemoveMessage.
  ///
  /// In en, this message translates to:
  /// **'They will no longer be part of this event.'**
  String get eventRemoveMessage;

  /// No description provided for @eventNoParticipants.
  ///
  /// In en, this message translates to:
  /// **'No one yet.'**
  String get eventNoParticipants;

  /// No description provided for @eventAddPeopleTitle.
  ///
  /// In en, this message translates to:
  /// **'Add people'**
  String get eventAddPeopleTitle;

  /// No description provided for @eventAddPeopleAction.
  ///
  /// In en, this message translates to:
  /// **'Add selected'**
  String get eventAddPeopleAction;

  /// No description provided for @eventAddPeopleEmpty.
  ///
  /// In en, this message translates to:
  /// **'There is no one left to add.'**
  String get eventAddPeopleEmpty;

  /// No description provided for @eventScoresTitle.
  ///
  /// In en, this message translates to:
  /// **'Scores'**
  String get eventScoresTitle;

  /// No description provided for @eventScoreEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter score'**
  String get eventScoreEntryTitle;

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'Set {number}'**
  String eventScoreSet(int number);

  /// No description provided for @eventScoreSingle.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get eventScoreSingle;

  /// No description provided for @eventScoreUnfinished.
  ///
  /// In en, this message translates to:
  /// **'Match not finished'**
  String get eventScoreUnfinished;

  /// No description provided for @eventScoreSave.
  ///
  /// In en, this message translates to:
  /// **'Save score'**
  String get eventScoreSave;

  /// No description provided for @eventScoreErrorNone.
  ///
  /// In en, this message translates to:
  /// **'Enter a score.'**
  String get eventScoreErrorNone;

  /// No description provided for @eventScoreErrorIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Enter both scores of a set.'**
  String get eventScoreErrorIncomplete;

  /// No description provided for @eventScoreErrorNumber.
  ///
  /// In en, this message translates to:
  /// **'Scores are whole numbers.'**
  String get eventScoreErrorNumber;

  /// No description provided for @eventConfirmScores.
  ///
  /// In en, this message translates to:
  /// **'Confirm scores'**
  String get eventConfirmScores;

  /// No description provided for @eventScoresConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Scores confirmed.'**
  String get eventScoresConfirmed;

  /// No description provided for @eventScoresConfirmFailed.
  ///
  /// In en, this message translates to:
  /// **'The scores could not be confirmed. Please try again.'**
  String get eventScoresConfirmFailed;

  /// No description provided for @eventScoreErrorTieBreak.
  ///
  /// In en, this message translates to:
  /// **'A tie-break cannot end level.'**
  String get eventScoreErrorTieBreak;

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'Tie-break, set {set}'**
  String eventScoreTieBreak(int set);

  /// No description provided for @eventScoreMatchTieBreak.
  ///
  /// In en, this message translates to:
  /// **'Match tie-break'**
  String get eventScoreMatchTieBreak;

  /// No description provided for @eventScoreDecidingPrompt.
  ///
  /// In en, this message translates to:
  /// **'The sets are level. How is the last set played?'**
  String get eventScoreDecidingPrompt;

  /// No description provided for @eventScoreNone.
  ///
  /// In en, this message translates to:
  /// **'No score yet'**
  String get eventScoreNone;

  /// No description provided for @eventScoreUnfinishedTag.
  ///
  /// In en, this message translates to:
  /// **'Unfinished'**
  String get eventScoreUnfinishedTag;

  /// No description provided for @eventScoreClearUnfinished.
  ///
  /// In en, this message translates to:
  /// **'Remove unfinished status'**
  String get eventScoreClearUnfinished;

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'Sets won: {top} – {bottom}'**
  String eventScoreWinning(int top, int bottom);

  /// No description provided for @eventScoreTop.
  ///
  /// In en, this message translates to:
  /// **'Top side'**
  String get eventScoreTop;

  /// No description provided for @eventScoreBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom side'**
  String get eventScoreBottom;

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'Match {number}'**
  String eventMatchNumber(int number);

  /// No description provided for @deviceBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Security Warning'**
  String get deviceBlockedTitle;

  /// No description provided for @deviceBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'This device appears to be rooted or jailbroken. That exposes your device to malware and keyloggers.\n\nWe do not recommend using our app on such a device. It is strongly recommended that you access your account on another device or reset this device to its original settings.'**
  String get deviceBlockedMessage;

  /// No description provided for @downtimeFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll be right back'**
  String get downtimeFallbackTitle;

  /// No description provided for @downtimeFallbackMessage.
  ///
  /// In en, this message translates to:
  /// **'The service is unavailable right now. Please try again in a little while.'**
  String get downtimeFallbackMessage;

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'We will be back before {time} {date}.'**
  String downtimeBackBefore(String time, String date);

  /// No description provided for @downtimeCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get downtimeCheckAgain;

  /// No description provided for @accessNeedsSubscription.
  ///
  /// In en, this message translates to:
  /// **'This feature needs a subscription.'**
  String get accessNeedsSubscription;

  /// No description provided for @accessBlocked.
  ///
  /// In en, this message translates to:
  /// **'This isn\'t available right now.'**
  String get accessBlocked;

  /// No description provided for @notificationViewAction.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get notificationViewAction;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Push notifications and text messages'**
  String get settingsNotificationsHint;

  /// No description provided for @settingsReminders.
  ///
  /// In en, this message translates to:
  /// **'Event reminders'**
  String get settingsReminders;

  /// No description provided for @settingsRemindersHint.
  ///
  /// In en, this message translates to:
  /// **'When to be reminded before an event'**
  String get settingsRemindersHint;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get profileFirstName;

  /// No description provided for @profileLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get profileLastName;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get profileEmail;

  /// No description provided for @profilePhone.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get profilePhone;

  /// No description provided for @profilePhoneHint.
  ///
  /// In en, this message translates to:
  /// **'To change your number, contact support.'**
  String get profilePhoneHint;

  /// No description provided for @profileFirstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name.'**
  String get profileFirstNameRequired;

  /// No description provided for @profileLastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name.'**
  String get profileLastNameRequired;

  /// No description provided for @profileEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get profileEmailInvalid;

  /// No description provided for @profileEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'This email is already in use.'**
  String get profileEmailTaken;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSave;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get profileSaved;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The profile could not be saved. Please try again.'**
  String get profileSaveFailed;

  /// No description provided for @profilePhotoChange.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get profilePhotoChange;

  /// No description provided for @profilePhotoAdd.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get profilePhotoAdd;

  /// No description provided for @profilePhotoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get profilePhotoRemove;

  /// No description provided for @profilePhotoCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get profilePhotoCamera;

  /// No description provided for @profilePhotoGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get profilePhotoGallery;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Photo updated.'**
  String get profilePhotoUpdated;

  /// No description provided for @profilePhotoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Photo removed.'**
  String get profilePhotoRemoved;

  /// No description provided for @profilePhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'The photo could not be updated. Please try again.'**
  String get profilePhotoFailed;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Your profile could not be loaded.'**
  String get profileLoadError;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsProfileHint.
  ///
  /// In en, this message translates to:
  /// **'Your name, email and photo'**
  String get settingsProfileHint;

  /// No description provided for @settingsShare.
  ///
  /// In en, this message translates to:
  /// **'Share with friends'**
  String get settingsShare;

  /// No description provided for @settingsShareHint.
  ///
  /// In en, this message translates to:
  /// **'Invite friends to Racketmates'**
  String get settingsShareHint;

  /// No description provided for @settingsContact.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get settingsContact;

  /// No description provided for @settingsContactHint.
  ///
  /// In en, this message translates to:
  /// **'Send a message to the Racketmates team'**
  String get settingsContactHint;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Ask for your account to be deleted'**
  String get settingsDeleteAccountHint;

  /// No description provided for @shareTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite your friends'**
  String get shareTitle;

  /// No description provided for @shareText.
  ///
  /// In en, this message translates to:
  /// **'Racketmates is better with friends. Share the app and play together.'**
  String get shareText;

  /// No description provided for @shareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareAction;

  /// No description provided for @shareCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get shareCopy;

  /// No description provided for @shareCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied.'**
  String get shareCopied;

  /// No description provided for @shareMessage.
  ///
  /// In en, this message translates to:
  /// **'Join me on Racketmates:'**
  String get shareMessage;

  /// No description provided for @contactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactTitle;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get contactEmail;

  /// No description provided for @contactSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get contactSubject;

  /// No description provided for @contactQuestion.
  ///
  /// In en, this message translates to:
  /// **'Your question'**
  String get contactQuestion;

  /// No description provided for @contactSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get contactSubmit;

  /// No description provided for @contactSent.
  ///
  /// In en, this message translates to:
  /// **'Thank you. We will get back to you.'**
  String get contactSent;

  /// No description provided for @contactFailed.
  ///
  /// In en, this message translates to:
  /// **'Your message could not be sent. Please try again.'**
  String get contactFailed;

  /// No description provided for @contactEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address.'**
  String get contactEmailRequired;

  /// No description provided for @contactEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get contactEmailInvalid;

  /// No description provided for @contactSubjectRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a subject.'**
  String get contactSubjectRequired;

  /// No description provided for @contactQuestionRequired.
  ///
  /// In en, this message translates to:
  /// **'Write your question.'**
  String get contactQuestionRequired;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteTitle;

  /// No description provided for @deleteText.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account removes your profile and your data. This cannot be undone.'**
  String get deleteText;

  /// No description provided for @deleteSubscription.
  ///
  /// In en, this message translates to:
  /// **'You have an active subscription. Deleting your account does not cancel it: manage it in the store first.'**
  String get deleteSubscription;

  /// No description provided for @deleteManageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get deleteManageSubscription;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAction;

  /// No description provided for @deleteConfirmText.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?'**
  String get deleteConfirmText;

  /// No description provided for @deleteCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deleteCancel;

  /// No description provided for @deleteProcessing.
  ///
  /// In en, this message translates to:
  /// **'Your request was sent. We will delete your account and you will be signed out.'**
  String get deleteProcessing;

  /// No description provided for @deleteOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get deleteOk;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'The request could not be sent. Please try again.'**
  String get deleteFailed;

  /// No description provided for @rolesTitle.
  ///
  /// In en, this message translates to:
  /// **'Roles and sports'**
  String get rolesTitle;

  /// No description provided for @rolesHint.
  ///
  /// In en, this message translates to:
  /// **'Choose how you use Racketmates and which sports you play, coach or have your kids play.'**
  String get rolesHint;

  /// No description provided for @roleActiveSports.
  ///
  /// In en, this message translates to:
  /// **'{sports}'**
  String roleActiveSports(String sports);

  /// No description provided for @roleNotActive.
  ///
  /// In en, this message translates to:
  /// **'Not active. Tap to add.'**
  String get roleNotActive;

  /// No description provided for @roleParentKids.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 kid} other{{count} kids}}'**
  String roleParentKids(int count);

  /// No description provided for @settingsRoles.
  ///
  /// In en, this message translates to:
  /// **'Roles and sports'**
  String get settingsRoles;

  /// No description provided for @settingsRolesHint.
  ///
  /// In en, this message translates to:
  /// **'Player, coach and parent'**
  String get settingsRolesHint;

  /// No description provided for @roleSportsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get roleSportsSave;

  /// No description provided for @roleSportsSaved.
  ///
  /// In en, this message translates to:
  /// **'Sports updated.'**
  String get roleSportsSaved;

  /// No description provided for @roleSportsAdded.
  ///
  /// In en, this message translates to:
  /// **'Role added.'**
  String get roleSportsAdded;

  /// No description provided for @roleSportsFailed.
  ///
  /// In en, this message translates to:
  /// **'The change could not be saved. Please try again.'**
  String get roleSportsFailed;

  /// No description provided for @kidsEnableTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable the parent role'**
  String get kidsEnableTitle;

  /// No description provided for @kidsEnableText.
  ///
  /// In en, this message translates to:
  /// **'Add your kids to manage their games and events from your account.'**
  String get kidsEnableText;

  /// No description provided for @kidsEnableAction.
  ///
  /// In en, this message translates to:
  /// **'Add a kid'**
  String get kidsEnableAction;

  /// No description provided for @kidEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get kidEdit;

  /// No description provided for @kidRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get kidRemove;

  /// No description provided for @kidRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String kidRemoveTitle(String name);

  /// No description provided for @kidRemoveText.
  ///
  /// In en, this message translates to:
  /// **'The account of {name} is deleted.'**
  String kidRemoveText(String name);

  /// No description provided for @kidRemoveLastText.
  ///
  /// In en, this message translates to:
  /// **'The account of {name} is deleted and the parent role is turned off.'**
  String kidRemoveLastText(String name);

  /// No description provided for @kidRemoved.
  ///
  /// In en, this message translates to:
  /// **'Kid removed.'**
  String get kidRemoved;

  /// No description provided for @kidRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'The kid could not be removed. Please try again.'**
  String get kidRemoveFailed;

  /// No description provided for @kidAdded.
  ///
  /// In en, this message translates to:
  /// **'Kid added.'**
  String get kidAdded;

  /// No description provided for @kidUpdated.
  ///
  /// In en, this message translates to:
  /// **'Kid updated.'**
  String get kidUpdated;

  /// No description provided for @kidEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit kid'**
  String get kidEditTitle;

  /// No description provided for @kidSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get kidSave;

  /// No description provided for @kidSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The kid could not be saved. Please try again.'**
  String get kidSaveFailed;

  /// No description provided for @kidNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get kidNameRequired;

  /// No description provided for @phoneChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change mobile number'**
  String get phoneChangeTitle;

  /// No description provided for @phoneChangeHint.
  ///
  /// In en, this message translates to:
  /// **'We will text a code to the new number.'**
  String get phoneChangeHint;

  /// No description provided for @phoneChangeSend.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get phoneChangeSend;

  /// No description provided for @phoneChangeTaken.
  ///
  /// In en, this message translates to:
  /// **'This number belongs to another account.'**
  String get phoneChangeTaken;

  /// No description provided for @phoneChangeSame.
  ///
  /// In en, this message translates to:
  /// **'That is already your number.'**
  String get phoneChangeSame;

  /// No description provided for @phoneChangeCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the code we sent to {number}.'**
  String phoneChangeCodeHint(String number);

  /// No description provided for @phoneChangeCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get phoneChangeCodeLabel;

  /// No description provided for @phoneChangeVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify and change'**
  String get phoneChangeVerify;

  /// No description provided for @phoneChangeCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code is not right.'**
  String get phoneChangeCodeInvalid;

  /// No description provided for @phoneChangeResend.
  ///
  /// In en, this message translates to:
  /// **'Send the code again'**
  String get phoneChangeResend;

  /// No description provided for @phoneChangeDone.
  ///
  /// In en, this message translates to:
  /// **'Mobile number changed.'**
  String get phoneChangeDone;

  /// No description provided for @phoneChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'The number could not be changed. Please try again.'**
  String get phoneChangeFailed;

  /// No description provided for @profilePhoneChange.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get profilePhoneChange;

  /// No description provided for @settingsRate.
  ///
  /// In en, this message translates to:
  /// **'Rate the app'**
  String get settingsRate;

  /// No description provided for @locationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get locationsTitle;

  /// No description provided for @locationsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search venues'**
  String get locationsSearchHint;

  /// No description provided for @locationsNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get locationsNearby;

  /// No description provided for @locationsFavourites.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get locationsFavourites;

  /// No description provided for @locationsNearYou.
  ///
  /// In en, this message translates to:
  /// **'Near your current location'**
  String get locationsNearYou;

  /// No description provided for @locationsNoLocation.
  ///
  /// In en, this message translates to:
  /// **'Turn on location to see the venues closest to you.'**
  String get locationsNoLocation;

  /// No description provided for @locationsEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable location'**
  String get locationsEnable;

  /// No description provided for @locationsOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get locationsOpenSettings;

  /// No description provided for @locationsLocating.
  ///
  /// In en, this message translates to:
  /// **'Finding your location'**
  String get locationsLocating;

  /// No description provided for @locationsFilter.
  ///
  /// In en, this message translates to:
  /// **'Distance filter'**
  String get locationsFilter;

  /// No description provided for @locationsDistanceValue.
  ///
  /// In en, this message translates to:
  /// **'Within {distance} {unit}'**
  String locationsDistanceValue(int distance, String unit);

  /// No description provided for @locationsDistanceHint.
  ///
  /// In en, this message translates to:
  /// **'Show venues within this distance of you.'**
  String get locationsDistanceHint;

  /// No description provided for @locationsApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get locationsApply;

  /// No description provided for @locationsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get locationsReset;

  /// No description provided for @locationsDefaultUnit.
  ///
  /// In en, this message translates to:
  /// **'mi'**
  String get locationsDefaultUnit;

  /// No description provided for @venueCourts.
  ///
  /// In en, this message translates to:
  /// **'Courts'**
  String get venueCourts;

  /// No description provided for @venueNoCourts.
  ///
  /// In en, this message translates to:
  /// **'No courts are listed for this venue.'**
  String get venueNoCourts;

  /// No description provided for @venueDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get venueDirections;

  /// No description provided for @venueMembership.
  ///
  /// In en, this message translates to:
  /// **'Membership required'**
  String get venueMembership;

  /// No description provided for @venueLoadError.
  ///
  /// In en, this message translates to:
  /// **'The venue could not be loaded.'**
  String get venueLoadError;

  /// No description provided for @venueCourtIndoor.
  ///
  /// In en, this message translates to:
  /// **'Indoor'**
  String get venueCourtIndoor;

  /// No description provided for @venueCourtOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get venueCourtOutdoor;

  /// No description provided for @settingsLocations.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get settingsLocations;

  /// No description provided for @settingsLocationsHint.
  ///
  /// In en, this message translates to:
  /// **'Find venues and manage your favourites'**
  String get settingsLocationsHint;

  /// No description provided for @subscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Racketmates Pro'**
  String get subscriptionTitle;

  /// No description provided for @subscriptionBenefit1Title.
  ///
  /// In en, this message translates to:
  /// **'Manage teams and events'**
  String get subscriptionBenefit1Title;

  /// No description provided for @subscriptionBenefit1Text.
  ///
  /// In en, this message translates to:
  /// **'Create teams, run events and keep everyone in the loop.'**
  String get subscriptionBenefit1Text;

  /// No description provided for @subscriptionBenefit2Title.
  ///
  /// In en, this message translates to:
  /// **'Grow your community'**
  String get subscriptionBenefit2Title;

  /// No description provided for @subscriptionBenefit2Text.
  ///
  /// In en, this message translates to:
  /// **'Invite players, coaches and friends and build up your club.'**
  String get subscriptionBenefit2Text;

  /// No description provided for @subscriptionBenefit3Title.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get subscriptionBenefit3Title;

  /// No description provided for @subscriptionBenefit3Text.
  ///
  /// In en, this message translates to:
  /// **'Chat with the Racketmates team whenever you need help.'**
  String get subscriptionBenefit3Text;

  /// No description provided for @subscriptionMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get subscriptionMonthly;

  /// No description provided for @subscriptionYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get subscriptionYearly;

  /// No description provided for @subscriptionPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{price}/month'**
  String subscriptionPerMonth(String price);

  /// No description provided for @subscriptionSave.
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String subscriptionSave(int percent);

  /// No description provided for @subscriptionUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade now'**
  String get subscriptionUpgrade;

  /// No description provided for @subscriptionRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get subscriptionRestore;

  /// No description provided for @subscriptionRedeem.
  ///
  /// In en, this message translates to:
  /// **'Redeem code'**
  String get subscriptionRedeem;

  /// No description provided for @subscriptionTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get subscriptionTerms;

  /// No description provided for @subscriptionPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get subscriptionPrivacy;

  /// No description provided for @subscriptionPaymentAndroid.
  ///
  /// In en, this message translates to:
  /// **'Payment is charged to your Google Play account. The subscription renews automatically until you cancel it in Google Play.'**
  String get subscriptionPaymentAndroid;

  /// No description provided for @subscriptionPaymentIos.
  ///
  /// In en, this message translates to:
  /// **'Payment is charged to your Apple ID account. The subscription renews automatically until you cancel it in your account settings.'**
  String get subscriptionPaymentIos;

  /// No description provided for @subscriptionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions are not available on this device or build.'**
  String get subscriptionUnavailable;

  /// No description provided for @subscriptionPending.
  ///
  /// In en, this message translates to:
  /// **'Your purchase is waiting for approval. Access starts once it is approved.'**
  String get subscriptionPending;

  /// No description provided for @subscriptionFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase did not complete. Please try again.'**
  String get subscriptionFailed;

  /// No description provided for @subscriptionLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Your purchase went through but could not be activated yet. We will try again; if access does not appear, restore your purchases or contact support.'**
  String get subscriptionLinkFailed;

  /// No description provided for @subscriptionCancelled.
  ///
  /// In en, this message translates to:
  /// **'The purchase was cancelled.'**
  String get subscriptionCancelled;

  /// No description provided for @subscriptionRestored.
  ///
  /// In en, this message translates to:
  /// **'Subscription restored.'**
  String get subscriptionRestored;

  /// No description provided for @subscriptionNothingToRestore.
  ///
  /// In en, this message translates to:
  /// **'No active subscription was found for this store account.'**
  String get subscriptionNothingToRestore;

  /// No description provided for @subscriptionRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restoring failed. Please try again.'**
  String get subscriptionRestoreFailed;

  /// No description provided for @subscriptionSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'You are all set'**
  String get subscriptionSuccessTitle;

  /// No description provided for @subscriptionSuccessText.
  ///
  /// In en, this message translates to:
  /// **'Thank you for subscribing. All features are unlocked.'**
  String get subscriptionSuccessText;

  /// No description provided for @subscriptionSuccessContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get subscriptionSuccessContinue;

  /// No description provided for @subscriptionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get subscriptionClose;

  /// No description provided for @settingsSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settingsSubscription;

  /// No description provided for @settingsSubscriptionManage.
  ///
  /// In en, this message translates to:
  /// **'Manage in the store'**
  String get settingsSubscriptionManage;

  /// No description provided for @settingsSubscriptionPlans.
  ///
  /// In en, this message translates to:
  /// **'See plans and upgrade'**
  String get settingsSubscriptionPlans;

  /// No description provided for @accessUpgradeAction.
  ///
  /// In en, this message translates to:
  /// **'See plans'**
  String get accessUpgradeAction;

  /// No description provided for @settingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Chat with support'**
  String get settingsSupport;

  /// No description provided for @settingsSupportHint.
  ///
  /// In en, this message translates to:
  /// **'Ask the Racketmates team for help'**
  String get settingsSupportHint;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get settingsLogoutTitle;

  /// No description provided for @settingsLogoutMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to use the app.'**
  String get settingsLogoutMessage;

  /// No description provided for @settingsLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogoutConfirm;

  /// No description provided for @settingsLoggingOut.
  ///
  /// In en, this message translates to:
  /// **'Logging out…'**
  String get settingsLoggingOut;

  /// No description provided for @settingsSubscriptionPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get settingsSubscriptionPremium;

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Free trial: 1 day left} other{Free trial: {count} days left}}'**
  String settingsSubscriptionTrial(int count);

  /// No description provided for @settingsSubscriptionFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get settingsSubscriptionFree;

  /// No description provided for @homeSettingsAction.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettingsAction;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsPush.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get notificationsPush;

  /// No description provided for @notificationsPushOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get notificationsPushOn;

  /// No description provided for @notificationsPushOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notificationsPushOff;

  /// No description provided for @notificationsPushOffHint.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications for this app in your device settings to hear about invitations and changes to your events.'**
  String get notificationsPushOffHint;

  /// No description provided for @notificationsPushNotAsked.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications to hear about invitations and changes to your events.'**
  String get notificationsPushNotAsked;

  /// No description provided for @notificationsAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get notificationsAllow;

  /// No description provided for @notificationsOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get notificationsOpenSettings;

  /// No description provided for @notificationsPushUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Push notifications are not available on this build.'**
  String get notificationsPushUnavailable;

  /// No description provided for @notificationsText.
  ///
  /// In en, this message translates to:
  /// **'Text messages'**
  String get notificationsText;

  /// No description provided for @notificationsTextHint.
  ///
  /// In en, this message translates to:
  /// **'Receive event updates by text message.'**
  String get notificationsTextHint;

  /// No description provided for @notificationsSaved.
  ///
  /// In en, this message translates to:
  /// **'Notification settings updated.'**
  String get notificationsSaved;

  /// No description provided for @notificationsFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t update your notification settings.'**
  String get notificationsFailed;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Event reminders'**
  String get remindersTitle;

  /// No description provided for @remindersHint.
  ///
  /// In en, this message translates to:
  /// **'You are reminded this long before each event you take part in.'**
  String get remindersHint;

  /// No description provided for @remindersEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have no reminders yet.'**
  String get remindersEmpty;

  /// No description provided for @remindersAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a reminder'**
  String get remindersAdd;

  /// No description provided for @remindersLoadError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your reminders.'**
  String get remindersLoadError;

  /// No description provided for @remindersFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t update your reminders.'**
  String get remindersFailed;

  /// No description provided for @reminderRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove reminder'**
  String get reminderRemove;

  /// No description provided for @reminderUnitMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get reminderUnitMinutes;

  /// No description provided for @reminderUnitHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get reminderUnitHours;

  /// No description provided for @reminderUnitDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get reminderUnitDays;

  /// No description provided for @reminderValueLabel.
  ///
  /// In en, this message translates to:
  /// **'How long before'**
  String get reminderValueLabel;

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute before} other{{count} minutes before}}'**
  String reminderMinutesBefore(int count);

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour before} other{{count} hours before}}'**
  String reminderHoursBefore(int count);

  /// Offline fallback.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day before} other{{count} days before}}'**
  String reminderDaysBefore(int count);
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
