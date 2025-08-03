import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_el.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('el'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Parkinson AI Detector'**
  String get appTitle;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get editName;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @dobHint.
  ///
  /// In en, this message translates to:
  /// **'yyyy-mm-dd'**
  String get dobHint;

  /// No description provided for @addMedication.
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get addMedication;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'LOG OUT'**
  String get logOut;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @greek.
  ///
  /// In en, this message translates to:
  /// **'Greek'**
  String get greek;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @iAmA.
  ///
  /// In en, this message translates to:
  /// **'I am a'**
  String get iAmA;

  /// No description provided for @patient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patient;

  /// No description provided for @doctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctor;

  /// No description provided for @keepMeLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Keep me logged in'**
  String get keepMeLoggedIn;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @passwordRecovery.
  ///
  /// In en, this message translates to:
  /// **'Password Recovery'**
  String get passwordRecovery;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @emailSent.
  ///
  /// In en, this message translates to:
  /// **'If the email exists, a reset link has been sent.'**
  String get emailSent;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @savedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get savedSuccessfully;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @noRecommendations.
  ///
  /// In en, this message translates to:
  /// **'No recommendations returned'**
  String get noRecommendations;

  /// No description provided for @questionnaire.
  ///
  /// In en, this message translates to:
  /// **'Questionnaire'**
  String get questionnaire;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @tapTest.
  ///
  /// In en, this message translates to:
  /// **'Tap Test'**
  String get tapTest;

  /// No description provided for @timeLeft.
  ///
  /// In en, this message translates to:
  /// **'Time left: {seconds}s'**
  String timeLeft(Object seconds);

  /// No description provided for @tap.
  ///
  /// In en, this message translates to:
  /// **'TAP'**
  String get tap;

  /// No description provided for @startTest.
  ///
  /// In en, this message translates to:
  /// **'Start Test'**
  String get startTest;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @pressStart.
  ///
  /// In en, this message translates to:
  /// **'Press start to begin'**
  String get pressStart;

  /// No description provided for @startingTest.
  ///
  /// In en, this message translates to:
  /// **'Starting test...'**
  String get startingTest;

  /// No description provided for @tapRightHand.
  ///
  /// In en, this message translates to:
  /// **'Tap with right hand'**
  String get tapRightHand;

  /// No description provided for @switchHands.
  ///
  /// In en, this message translates to:
  /// **'Switch hands'**
  String get switchHands;

  /// No description provided for @tapLeftHand.
  ///
  /// In en, this message translates to:
  /// **'Tap with left hand'**
  String get tapLeftHand;

  /// No description provided for @testCompleted.
  ///
  /// In en, this message translates to:
  /// **'Test completed'**
  String get testCompleted;

  /// No description provided for @voiceTest.
  ///
  /// In en, this message translates to:
  /// **'Voice Test'**
  String get voiceTest;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get recording;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @microphonePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied'**
  String get microphonePermissionDenied;

  /// No description provided for @possibleParkinson.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Possible Parkinson pattern ({percent}%)'**
  String possibleParkinson(Object percent);

  /// No description provided for @normalVoice.
  ///
  /// In en, this message translates to:
  /// **'✅ Normal voice ({percent}%)'**
  String normalVoice(Object percent);

  /// No description provided for @recordingFailed.
  ///
  /// In en, this message translates to:
  /// **'Recording failed'**
  String get recordingFailed;

  /// No description provided for @noDoctorSelected.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t selected a doctor yet.\nClick to select'**
  String get noDoctorSelected;

  /// No description provided for @myDoctor.
  ///
  /// In en, this message translates to:
  /// **'My Doctor'**
  String get myDoctor;

  /// No description provided for @sendResults.
  ///
  /// In en, this message translates to:
  /// **'Send Results'**
  String get sendResults;

  /// No description provided for @diagnoses.
  ///
  /// In en, this message translates to:
  /// **'Diagnoses'**
  String get diagnoses;

  /// No description provided for @bookAppointment.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointment;

  /// No description provided for @getSecondOpinion.
  ///
  /// In en, this message translates to:
  /// **'Get Second Opinion'**
  String get getSecondOpinion;

  /// No description provided for @secondOpinions.
  ///
  /// In en, this message translates to:
  /// **'Second Opinions'**
  String get secondOpinions;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @noDoctorFeedback.
  ///
  /// In en, this message translates to:
  /// **'No doctor feedback yet.'**
  String get noDoctorFeedback;

  /// No description provided for @noNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get noNotesYet;

  /// No description provided for @completeOneTest.
  ///
  /// In en, this message translates to:
  /// **'Please complete at least one test first.'**
  String get completeOneTest;

  /// No description provided for @selectDoctor.
  ///
  /// In en, this message translates to:
  /// **'Select Doctor'**
  String get selectDoctor;

  /// No description provided for @searchDoctor.
  ///
  /// In en, this message translates to:
  /// **'Search doctor...'**
  String get searchDoctor;

  /// No description provided for @noDoctorsFound.
  ///
  /// In en, this message translates to:
  /// **'No doctors found'**
  String get noDoctorsFound;

  /// No description provided for @resultsSentTo.
  ///
  /// In en, this message translates to:
  /// **'Results sent to {name}'**
  String resultsSentTo(Object name);

  /// No description provided for @testResults.
  ///
  /// In en, this message translates to:
  /// **'Test Results'**
  String get testResults;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @needThreeTests.
  ///
  /// In en, this message translates to:
  /// **'Complete at least 3 different tests to view the summary chart.'**
  String get needThreeTests;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String days(Object count);

  /// No description provided for @exportResults.
  ///
  /// In en, this message translates to:
  /// **'Export Results'**
  String get exportResults;

  /// No description provided for @cameraDetectionTest.
  ///
  /// In en, this message translates to:
  /// **'Camera Detection Test'**
  String get cameraDetectionTest;

  /// No description provided for @tremorTest.
  ///
  /// In en, this message translates to:
  /// **'Tremor Test'**
  String get tremorTest;

  /// No description provided for @drawingTest.
  ///
  /// In en, this message translates to:
  /// **'Drawing Test'**
  String get drawingTest;

  /// No description provided for @neuropsychologicalTest.
  ///
  /// In en, this message translates to:
  /// **'Neuropsychological Test'**
  String get neuropsychologicalTest;

  /// No description provided for @fabTest.
  ///
  /// In en, this message translates to:
  /// **'Frontal Assessment Battery Test'**
  String get fabTest;

  /// No description provided for @sendResultsToDoctor.
  ///
  /// In en, this message translates to:
  /// **'Send Results to Doctor'**
  String get sendResultsToDoctor;

  /// No description provided for @noHandsDetected.
  ///
  /// In en, this message translates to:
  /// **'No hands detected. Try again.'**
  String get noHandsDetected;

  /// No description provided for @testCompletedMsg.
  ///
  /// In en, this message translates to:
  /// **'{test} completed'**
  String testCompletedMsg(Object test);

  /// No description provided for @drawOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Draw on phone'**
  String get drawOnPhone;

  /// No description provided for @takePicture.
  ///
  /// In en, this message translates to:
  /// **'Take picture'**
  String get takePicture;

  /// No description provided for @uploadPicture.
  ///
  /// In en, this message translates to:
  /// **'Upload picture'**
  String get uploadPicture;
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
      <String>['el', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
