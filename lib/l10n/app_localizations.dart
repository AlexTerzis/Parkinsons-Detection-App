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

  /// No description provided for @testStopped.
  ///
  /// In en, this message translates to:
  /// **'Test stopped'**
  String get testStopped;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @tabTests.
  ///
  /// In en, this message translates to:
  /// **'Tests'**
  String get tabTests;

  /// No description provided for @tabResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get tabResults;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @finishAction.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishAction;

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

  /// No description provided for @tabMyPatients.
  ///
  /// In en, this message translates to:
  /// **'MyPatients'**
  String get tabMyPatients;

  /// No description provided for @tabCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get tabCommunity;

  /// No description provided for @specialtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Specialty'**
  String get specialtyLabel;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @noPatientReportsYet.
  ///
  /// In en, this message translates to:
  /// **'No patient reports yet.'**
  String get noPatientReportsYet;

  /// No description provided for @reportsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Reports: {count}'**
  String reportsCountLabel(Object count);

  /// No description provided for @sentAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Sent: {date}'**
  String sentAtLabel(Object date);

  /// No description provided for @testsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Tests: {count}'**
  String testsCountLabel(Object count);

  /// No description provided for @writeNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Write notes for patient...'**
  String get writeNotesHint;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNote;

  /// No description provided for @noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No posts yet.'**
  String get noPostsYet;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report {date}'**
  String reportTitle(Object date);

  /// No description provided for @scorePercent.
  ///
  /// In en, this message translates to:
  /// **'Score: {percent}%'**
  String scorePercent(Object percent);

  /// No description provided for @noAdditionalData.
  ///
  /// In en, this message translates to:
  /// **'No additional data'**
  String get noAdditionalData;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @authenticationError.
  ///
  /// In en, this message translates to:
  /// **'Authentication error'**
  String get authenticationError;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get unexpectedError;

  /// No description provided for @enterEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email first.'**
  String get enterEmailFirst;

  /// No description provided for @failedToSendResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email.'**
  String get failedToSendResetEmail;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @invalidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmailAddress;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequired;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @testingHand1.
  ///
  /// In en, this message translates to:
  /// **'Testing Hand 1...'**
  String get testingHand1;

  /// No description provided for @testingHand2.
  ///
  /// In en, this message translates to:
  /// **'Testing Hand 2...'**
  String get testingHand2;

  /// No description provided for @handOneLabel.
  ///
  /// In en, this message translates to:
  /// **'Hand 1'**
  String get handOneLabel;

  /// No description provided for @handTwoLabel.
  ///
  /// In en, this message translates to:
  /// **'Hand 2'**
  String get handTwoLabel;

  /// No description provided for @fftResultsTemplate.
  ///
  /// In en, this message translates to:
  /// **'{label} Results (Accelerometer):\nX Peak Frequency: {x} Hz\nY Peak Frequency: {y} Hz\nZ Peak Frequency: {z} Hz'**
  String fftResultsTemplate(Object label, Object x, Object y, Object z);

  /// No description provided for @handOneFftSpectrum.
  ///
  /// In en, this message translates to:
  /// **'Hand 1 FFT Spectrum'**
  String get handOneFftSpectrum;

  /// No description provided for @handTwoFftSpectrum.
  ///
  /// In en, this message translates to:
  /// **'Hand 2 FFT Spectrum'**
  String get handTwoFftSpectrum;

  /// No description provided for @insufficientSensorData.
  ///
  /// In en, this message translates to:
  /// **'Insufficient sensor data to render spectrum.'**
  String get insufficientSensorData;

  /// No description provided for @xAxisLabel.
  ///
  /// In en, this message translates to:
  /// **'X-axis'**
  String get xAxisLabel;

  /// No description provided for @yAxisLabel.
  ///
  /// In en, this message translates to:
  /// **'Y-axis'**
  String get yAxisLabel;

  /// No description provided for @zAxisLabel.
  ///
  /// In en, this message translates to:
  /// **'Z-axis'**
  String get zAxisLabel;

  /// No description provided for @accelerometerReadout.
  ///
  /// In en, this message translates to:
  /// **'Accelerometer: X={x} Y={y} Z={z}'**
  String accelerometerReadout(Object x, Object y, Object z);

  /// No description provided for @gyroscopeReadout.
  ///
  /// In en, this message translates to:
  /// **'Live Gyroscope meter: X={x}  Y={y}  Z={z}'**
  String gyroscopeReadout(Object x, Object y, Object z);

  /// No description provided for @rightHandLabel.
  ///
  /// In en, this message translates to:
  /// **'Right hand'**
  String get rightHandLabel;

  /// No description provided for @leftHandLabel.
  ///
  /// In en, this message translates to:
  /// **'Left hand'**
  String get leftHandLabel;

  /// No description provided for @predictionNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Prediction not available'**
  String get predictionNotAvailable;

  /// No description provided for @predictionFailed.
  ///
  /// In en, this message translates to:
  /// **'Prediction failed'**
  String get predictionFailed;

  /// No description provided for @tapParkinsonPattern.
  ///
  /// In en, this message translates to:
  /// **'{label}: ⚠️ Parkinson-like pattern ({percent}%)'**
  String tapParkinsonPattern(Object label, Object percent);

  /// No description provided for @tapNormalPattern.
  ///
  /// In en, this message translates to:
  /// **'{label}: ✅ Normal tapping ({percent}%)'**
  String tapNormalPattern(Object label, Object percent);

  /// No description provided for @drawTitle.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get drawTitle;

  /// No description provided for @clearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearAction;

  /// No description provided for @aiSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Overall AI Summary'**
  String get aiSummaryTitle;

  /// No description provided for @aiSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Low risk – more advanced analytics will appear here.'**
  String get aiSummarySubtitle;

  /// No description provided for @testBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Test-by-Test Breakdown'**
  String get testBreakdownTitle;

  /// No description provided for @testBreakdownSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Charts of tapping, tremor and other tests will be added.'**
  String get testBreakdownSubtitle;

  /// No description provided for @riskAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Risk Alerts or Anomalies'**
  String get riskAlertsTitle;

  /// No description provided for @noAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No alerts detected recently.'**
  String get noAlertsSubtitle;

  /// No description provided for @argumentation.
  ///
  /// In en, this message translates to:
  /// **'Argumentation'**
  String get argumentation;

  /// No description provided for @loadingReasoning.
  ///
  /// In en, this message translates to:
  /// **'Loading reasoning...'**
  String get loadingReasoning;

  /// No description provided for @takeQuestionnairePrompt.
  ///
  /// In en, this message translates to:
  /// **'Take the questionnaire to see the results'**
  String get takeQuestionnairePrompt;

  /// No description provided for @noArgumentationYet.
  ///
  /// In en, this message translates to:
  /// **'Cannot give clear argumentation yet from the questionnaire results. If you have any questions, please contact your doctor.'**
  String get noArgumentationYet;

  /// No description provided for @aiSuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Test Suggestions'**
  String get aiSuggestionsTitle;

  /// No description provided for @retakeTremorSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Please retake the Tremor Test – last result was inconclusive.'**
  String get retakeTremorSuggestion;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @textSizeSystemNote.
  ///
  /// In en, this message translates to:
  /// **'This replaces your device\'s font size setting inside this app.'**
  String get textSizeSystemNote;

  /// No description provided for @textSizeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get textSizeNormal;

  /// No description provided for @textSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textSizeLarge;

  /// No description provided for @textSizeLarger.
  ///
  /// In en, this message translates to:
  /// **'Larger'**
  String get textSizeLarger;

  /// No description provided for @textSizeLargest.
  ///
  /// In en, this message translates to:
  /// **'Largest'**
  String get textSizeLargest;

  /// No description provided for @textSizePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get textSizePreviewTitle;

  /// No description provided for @textSizePreviewBody.
  ///
  /// In en, this message translates to:
  /// **'Text throughout the app will look like this.'**
  String get textSizePreviewBody;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get resetToDefault;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueAsGuest;

  /// No description provided for @guestAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'You are using a guest account'**
  String get guestAccountTitle;

  /// No description provided for @guestAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your tests and results are saved to this device only. Create an account to keep them and to share results with a doctor.'**
  String get guestAccountBody;

  /// No description provided for @keepMyResults.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get keepMyResults;

  /// No description provided for @guestSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of guest account?'**
  String get guestSignOutTitle;

  /// No description provided for @guestSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'This guest account and every result in it will be permanently lost. Create an account first if you want to keep them.'**
  String get guestSignOutBody;

  /// No description provided for @signOutAnyway.
  ///
  /// In en, this message translates to:
  /// **'Sign out anyway'**
  String get signOutAnyway;

  /// No description provided for @accountCreatedKeptResults.
  ///
  /// In en, this message translates to:
  /// **'Account created. Your results have been kept.'**
  String get accountCreatedKeptResults;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'That email already belongs to another account. Sign in to it instead, though your guest results will not carry over.'**
  String get emailAlreadyInUse;

  /// No description provided for @guestUpgradeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the account. Please try again.'**
  String get guestUpgradeFailed;

  /// No description provided for @cameraTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera hand assessment'**
  String get cameraTestTitle;

  /// No description provided for @cameraSetupBody.
  ///
  /// In en, this message translates to:
  /// **'You will be guided through a short series of hand movements, one hand at a time. Hold your phone steady, or prop it up, so the hand being tested stays in view.'**
  String get cameraSetupBody;

  /// No description provided for @cameraTestLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get cameraTestLength;

  /// No description provided for @cameraModeFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get cameraModeFull;

  /// No description provided for @cameraModeShort.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get cameraModeShort;

  /// No description provided for @cameraModeShortNote.
  ///
  /// In en, this message translates to:
  /// **'Short mode uses about half the time for each movement.'**
  String get cameraModeShortNote;

  /// No description provided for @cameraApproxDuration.
  ///
  /// In en, this message translates to:
  /// **'About {seconds} seconds'**
  String cameraApproxDuration(Object seconds);

  /// No description provided for @cameraStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get cameraStart;

  /// No description provided for @cameraExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get cameraExit;

  /// No description provided for @cameraHandLeft.
  ///
  /// In en, this message translates to:
  /// **'Left hand'**
  String get cameraHandLeft;

  /// No description provided for @cameraHandRight.
  ///
  /// In en, this message translates to:
  /// **'Right hand'**
  String get cameraHandRight;

  /// No description provided for @cameraTaskRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get cameraTaskRest;

  /// No description provided for @cameraTaskOpenClose.
  ///
  /// In en, this message translates to:
  /// **'Open and close'**
  String get cameraTaskOpenClose;

  /// No description provided for @cameraTaskFingerTap.
  ///
  /// In en, this message translates to:
  /// **'Finger tapping'**
  String get cameraTaskFingerTap;

  /// No description provided for @cameraTaskPronation.
  ///
  /// In en, this message translates to:
  /// **'Palm up and down'**
  String get cameraTaskPronation;

  /// No description provided for @cameraInstructionRest.
  ///
  /// In en, this message translates to:
  /// **'Rest your hand still and relaxed, in view of the camera.'**
  String get cameraInstructionRest;

  /// No description provided for @cameraInstructionOpenClose.
  ///
  /// In en, this message translates to:
  /// **'Open your hand wide, then close it into a fist. Repeat as fully and as quickly as you can.'**
  String get cameraInstructionOpenClose;

  /// No description provided for @cameraInstructionFingerTap.
  ///
  /// In en, this message translates to:
  /// **'Tap your thumb against your index finger. Make each tap as big and as fast as you can.'**
  String get cameraInstructionFingerTap;

  /// No description provided for @cameraInstructionPronation.
  ///
  /// In en, this message translates to:
  /// **'Turn your palm up, then down, over and over. Make each turn as big and as fast as you can.'**
  String get cameraInstructionPronation;

  /// No description provided for @cameraStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String cameraStepOf(Object current, Object total);

  /// No description provided for @cameraMdsItem.
  ///
  /// In en, this message translates to:
  /// **'MDS-UPDRS item {item}'**
  String cameraMdsItem(Object item);

  /// No description provided for @cameraHandNotVisible.
  ///
  /// In en, this message translates to:
  /// **'Move your {hand} into view'**
  String cameraHandNotVisible(Object hand);

  /// No description provided for @cameraPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get cameraPause;

  /// No description provided for @cameraPausePending.
  ///
  /// In en, this message translates to:
  /// **'Pausing after this movement'**
  String get cameraPausePending;

  /// No description provided for @cameraCancelPause.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get cameraCancelPause;

  /// No description provided for @cameraPausedTitle.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get cameraPausedTitle;

  /// No description provided for @cameraPausedBody.
  ///
  /// In en, this message translates to:
  /// **'Take as long as you need. The test continues from the next movement.'**
  String get cameraPausedBody;

  /// No description provided for @cameraNextUp.
  ///
  /// In en, this message translates to:
  /// **'Next: {task}'**
  String cameraNextUp(Object task);

  /// No description provided for @cameraResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get cameraResume;

  /// No description provided for @cameraFinishing.
  ///
  /// In en, this message translates to:
  /// **'Saving your results'**
  String get cameraFinishing;
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
